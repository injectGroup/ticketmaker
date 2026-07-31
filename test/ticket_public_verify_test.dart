import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:ticket_maker/features/tickets/data/ticket_payload.dart';
import 'package:ticket_maker/features/tickets/data/ticket_public_verify.dart';

const _code = '1234-5678-910';

Map<String, dynamic> _validDoc({
  String status = 'valid',
  String? hostUid,
  String? internalTicketId,
}) {
  return <String, dynamic>{
    'status': status,
    'eventName': "Ejike's Birthday Bash",
    'guestName': 'Ada Lovelace',
    'eventDate': 'Fri, 31 Jul 2026',
    'timeLabel': '8:00 PM',
    'eventAt': DateTime(2026, 7, 31, 20).toIso8601String(),
    'qrData': TicketPayload.verificationUrl(_code),
    'hostUid': ?hostUid,
    'internalTicketId': ?internalTicketId,
  };
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TicketPublicVerify verifier;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    verifier = TicketPublicVerify(firestore: firestore);
  });

  Future<Map<String, dynamic>?> readTicket() async {
    final snap = await firestore.collection('tickets').doc(_code).get();
    return snap.data();
  }

  group('payload handling', () {
    test('rejects text that is not a ticket payload', () async {
      final result = await verifier.verifyAndCheckIn('not-a-ticket');

      expect(result.status, TicketVerifyStatus.invalidPayload);
      expect(result.code, isNull);
    });

    test('reports notFound for a well-formed but unknown code', () async {
      final result = await verifier.verifyAndCheckIn('9999-8888-777');

      expect(result.status, TicketVerifyStatus.notFound);
      expect(result.code, '9999-8888-777');
    });

    test('resolves a full QR URL and a bare code to the same document',
        () async {
      await firestore.collection('tickets').doc(_code).set(_validDoc());

      final fromUrl = await verifier.verifyAndCheckIn(
        TicketPayload.verificationUrl(_code),
      );
      expect(fromUrl.status, TicketVerifyStatus.success);

      final fromCode = await verifier.verifyAndCheckIn(_code);
      expect(fromCode.status, TicketVerifyStatus.alreadyCheckedIn);
      expect(fromCode.code, _code);
    });
  });

  group('single-use admission', () {
    test('admits a valid ticket and stamps the check-in', () async {
      await firestore.collection('tickets').doc(_code).set(_validDoc());

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.success);
      expect(result.isSuccess, isTrue);
      expect(result.ticket!.title, "Ejike's Birthday Bash");
      expect(result.ticket!.subtitle, 'Ada Lovelace');
      expect(result.ticket!.checkedInAt, isNotNull);

      final stored = await readTicket();
      expect(stored!['checkedIn'], isTrue);
      expect(stored['status'], 'checked_in');
      expect(stored['checkedInAt'], isA<String>());
    });

    test('refuses the second scan of the same ticket', () async {
      await firestore.collection('tickets').doc(_code).set(_validDoc());

      expect(
        (await verifier.verifyAndCheckIn(_code)).status,
        TicketVerifyStatus.success,
      );
      expect(
        (await verifier.verifyAndCheckIn(_code)).status,
        TicketVerifyStatus.alreadyCheckedIn,
      );
    });

    test('treats a legacy checkedIn flag without status as used', () async {
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'checkedIn': true,
        'eventName': 'Legacy Event',
      });

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.alreadyCheckedIn);
      expect(result.ticket!.checkedInAt, isNotNull);
    });

    test('refuses any status other than valid', () async {
      await firestore
          .collection('tickets')
          .doc(_code)
          .set(_validDoc(status: 'revoked'));

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.alreadyCheckedIn);
      final stored = await readTicket();
      expect(stored!['status'], 'revoked', reason: 'must not overwrite');
    });

    test('admits a document that carries no status field', () async {
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'eventName': 'No Status Event',
      });

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.success);
    });

    test('reports checkInFailed when the admit write is rejected', () async {
      final doc = firestore.collection('tickets').doc(_code);
      await doc.set(_validDoc());
      whenCalling(Invocation.method(#set, null)).on(doc).thenThrow(
            FirebaseException(plugin: 'firestore', code: 'permission-denied'),
          );

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.checkInFailed);
      expect(result.code, _code);
      expect(result.ticket, isNotNull);
    });
  });

  group('owner document sync', () {
    test('mirrors the check-in onto the host copy', () async {
      await firestore.collection('tickets').doc(_code).set(
            _validDoc(hostUid: 'host-1', internalTicketId: 'ticket-1'),
          );

      final result = await verifier.verifyAndCheckIn(_code);
      expect(result.status, TicketVerifyStatus.success);

      final owner = await firestore
          .collection('users')
          .doc('host-1')
          .collection('tickets')
          .doc('ticket-1')
          .get();
      expect(owner.data()!['checkedIn'], isTrue);
      expect(owner.data()!['status'], 'checked_in');
    });

    test('still admits the guest when the host copy cannot be written',
        () async {
      await firestore.collection('tickets').doc(_code).set(
            _validDoc(hostUid: 'host-1', internalTicketId: 'ticket-1'),
          );
      final ownerDoc = firestore
          .collection('users')
          .doc('host-1')
          .collection('tickets')
          .doc('ticket-1');
      whenCalling(Invocation.method(#set, null)).on(ownerDoc).thenThrow(
            FirebaseException(plugin: 'firestore', code: 'permission-denied'),
          );

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.success);
      expect((await readTicket())!['checkedIn'], isTrue);
    });

    test('skips the sync when host identifiers are absent', () async {
      await firestore.collection('tickets').doc(_code).set(_validDoc());

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.status, TicketVerifyStatus.success);
      final users = await firestore.collection('users').get();
      expect(users.docs, isEmpty);
    });
  });

  group('field fallbacks', () {
    test('falls back from eventName to title, then to a generic label',
        () async {
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'status': 'valid',
        'title': 'Legacy Title',
      });

      final fromTitle = await verifier.verifyAndCheckIn(_code);
      expect(fromTitle.ticket!.title, 'Legacy Title');

      await firestore
          .collection('tickets')
          .doc('2222-3333-444')
          .set(<String, dynamic>{'status': 'valid'});

      final bare = await verifier.verifyAndCheckIn('2222-3333-444');
      expect(bare.ticket!.title, 'Ticket');
    });

    test('derives qrData from the code when the document omits it', () async {
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'status': 'valid',
      });

      final result = await verifier.verifyAndCheckIn(_code);

      expect(result.ticket!.qrData, TicketPayload.verificationUrl(_code));
      expect(result.ticket!.id, _code, reason: 'falls back to the guest code');
    });
  });
}
