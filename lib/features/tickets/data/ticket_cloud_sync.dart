import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../generate/domain/entities/ticket.dart';

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

  /// Writes ticket metadata immediately (does not wait on image upload).
  Future<void> upsertTicketDocument(Ticket ticket) async {
    final doc = _ticketDoc(ticket.id);
    if (doc == null) return;
    await doc.set({
      ...ticket.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('Ticket image uploaded: $ticketId');
    return url;
  }
}
