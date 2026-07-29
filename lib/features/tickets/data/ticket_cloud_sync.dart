import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_payload.dart';

/// Firestore metadata + Firebase Storage image sync for saved tickets.
class TicketCloudSync {
  TicketCloudSync({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _authOverride = auth,
       _firestoreOverride = firestore,
       _storageOverride = storage;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseStorage? _storageOverride;

  // Lazy so constructing TicketsCubit in tests does not require Firebase init.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  String? get _uid {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      // Firebase not initialized (unit tests / early boot).
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

  /// Code-indexed admission doc for host door verification across devices.
  DocumentReference<Map<String, dynamic>>? _indexDoc(String code) {
    final uid = _uid;
    final normalized = code.trim();
    if (uid == null || normalized.isEmpty) return null;
    return _firestore.collection('ticketIndex').doc(normalized);
  }

  /// Writes ticket metadata immediately (does not wait on image upload).
  Future<void> upsertTicketDocument(Ticket ticket) async {
    final doc = _ticketDoc(ticket.id);
    if (doc == null) return;
    final payload = {
      ...ticket.toJson(),
      'imagePath': ticket.imagePath,
      'imageUrl': ticket.imagePath,
      'photoUrl': ticket.imagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload, SetOptions(merge: true));
    await _upsertIndex(ticket);
  }

  Future<void> _upsertIndex(Ticket ticket) async {
    final uid = _uid;
    final index = _indexDoc(ticket.code);
    if (uid == null || index == null) return;
    try {
      await index.set({
        'hostUid': uid,
        'ticketId': ticket.id,
        'code': ticket.code,
        'title': ticket.title,
        'subtitle': ticket.subtitle,
        'venue': ticket.venue,
        'qrData': ticket.qrData.isNotEmpty
            ? ticket.qrData
            : TicketPayload.verificationUrl(ticket.code),
        'checkedIn': ticket.isCheckedIn,
        'status': ticket.isCheckedIn ? 'checked_in' : 'valid',
        if (ticket.checkedInAt != null)
          'checkedInAt': ticket.checkedInAt!.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Ticket index upsert failed: $e\n$st');
    }
  }

  /// Marks a ticket checked in on the owner doc + code index.
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
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e, st) {
        debugPrint('Ticket check-in cloud write failed: $e\n$st');
      }
    }
    await _upsertIndex(
      ticket.copyWith(checkedInAt: checkedInAt),
    );
  }

  /// Looks up a ticket by guest [code] for the signed-in host (cross-device).
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

  /// Uploads a JPEG ticket/event image and patches the Firestore doc with URL.
  Future<String?> uploadTicketImageJpeg({
    required String ticketId,
    required Uint8List jpegBytes,
  }) async {
    final uid = _uid;
    final doc = _ticketDoc(ticketId);
    if (uid == null || doc == null || jpegBytes.isEmpty) return null;

    final ref = _storage.ref('users/$uid/tickets/$ticketId.jpg');
    await ref.putData(
      jpegBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await doc.set({
      'imagePath': url,
      'imageUrl': url,
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('Ticket image uploaded: $ticketId');
    return url;
  }
}
