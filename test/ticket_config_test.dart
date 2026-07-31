import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_payload.dart';
import 'package:ticket_maker/models/ticket_config.dart';

void main() {
  group('TicketConfig.v1Default', () {
    test('carries the protected V1 host defaults', () {
      final config = TicketConfig.v1Default(guestName: 'Ada Lovelace');

      expect(config.eventName, "Ejike's Birthday Bash");
      expect(config.subtitle, 'VIP Guest Pass');
      expect(config.guestName, 'Ada Lovelace');
    });

    test('builds the payload URL from the live verification host', () {
      final config = TicketConfig.v1Default(guestName: 'Ada');

      // Pinned to TicketPayload so the model cannot drift away from the host
      // that QR codes actually encode.
      expect(config.payloadUrl, 'https://${TicketPayload.host}/verify/');
    });

    test('stamps generatedAt at creation time', () {
      final before = DateTime.now();
      final config = TicketConfig.v1Default(guestName: 'Ada');
      final after = DateTime.now();

      expect(
        config.generatedAt.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        config.generatedAt.isAfter(after.add(const Duration(seconds: 1))),
        isFalse,
      );
    });
  });

  group('serialization', () {
    test('round-trips every field including the generatedAt instant', () {
      final original = TicketConfig(
        eventName: "Ejike's Birthday Bash",
        subtitle: 'VIP Guest Pass',
        payloadUrl: 'https://${TicketPayload.host}/verify/',
        guestName: 'Ada Lovelace',
        generatedAt: DateTime(2026, 7, 31, 12, 34, 56, 789),
      );

      final restored = TicketConfig.fromJsonString(original.toJsonString());

      expect(restored.eventName, original.eventName);
      expect(restored.subtitle, original.subtitle);
      expect(restored.payloadUrl, original.payloadUrl);
      expect(restored.guestName, original.guestName);
      expect(restored.generatedAt, original.generatedAt);
    });

    test('toJson uses ISO-8601 for generatedAt', () {
      final config = TicketConfig(
        eventName: 'Event',
        subtitle: 'Pass',
        payloadUrl: 'https://example.test/verify/',
        guestName: 'Guest',
        generatedAt: DateTime(2026, 1, 2, 3, 4, 5),
      );

      expect(config.toJson()['generatedAt'], '2026-01-02T03:04:05.000');
    });

    test('fromJson defaults missing fields instead of throwing', () {
      final config = TicketConfig.fromJson(const <String, dynamic>{});

      expect(config.eventName, '');
      expect(config.subtitle, '');
      expect(config.payloadUrl, '');
      expect(config.guestName, '');
      expect(config.generatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromJson falls back to the epoch on an unparseable date', () {
      final config = TicketConfig.fromJson(const <String, dynamic>{
        'eventName': 'Event',
        'generatedAt': 'not-a-date',
      });

      expect(config.eventName, 'Event');
      expect(config.generatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromJsonString rejects malformed JSON', () {
      expect(
        () => TicketConfig.fromJsonString('{not json'),
        throwsFormatException,
      );
    });

    test('fromJsonString rejects JSON that is not an object', () {
      expect(
        () => TicketConfig.fromJsonString('[1, 2, 3]'),
        throwsFormatException,
      );
      expect(
        () => TicketConfig.fromJsonString('"just a string"'),
        throwsFormatException,
      );
    });
  });
}
