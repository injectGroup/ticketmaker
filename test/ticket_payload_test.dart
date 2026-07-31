import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_payload.dart';

void main() {
  group('TicketPayload', () {
    test('verificationUrl uses Hosting /verify path', () {
      expect(
        TicketPayload.verificationUrl('1234-5678-910'),
        'https://quick-ticket-maker-sandbox.web.app/verify/1234-5678-910',
      );
    });

    test('parseCode accepts verify URL, legacy /t/, and bare code', () {
      expect(
        TicketPayload.parseCode(
          'https://quick-ticket-maker-sandbox.web.app/verify/1234-5678-910',
        ),
        '1234-5678-910',
      );
      expect(
        TicketPayload.parseCode(
          'https://ticketmaker.app/t/9999-8888-777',
        ),
        '9999-8888-777',
      );
      expect(TicketPayload.parseCode('1234-5678-910'), '1234-5678-910');
    });

    test('parseCode rejects garbage', () {
      expect(TicketPayload.parseCode(''), isNull);
      expect(TicketPayload.parseCode('not-a-ticket'), isNull);
      expect(
        TicketPayload.parseCode('https://example.com/verify/1234-5678-910'),
        isNull,
      );
      expect(TicketPayload.parseCode('123-456-789'), isNull);
    });
  });
}
