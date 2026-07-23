import '../domain/seat.dart';
import '../domain/seat_status.dart';

/// Builds a 3×10 seating grid; ~20% of seats sold out, seeded by [eventId].
abstract final class SeatingLayoutFactory {
  static const rows = ['A', 'B', 'C'];
  static const seatsPerRow = 10;

  static List<Seat> build({required String eventId}) {
    final sold = _soldOutIds(eventId);
    final seats = <Seat>[];
    for (final row in rows) {
      for (var n = 1; n <= seatsPerRow; n++) {
        final id = '$row$n';
        seats.add(
          Seat(
            id: id,
            row: row,
            number: n,
            status: sold.contains(id)
                ? SeatStatus.soldOut
                : SeatStatus.available,
          ),
        );
      }
    }
    return seats;
  }

  static Set<String> _soldOutIds(String eventId) {
    // Deterministic pseudo-random selection from event id.
    var hash = 0;
    for (final code in eventId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final sold = <String>{};
    final total = rows.length * seatsPerRow;
    final target = (total * 0.2).round().clamp(1, total);
    var cursor = hash;
    while (sold.length < target) {
      cursor = (cursor * 1103515245 + 12345) & 0x7fffffff;
      final index = cursor % total;
      final row = rows[index ~/ seatsPerRow];
      final number = (index % seatsPerRow) + 1;
      sold.add('$row$number');
    }
    return sold;
  }
}
