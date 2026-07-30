import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ticket_config.dart';

/// Persists [TicketConfig] entries in platform secure storage.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // ignore: deprecated_member_use
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'ticket_config_';

  String _key(String ticketId) => '$_keyPrefix$ticketId';

  Future<void> saveTicket(String ticketId, TicketConfig config) async {
    await _storage.write(
      key: _key(ticketId),
      value: config.toJsonString(),
    );
  }

  Future<TicketConfig?> getTicket(String ticketId) async {
    final raw = await _storage.read(key: _key(ticketId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return TicketConfig.fromJsonString(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    await _storage.delete(key: _key(ticketId));
  }

  Future<void> clearAllTickets() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_keyPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }
}
