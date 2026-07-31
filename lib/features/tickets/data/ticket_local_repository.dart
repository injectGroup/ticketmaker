import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../generate/domain/entities/ticket.dart';
import '../../../services/secure_key_value_store.dart';

/// Persists saved tickets as a JSON array in encrypted secure storage.
class TicketLocalRepository {
  TicketLocalRepository({
    SecureKeyValueStore? store,
    SharedPreferences? preferences,
  }) : this._(store ?? SecureKeyValueStore(), preferences);

  TicketLocalRepository._(this._store, this._preferences);

  static const String storageKey = 'saved_tickets_json';

  final SecureKeyValueStore _store;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<Ticket>> loadTickets() async {
    final raw = await _store.read(storageKey);
    if (raw != null && raw.isNotEmpty) {
      return _decodeTickets(raw);
    }

    // One-time migration from legacy plaintext SharedPreferences.
    final migrated = await _migrateFromSharedPreferences();
    if (migrated.isNotEmpty) {
      await saveTickets(migrated);
    }
    return migrated;
  }

  Future<void> saveTickets(List<Ticket> tickets) async {
    final encoded = jsonEncode(
      tickets.map((ticket) => ticket.toJson()).toList(growable: false),
    );
    await _store.write(storageKey, encoded);
  }

  /// Removes all persisted tickets from secure storage.
  Future<void> clearTickets() async {
    await _store.delete(storageKey);
  }

  List<Ticket> _decodeTickets(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final tickets = <Ticket>[];
      for (final entry in decoded) {
        try {
          if (entry is Map<String, dynamic>) {
            tickets.add(Ticket.fromJson(entry));
          } else if (entry is Map) {
            tickets.add(Ticket.fromJson(Map<String, dynamic>.from(entry)));
          } else if (entry is String) {
            // Legacy string-list entries (each item was jsonEncode(ticket)).
            final nested = jsonDecode(entry);
            if (nested is Map<String, dynamic>) {
              tickets.add(Ticket.fromJson(nested));
            } else if (nested is Map) {
              tickets.add(Ticket.fromJson(Map<String, dynamic>.from(nested)));
            }
          }
        } on FormatException {
          // Skip corrupt entries.
        } on TypeError {
          // Skip corrupt entries.
        }
      }
      return tickets;
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<List<Ticket>> _migrateFromSharedPreferences() async {
    try {
      final prefs = await _prefs();
      final legacy = prefs.getStringList(storageKey);
      if (legacy == null || legacy.isEmpty) return const [];

      final tickets = <Ticket>[];
      for (final entry in legacy) {
        try {
          final decoded = jsonDecode(entry);
          if (decoded is Map<String, dynamic>) {
            tickets.add(Ticket.fromJson(decoded));
          } else if (decoded is Map) {
            tickets.add(Ticket.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } on FormatException {
          // Skip corrupt entries.
        } on TypeError {
          // Skip corrupt entries.
        }
      }
      await prefs.remove(storageKey);
      return tickets;
    } on Object {
      return const [];
    }
  }
}
