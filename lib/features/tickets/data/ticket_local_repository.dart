import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../generate/domain/entities/ticket.dart';

/// Persists saved tickets as a JSON string list in SharedPreferences.
class TicketLocalRepository {
  TicketLocalRepository({this._preferences});

  static const String storageKey = 'saved_tickets_json';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<Ticket>> loadTickets() async {
    final prefs = await _prefs();
    final raw = prefs.getStringList(storageKey) ?? const <String>[];
    final tickets = <Ticket>[];
    for (final entry in raw) {
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
    return tickets;
  }

  Future<void> saveTickets(List<Ticket> tickets) async {
    final prefs = await _prefs();
    final encoded = tickets
        .map((ticket) => jsonEncode(ticket.toJson()))
        .toList(growable: false);
    await prefs.setStringList(storageKey, encoded);
  }

  /// Removes all persisted tickets from SharedPreferences.
  Future<void> clearTickets() async {
    final prefs = await _prefs();
    await prefs.remove(storageKey);
  }
}
