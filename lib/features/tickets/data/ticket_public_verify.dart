import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../generate/domain/entities/ticket.dart';
import 'ticket_payload.dart';

/// Public (no-auth) door verification against [ticketIndex].
///
/// Used by the hosted `/verify/:code` page when a gatekeeper scans a guest QR.
class TicketPublicVerify {
  TicketPublicVerify({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _indexDoc(String code) =>
      _firestore.collection('ticketIndex').doc(code);

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
        final ref = _indexDoc(code);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          return TicketVerifyResult(
            status: TicketVerifyStatus.notFound,
            code: code,
          );
        }

        final data = Map<String, dynamic>.from(snap.data() ?? {});
        final ticket = _ticketFromIndex(code: code, data: data);
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
        final ticketId = data['ticketId'] as String?;
        if (hostUid != null &&
            hostUid.isNotEmpty &&
            ticketId != null &&
            ticketId.isNotEmpty) {
          final ticketRef = _firestore
              .collection('users')
              .doc(hostUid)
              .collection('tickets')
              .doc(ticketId);
          final ticketSnap = await tx.get(ticketRef);
          if (ticketSnap.exists) {
            tx.set(
              ticketRef,
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
      // Permission / missing index → treat as invalid for the gatekeeper UI.
      return TicketVerifyResult(
        status: TicketVerifyStatus.notFound,
        code: code,
      );
    }
  }

  Ticket _ticketFromIndex({
    required String code,
    required Map<String, dynamic> data,
  }) {
    DateTime? checkedInAt;
    final raw = data['checkedInAt'];
    if (raw is String) checkedInAt = DateTime.tryParse(raw);
    if (data['checkedIn'] == true && checkedInAt == null) {
      checkedInAt = DateTime.now();
    }
    return Ticket(
      id: data['ticketId'] as String? ?? code,
      headerLabel: 'GUEST PASS',
      title: data['title'] as String? ?? 'Ticket',
      subtitle: data['subtitle'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
      dateLabel: '',
      timeLabel: '',
      eventAt: DateTime.now(),
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
