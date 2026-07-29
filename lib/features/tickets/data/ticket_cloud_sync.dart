import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_image_codec.dart';
import 'ticket_payload.dart';

/// Firestore-only ticket sync (no Firebase Storage — Spark / no bucket).
///
/// Event flyers are stored as local files / `web-bytes:` / `data:` URLs.
/// When a flyer fits under the Firestore size budget, the owner ticket doc
/// embeds a Base64 `data:image/jpeg;base64,...` string.
class TicketCloudSync {
  TicketCloudSync({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _authOverride = auth,
       _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  /// Soft cap so owner ticket docs stay under Firestore's 1 MiB limit.
  static const int maxEmbeddedPhotoDataUrlChars = 700000;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  String? get _uid {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? _ticketDoc(String ticketId) {
    final uid = _uid;
    if (uid == null || ticketId.isEmpty) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tickets')
        .doc(ticketId);
  }

  DocumentReference<Map<String, dynamic>>? _publicTicketDoc(String code) {
    final uid = _uid;
    final normalized = code.trim();
    if (uid == null || normalized.isEmpty) return null;
    return _firestore.collection('tickets').doc(normalized);
  }

  DocumentReference<Map<String, dynamic>>? _indexDoc(String code) {
    final uid = _uid;
    final normalized = code.trim();
    if (uid == null || normalized.isEmpty) return null;
    return _firestore.collection('ticketIndex').doc(normalized);
  }

  /// True when [url] points at Firebase Storage (disabled on Spark).
  static bool isFirebaseStorageUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.contains('firebasestorage.googleapis.com') ||
        u.contains('firebasestorage.app') ||
        u.startsWith('gs://');
  }

  /// Builds a `data:image/jpeg;base64,...` URL if it fits the Firestore budget.
  static String? jpegBytesToDataUrl(Uint8List jpegBytes) {
    if (jpegBytes.isEmpty) return null;
    final encoded = base64Encode(jpegBytes);
    final dataUrl = 'data:image/jpeg;base64,$encoded';
    if (dataUrl.length > maxEmbeddedPhotoDataUrlChars) return null;
    return dataUrl;
  }

  /// Compresses flyer bytes for Firestore embedding (smaller than local cache).
  static Future<Uint8List> compressForFirestore(Uint8List bytes) {
    return compressImageToJpeg(bytes, quality: 55, maxWidth: 720);
  }

  /// Writes ticket metadata (+ optional embedded flyer) to Firestore.
  ///
  /// [photoBytes] are compressed and stored as a Base64 data URL when small
  /// enough. Never calls Firebase Storage.
  Future<void> upsertTicketDocument(
    Ticket ticket, {
    Uint8List? photoBytes,
  }) async {
    final doc = _ticketDoc(ticket.id);
    if (doc == null) return;

    var photoField = ticket.imagePath.trim();
    if (isFirebaseStorageUrl(photoField)) {
      photoField = '';
    }

    if (photoBytes != null && photoBytes.isNotEmpty) {
      try {
        final jpeg = await compressForFirestore(photoBytes);
        final dataUrl = jpegBytesToDataUrl(jpeg);
        if (dataUrl != null) {
          photoField = dataUrl;
        }
      } catch (e, st) {
        debugPrint('Firestore photo embed compress failed: $e\n$st');
      }
    } else if (photoField.startsWith('data:image/')) {
      // Already embedded.
    } else if (photoField.startsWith('http://') ||
        photoField.startsWith('https://')) {
      // Allow non-Storage http(s) flyer URLs only.
      if (isFirebaseStorageUrl(photoField)) photoField = '';
    } else {
      // Local / web-bytes paths are device-only — don't push them to Firestore.
      photoField = '';
    }

    final forCloud = ticket.copyWith(imagePath: photoField);
    final payload = {
      ...forCloud.toJson(),
      'imagePath': photoField,
      'imageUrl': photoField,
      'photoUrl': photoField,
      'storageProvider': 'firestore_base64',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload, SetOptions(merge: true));
    await _upsertIndex(forCloud);
  }

  Future<void> _upsertIndex(Ticket ticket) async {
    final uid = _uid;
    final publicDoc = _publicTicketDoc(ticket.code);
    final index = _indexDoc(ticket.code);
    if (uid == null || publicDoc == null) return;

    // Public verify docs stay lean — no flyer Base64 (check-in only).
    final payload = <String, dynamic>{
      'hostUid': uid,
      'ticketId': ticket.id,
      'code': ticket.code,
      'title': ticket.title,
      'eventName': ticket.title,
      'subtitle': ticket.subtitle,
      'venue': ticket.venue,
      'dateLabel': ticket.dateLabel,
      'timeLabel': ticket.timeLabel,
      'eventAt': ticket.eventAt.toIso8601String(),
      'headerLabel': ticket.headerLabel,
      'qrData': ticket.qrData.isNotEmpty
          ? ticket.qrData
          : TicketPayload.verificationUrl(ticket.code),
      'checkedIn': ticket.isCheckedIn,
      'status': ticket.isCheckedIn ? 'checked_in' : 'valid',
      if (ticket.checkedInAt != null)
        'checkedInAt': ticket.checkedInAt!.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await publicDoc.set(payload, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Public tickets upsert failed: $e\n$st');
    }

    if (index == null) return;
    try {
      await index.set(payload, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Ticket index upsert failed: $e\n$st');
    }
  }

  Future<void> markCheckedIn({
    required Ticket ticket,
    required DateTime checkedInAt,
  }) async {
    final doc = _ticketDoc(ticket.id);
    final iso = checkedInAt.toIso8601String();
    if (doc != null) {
      try {
        await doc.set({
          'checkedIn': true,
          'checkedInAt': iso,
          'status': 'checked_in',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e, st) {
        debugPrint('Ticket check-in cloud write failed: $e\n$st');
      }
    }
    await _upsertIndex(ticket.copyWith(checkedInAt: checkedInAt));
  }

  Future<Ticket?> findTicketByCode(String code) async {
    final uid = _uid;
    final normalized = code.trim();
    if (uid == null || normalized.isEmpty) return null;

    try {
      final indexRef = _indexDoc(normalized);
      if (indexRef == null) return null;
      final indexSnap = await indexRef.get();
      if (!indexSnap.exists) return null;
      final data = indexSnap.data();
      if (data == null) return null;
      if (data['hostUid'] != uid) return null;

      final ticketId = data['ticketId'] as String?;
      if (ticketId == null || ticketId.isEmpty) return null;
      final ticketRef = _ticketDoc(ticketId);
      if (ticketRef != null) {
        final ticketSnap = await ticketRef.get();
        if (ticketSnap.exists) {
          final json = ticketSnap.data();
          if (json != null) {
            return Ticket.fromJson(Map<String, dynamic>.from(json));
          }
        }
      }

      DateTime? checkedInAt;
      final raw = data['checkedInAt'];
      if (raw is String) checkedInAt = DateTime.tryParse(raw);
      return Ticket(
        id: ticketId,
        headerLabel: 'GUEST PASS',
        title: data['title'] as String? ?? 'Ticket',
        subtitle: data['subtitle'] as String? ?? '',
        venue: data['venue'] as String? ?? '',
        dateLabel: '',
        timeLabel: '',
        eventAt: DateTime.now(),
        code: normalized,
        qrData: data['qrData'] as String? ??
            TicketPayload.verificationUrl(normalized),
        imagePath: '',
        eyeColor: const Color(0xFFFF5963),
        dataModuleColor: const Color(0xFFFFFFFF),
        isSquare: false,
        topGradientStart: const Color(0xFF4B39EF),
        topGradientEnd: const Color(0xFF4B39EF),
        bottomGradientStart: const Color(0xFF4B39EF),
        bottomGradientEnd: const Color(0xFF4B39EF),
        checkedInAt: checkedInAt,
      );
    } catch (e, st) {
      debugPrint('findTicketByCode failed: $e\n$st');
      return null;
    }
  }

  /// Storage uploads are disabled (Spark / no bucket). Always returns null.
  @Deprecated('Firebase Storage disabled — use Firestore Base64 embedding.')
  Future<String?> uploadTicketImageJpeg({
    required String ticketId,
    required Uint8List jpegBytes,
  }) async {
    debugPrint(
      'uploadTicketImageJpeg skipped (Storage disabled) for $ticketId',
    );
    return null;
  }
}
