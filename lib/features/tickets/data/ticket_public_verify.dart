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

    final ref = _ticketsDoc(code);

    late final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await ref.get();
    } catch (e, st) {
      debugPrint('Public verify read failed: $e\n$st');
      return TicketVerifyResult(
        status: TicketVerifyStatus.checkInFailed,
        code: code,
      );
    }

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

    if (status.isNotEmpty && status != 'valid') {
      return TicketVerifyResult(
        status: TicketVerifyStatus.alreadyCheckedIn,
        ticket: ticket,
        code: code,
      );
    }

    final checkedInAt = DateTime.now();
    final iso = checkedInAt.toIso8601String();
    try {
      await ref.set(
        {
          'checkedIn': true,
          'checkedInAt': iso,
          'status': 'checked_in',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('Public verify check-in write failed: $e\n$st');
      return TicketVerifyResult(
        status: TicketVerifyStatus.checkInFailed,
        ticket: ticket,
        code: code,
      );
    }

    // Best-effort owner doc sync — must not fail the public admit.
    final hostUid = data['hostUid'] as String?;
    final internalId = data['internalTicketId'] as String?;
    if (hostUid != null &&
        hostUid.isNotEmpty &&
        internalId != null &&
        internalId.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(hostUid)
            .collection('tickets')
            .doc(internalId)
            .set(
              {
                'checkedIn': true,
                'checkedInAt': iso,
                'status': 'checked_in',
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      } catch (e, st) {
        debugPrint('Owner check-in sync skipped: $e\n$st');
      }
    }

    return TicketVerifyResult(
      status: TicketVerifyStatus.success,
      ticket: ticket.copyWith(checkedInAt: checkedInAt),
      code: code,
    );
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
