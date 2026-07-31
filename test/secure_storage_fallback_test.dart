import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';
import 'package:ticket_maker/services/secure_key_value_store.dart';

Ticket _sample() {
  return Ticket(
    id: 'ticket-1',
    headerLabel: 'VIP',
    title: 'Concert',
    subtitle: 'Venue',
    venue: '',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 18, 20),
    code: '1111-2222-333',
    qrData: 'https://quick-ticket-maker-sandbox.web.app/verify/1111-2222-333',
    imagePath: '',
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFFFF9800),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );
}

/// Platform that always throws [MissingPluginException], simulating a stale
/// web registrant where flutter_secure_storage_web was never registered.
class _MissingPluginSecureStoragePlatform extends FlutterSecureStoragePlatform {
  MissingPluginException get _error => MissingPluginException(
        'No implementation found for method write on channel '
        'plugins.it_nomads.com/flutter_secure_storage',
      );

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      throw _error;

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async =>
      throw _error;

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      throw _error;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async =>
      throw _error;

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      throw _error;

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async =>
      throw _error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('legacy SharedPreferences migration', () {
    test('migrates string-list tickets into secure storage and clears prefs',
        () async {
      final ticket = _sample();
      SharedPreferences.setMockInitialValues({
        TicketLocalRepository.storageKey: <String>[jsonEncode(ticket.toJson())],
      });
      FlutterSecureStorage.setMockInitialValues({});

      final repo = TicketLocalRepository();
      final loaded = await repo.loadTickets();

      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Concert');
      expect(loaded.single.code, '1111-2222-333');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(TicketLocalRepository.storageKey), isNull);

      // Reloading should hit secure storage, not legacy prefs.
      final again = await repo.loadTickets();
      expect(again, hasLength(1));
      expect(again.single.title, 'Concert');
    });
  });

  group('SharedPreferences fallback when plugin missing', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStoragePlatform.instance =
          _MissingPluginSecureStoragePlatform();
    });

    test('saveTickets / loadTickets round-trip via fallback', () async {
      final store = SecureKeyValueStore();
      final repo = TicketLocalRepository(store: store);

      await repo.saveTickets([_sample()]);
      expect(store.isDegraded, isTrue);

      final loaded = await repo.loadTickets();
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Concert');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(
          '${SecureKeyValueStore.fallbackKeyPrefix}'
          '${TicketLocalRepository.storageKey}',
        ),
        isTrue,
      );
    });

    test('SecureKeyValueStore write/read/delete use fallback prefix', () async {
      final store = SecureKeyValueStore();
      await store.write('hello', 'world');
      expect(store.isDegraded, isTrue);
      expect(await store.read('hello'), 'world');

      final all = await store.readAll();
      expect(all['hello'], 'world');

      await store.delete('hello');
      expect(await store.read('hello'), isNull);
    });
  });
}
