import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_payload.dart';

/// Public (no-auth) door verification against the top-level `tickets` collection.
///
/// Document id is the guest code (`####-####-###`) encoded in the QR URL.
class TicketPublicVerify {
  TicketPublicVerify({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ticketsDoc(String id) =>
      _firestore.collection('tickets').doc(id);

  DocumentReference<Map<String, dynamic>> _indexDoc(String id) =>
      _firestore.collection('ticketIndex').doc(id);

  /// Looks up [rawOrCode], admits once, and returns a UI-ready result.
  Future<TicketVerifyResult> verifyAndCheckIn(String rawOrCode) async {
    final code = TicketPayload.parseCode(rawOrCode);
    if (code == null) {
      return const TicketVerifyResult(
        status: TicketVerifyStatus.invalidPayload,
      );
    }

    try {
      return await _firestore.runTransaction((tx) async {
        final primary = _ticketsDoc(code);
        var snap = await tx.get(primary);
        var usingIndex = false;

        if (!snap.exists) {
          // Legacy docs written only to ticketIndex.
          final legacy = await tx.get(_indexDoc(code));
          if (!legacy.exists) {
            return TicketVerifyResult(
              status: TicketVerifyStatus.notFound,
              code: code,
            );
          }
          snap = legacy;
          usingIndex = true;
        }

        final data = Map<String, dynamic>.from(snap.data() ?? {});
        final ticket = _ticketFromData(code: code, data: data);
        final already = data['checkedIn'] == true ||
            data['status'] == 'checked_in' ||
            ticket.isCheckedIn;

        if (already) {
          return TicketVerifyResult(
            status: TicketVerifyStatus.alreadyCheckedIn,
            ticket: ticket,
            code: code,
          );
        }

        final checkedInAt = DateTime.now();
        final iso = checkedInAt.toIso8601String();
        final patch = <String, dynamic>{
          'checkedIn': true,
          'checkedInAt': iso,
          'status': 'checked_in',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (usingIndex) {
          tx.set(_indexDoc(code), patch, SetOptions(merge: true));
        } else {
          tx.set(primary, patch, SetOptions(merge: true));
          final indexSnap = await tx.get(_indexDoc(code));
          if (indexSnap.exists) {
            tx.set(_indexDoc(code), patch, SetOptions(merge: true));
          }
        }

        final hostUid = data['hostUid'] as String?;
        final ownerTicketId = data['ticketId'] as String?;
        if (hostUid != null &&
            hostUid.isNotEmpty &&
            ownerTicketId != null &&
            ownerTicketId.isNotEmpty) {
          final ownerRef = _firestore
              .collection('users')
              .doc(hostUid)
              .collection('tickets')
              .doc(ownerTicketId);
          final ownerSnap = await tx.get(ownerRef);
          if (ownerSnap.exists) {
            tx.set(ownerRef, patch, SetOptions(merge: true));
          }
        }

        return TicketVerifyResult(
          status: TicketVerifyStatus.success,
          ticket: ticket.copyWith(checkedInAt: checkedInAt),
          code: code,
        );
      });
    } catch (e, st) {
      debugPrint('Public verify failed: $e\n$st');
      return TicketVerifyResult(
        status: TicketVerifyStatus.notFound,
        code: code,
      );
    }
  }

  Ticket _ticketFromData({
    required String code,
    required Map<String, dynamic> data,
  }) {
    DateTime? checkedInAt;
    final raw = data['checkedInAt'];
    if (raw is String) checkedInAt = DateTime.tryParse(raw);
    if (data['checkedIn'] == true && checkedInAt == null) {
      checkedInAt = DateTime.now();
    }

    DateTime eventAt = DateTime.now();
    final rawEvent = data['eventAt'];
    if (rawEvent is String) {
      eventAt = DateTime.tryParse(rawEvent) ?? eventAt;
    }

    return Ticket(
      id: data['ticketId'] as String? ?? code,
      headerLabel: data['headerLabel'] as String? ?? 'GUEST PASS',
      title: data['title'] as String? ??
          data['eventName'] as String? ??
          'Ticket',
      subtitle: data['subtitle'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
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
}
