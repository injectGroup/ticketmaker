import '../models/ticket_config.dart';
import 'secure_key_value_store.dart';

/// Persists [TicketConfig] entries in platform secure storage.
class SecureStorageService {
  SecureStorageService({SecureKeyValueStore? store})
      : _store = store ?? SecureKeyValueStore();

  final SecureKeyValueStore _store;

  static const String _keyPrefix = 'ticket_config_';

  String _key(String ticketId) => '$_keyPrefix$ticketId';

  Future<void> saveTicket(String ticketId, TicketConfig config) async {
    await _store.write(_key(ticketId), config.toJsonString());
  }

  Future<TicketConfig?> getTicket(String ticketId) async {
    final raw = await _store.read(_key(ticketId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return TicketConfig.fromJsonString(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    await _store.delete(_key(ticketId));
  }

  Future<void> clearAllTickets() async {
    final all = await _store.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_keyPrefix)) {
        await _store.delete(key);
      }
    }
  }
}
