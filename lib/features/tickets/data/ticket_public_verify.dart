import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_payload.dart';

/// Public door verification against top-level `tickets/{ticketId}`.
///
/// Document id is the guest code (`####-####-###`) from the QR URL.
class TicketPublicVerify {
  TicketPublicVerify({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ticketsDoc(String id) =>
      _firestore.collection('tickets').doc(id);

  /// Looks up [rawOrCode], admits once when `status == valid`, and returns UI result.
  Future<TicketVerifyResult> verifyAndCheckIn(String rawOrCode) async {
    final code = TicketPayload.parseCode(rawOrCode);
    if (code == null) {
      return const TicketVerifyResult(
        status: TicketVerifyStatus.invalidPayload,
      );
    }

    try {
      return await _firestore.runTransaction((tx) async {
        final ref = _ticketsDoc(code);
        final snap = await tx.get(ref);

        // Red INVALID only when the public doc is missing.
        if (!snap.exists) {
          return TicketVerifyResult(
            status: TicketVerifyStatus.notFound,
            code: code,
          );
        }

        final data = Map<String, dynamic>.from(snap.data() ?? {});
        final ticket = _ticketFromData(code: code, data: data);
        final status = (data['status'] as String?)?.trim().toLowerCase() ?? '';

        if (status == 'checked_in' || data['checkedIn'] == true) {
          return TicketVerifyResult(
            status: TicketVerifyStatus.alreadyCheckedIn,
            ticket: ticket,
            code: code,
          );
        }

        // Treat missing/unknown status as valid so older docs still admit once.
        if (status.isNotEmpty && status != 'valid') {
          return TicketVerifyResult(
            status: TicketVerifyStatus.alreadyCheckedIn,
            ticket: ticket,
            code: code,
          );
        }

        final checkedInAt = DateTime.now();
        final iso = checkedInAt.toIso8601String();
        tx.set(
          ref,
          {
            'checkedIn': true,
            'checkedInAt': iso,
            'status': 'checked_in',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        final hostUid = data['hostUid'] as String?;
        final internalId = data['internalTicketId'] as String?;
        if (hostUid != null &&
            hostUid.isNotEmpty &&
            internalId != null &&
            internalId.isNotEmpty) {
          final ownerRef = _firestore
              .collection('users')
              .doc(hostUid)
              .collection('tickets')
              .doc(internalId);
          final ownerSnap = await tx.get(ownerRef);
          if (ownerSnap.exists) {
            tx.set(
              ownerRef,
              {
                'checkedIn': true,
                'checkedInAt': iso,
                'status': 'checked_in',
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
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
      // Permission / network errors — surface as invalid so the gatekeeper
      // does not falsely admit.
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
      id: data['internalTicketId'] as String? ?? code,
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
}
