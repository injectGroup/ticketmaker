import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_image_codec.dart';
import 'ticket_payload.dart';

/// Firestore ticket sync (no Firebase Storage — Spark / no bucket).
///
/// Public door-verify docs live at `tickets/{guestCode}` and are written on
/// every save (signed-in or guest) so `/verify/:id` works for phone camera scans.
class TicketCloudSync {
  TicketCloudSync({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _authOverride = auth,
       _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

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

  DocumentReference<Map<String, dynamic>>? _ownerTicketDoc(String ticketId) {
    final uid = _uid;
    if (uid == null || ticketId.isEmpty) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tickets')
        .doc(ticketId);
  }

  /// Public verify doc — always addressable (no auth required to obtain ref).
  DocumentReference<Map<String, dynamic>> _publicTicketDoc(String code) {
    return _firestore.collection('tickets').doc(code.trim());
  }

  static bool isFirebaseStorageUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.contains('firebasestorage.googleapis.com') ||
        u.contains('firebasestorage.app') ||
        u.startsWith('gs://');
  }

  static String? jpegBytesToDataUrl(Uint8List jpegBytes) {
    if (jpegBytes.isEmpty) return null;
    final encoded = base64Encode(jpegBytes);
    final dataUrl = 'data:image/jpeg;base64,$encoded';
    if (dataUrl.length > maxEmbeddedPhotoDataUrlChars) return null;
    return dataUrl;
  }

  static Future<Uint8List> compressForFirestore(Uint8List bytes) {
    return compressImageToJpeg(bytes, quality: 55, maxWidth: 720);
  }

  /// Payload for top-level `tickets/{guestCode}` used by `/verify/:id`.
  Map<String, dynamic> publicVerifyPayload(Ticket ticket) {
    final code = ticket.code.trim();
    final uid = _uid;
    return {
      'ticketId': code,
      'internalTicketId': ticket.id,
      'code': code,
      'eventName': ticket.title,
      'eventDate': ticket.dateLabel.trim().isNotEmpty
          ? ticket.dateLabel
          : ticket.eventAt.toIso8601String(),
      'eventAt': ticket.eventAt.toIso8601String(),
      'venue': ticket.venue,
      'guestName': ticket.subtitle.trim().isNotEmpty
          ? ticket.subtitle
          : ticket.headerLabel,
      'title': ticket.title,
      'subtitle': ticket.subtitle,
      'dateLabel': ticket.dateLabel,
      'timeLabel': ticket.timeLabel,
      'headerLabel': ticket.headerLabel,
      'qrData': ticket.qrData.isNotEmpty
          ? ticket.qrData
          : TicketPayload.verificationUrl(code),
      'status': ticket.isCheckedIn ? 'checked_in' : 'valid',
      'checkedIn': ticket.isCheckedIn,
      if (ticket.checkedInAt != null)
        'checkedInAt': ticket.checkedInAt!.toIso8601String(),
      if (uid != null) 'hostUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Creates/updates the public verify document. Must succeed for QR scans.
  ///
  /// Returns `false` when Firebase is not initialized (unit tests) or the write
  /// fails; returns `true` on success.
  Future<bool> publishPublicTicket(Ticket ticket) async {
    try {
      if (Firebase.apps.isEmpty) return false;
    } catch (_) {
      return false;
    }

    final code = ticket.code.trim();
    if (!TicketPayload.codePattern.hasMatch(code)) {
      debugPrint('Invalid ticket code for public publish: $code');
      return false;
    }

    try {
      final ref = _publicTicketDoc(code);
      final payload = publicVerifyPayload(ticket);
      final existing = await ref.get();
      if (existing.exists) {
        payload.remove('createdAt');
      }
      await ref.set(payload, SetOptions(merge: true));
      debugPrint('Published public ticket tickets/$code');
      return true;
    } catch (e, st) {
      debugPrint('Public tickets/$code publish failed: $e\n$st');
      return false;
    }
  }

  /// Owner private doc (when signed in) + public verify doc (always).
  Future<void> upsertTicketDocument(
    Ticket ticket, {
    Uint8List? photoBytes,
  }) async {
    // Public verify doc first — gatekeepers depend on this.
    final published = await publishPublicTicket(ticket);
    if (!published) {
      debugPrint('Public tickets/${ticket.code} publish skipped or failed');
    }

    final doc = _ownerTicketDoc(ticket.id);
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
      // keep
    } else if (photoField.startsWith('http://') ||
        photoField.startsWith('https://')) {
      if (isFirebaseStorageUrl(photoField)) photoField = '';
    } else {
      photoField = '';
    }

    final forCloud = ticket.copyWith(imagePath: photoField);
    final payload = {
      ...forCloud.toJson(),
      'imagePath': photoField,
      'imageUrl': photoField,
      'photoUrl': photoField,
      'storageProvider': 'firestore_base64',
      'status': ticket.isCheckedIn ? 'checked_in' : 'valid',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload, SetOptions(merge: true));
  }

  Future<void> markCheckedIn({
    required Ticket ticket,
    required DateTime checkedInAt,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }

    final iso = checkedInAt.toIso8601String();
    final patch = <String, dynamic>{
      'checkedIn': true,
      'checkedInAt': iso,
      'status': 'checked_in',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _publicTicketDoc(ticket.code).set(patch, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Public check-in write failed: $e\n$st');
    }

    final doc = _ownerTicketDoc(ticket.id);
    if (doc != null) {
      try {
        await doc.set(patch, SetOptions(merge: true));
      } catch (e, st) {
        debugPrint('Owner check-in cloud write failed: $e\n$st');
      }
    }
  }

  Future<Ticket?> findTicketByCode(String code) async {
    try {
      if (Firebase.apps.isEmpty) return null;
    } catch (_) {
      return null;
    }

    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    try {
      final snap = await _publicTicketDoc(normalized).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return _ticketFromPublicData(code: normalized, data: data);
    } catch (e, st) {
      debugPrint('findTicketByCode failed: $e\n$st');
      return null;
    }
  }

  Ticket _ticketFromPublicData({
    required String code,
    required Map<String, dynamic> data,
  }) {
    DateTime? checkedInAt;
    final raw = data['checkedInAt'];
    if (raw is String) checkedInAt = DateTime.tryParse(raw);
    if ((data['status'] == 'checked_in' || data['checkedIn'] == true) &&
        checkedInAt == null) {
      checkedInAt = DateTime.now();
    }

    DateTime eventAt = DateTime.now();
    final rawEvent = data['eventAt'];
    if (rawEvent is String) {
      eventAt = DateTime.tryParse(rawEvent) ?? eventAt;
    }

    return Ticket(
      id: data['internalTicketId'] as String? ??
          data['ticketId'] as String? ??
          code,
      headerLabel: data['headerLabel'] as String? ?? 'GUEST PASS',
      title: data['eventName'] as String? ??
          data['title'] as String? ??
          'Ticket',
      subtitle: data['guestName'] as String? ??
          data['subtitle'] as String? ??
          '',
      venue: data['venue'] as String? ?? '',
      dateLabel: data['eventDate'] as String? ??
          data['dateLabel'] as String? ??
          '',
      timeLabel: data['timeLabel'] as String? ?? '',
      eventAt: eventAt,
      code: code,
      qrData: data['qrData'] as String? ??
          TicketPayload.verificationUrl(code),
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
  }

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
