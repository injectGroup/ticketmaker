import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../generate/domain/entities/ticket.dart';

/// Persists saved tickets as a JSON array in encrypted secure storage.
class TicketLocalRepository {
  TicketLocalRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // ignore: deprecated_member_use
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String storageKey = 'saved_tickets_json';

  final FlutterSecureStorage _storage;

  Future<List<Ticket>> loadTickets() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.isEmpty) return const [];
    return _decodeTickets(raw);
  }

  Future<void> saveTickets(List<Ticket> tickets) async {
    final encoded = jsonEncode(
      tickets.map((ticket) => ticket.toJson()).toList(growable: false),
    );
    await _storage.write(key: storageKey, value: encoded);
  }

  /// Removes all persisted tickets from secure storage.
  Future<void> clearTickets() async {
    await _storage.delete(key: storageKey);
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
}
