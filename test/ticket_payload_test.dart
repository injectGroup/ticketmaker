import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_payload.dart';

void main() {
  group('TicketPayload', () {
    test('verificationUrl matches ticketmaker.app template', () {
      expect(
        TicketPayload.verificationUrl('1234-5678-910'),
        'https://ticketmaker.app/t/1234-5678-910',
      );
    });

    test('parseCode accepts full URL and bare code', () {
      expect(
        TicketPayload.parseCode('https://ticketmaker.app/t/1234-5678-910'),
        '1234-5678-910',
      );
      expect(
        TicketPayload.parseCode('http://www.ticketmaker.app/t/9999-8888-777'),
        '9999-8888-777',
      );
      expect(TicketPayload.parseCode('1234-5678-910'), '1234-5678-910');
    });

    test('parseCode rejects garbage', () {
      expect(TicketPayload.parseCode(''), isNull);
      expect(TicketPayload.parseCode('not-a-ticket'), isNull);
      expect(TicketPayload.parseCode('https://example.com/t/1234-5678-910'), isNull);
      expect(TicketPayload.parseCode('123-456-789'), isNull);
    });
  });
}
