import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/models/ticket_config.dart';
import 'package:ticket_maker/services/secure_key_value_store.dart';
import 'package:ticket_maker/services/secure_storage_service.dart';

TicketConfig _config({String guestName = 'Ada Lovelace'}) {
  return TicketConfig(
    eventName: "Ejike's Birthday Bash",
    subtitle: 'VIP Guest Pass',
    payloadUrl: 'https://quick-ticket-maker-sandbox.web.app/verify/',
    guestName: guestName,
    generatedAt: DateTime(2026, 7, 31, 12, 34, 56),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureKeyValueStore store;
  late SecureStorageService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureKeyValueStore();
    service = SecureStorageService(store: store);
  });

  test('saveTicket then getTicket round-trips the config', () async {
    await service.saveTicket('ticket-1', _config());

    final loaded = await service.getTicket('ticket-1');

    expect(loaded, isNotNull);
    expect(loaded!.eventName, "Ejike's Birthday Bash");
    expect(loaded.subtitle, 'VIP Guest Pass');
    expect(loaded.guestName, 'Ada Lovelace');
    expect(loaded.generatedAt, DateTime(2026, 7, 31, 12, 34, 56));
  });

  test('getTicket returns null for an unknown id', () async {
    expect(await service.getTicket('never-saved'), isNull);
  });

  test('saveTicket overwrites an existing id', () async {
    await service.saveTicket('ticket-1', _config(guestName: 'First'));
    await service.saveTicket('ticket-1', _config(guestName: 'Second'));

    final loaded = await service.getTicket('ticket-1');

    expect(loaded!.guestName, 'Second');
  });

  test('namespaces stored keys with the ticket_config_ prefix', () async {
    await service.saveTicket('ticket-1', _config());

    expect((await store.readAll()).keys, contains('ticket_config_ticket-1'));
  });

  test('deleteTicket removes only the targeted id', () async {
    await service.saveTicket('keep', _config(guestName: 'Keep'));
    await service.saveTicket('drop', _config(guestName: 'Drop'));

    await service.deleteTicket('drop');

    expect(await service.getTicket('drop'), isNull);
    expect((await service.getTicket('keep'))!.guestName, 'Keep');
  });

  test('deleteTicket on an unknown id is a no-op', () async {
    await service.saveTicket('keep', _config());

    await service.deleteTicket('never-saved');

    expect(await service.getTicket('keep'), isNotNull);
  });

  test('clearAllTickets removes configs but leaves unrelated keys', () async {
    await service.saveTicket('ticket-1', _config());
    await service.saveTicket('ticket-2', _config());
    await store.write('saved_tickets', 'unrelated payload');

    await service.clearAllTickets();

    expect(await service.getTicket('ticket-1'), isNull);
    expect(await service.getTicket('ticket-2'), isNull);
    expect(await store.read('saved_tickets'), 'unrelated payload');
  });

  test('getTicket returns null for corrupt stored JSON', () async {
    await store.write('ticket_config_broken', '{not json');

    expect(await service.getTicket('broken'), isNull);
  });

  test('getTicket returns null for an empty stored value', () async {
    await store.write('ticket_config_empty', '');

    expect(await service.getTicket('empty'), isNull);
  });
}
