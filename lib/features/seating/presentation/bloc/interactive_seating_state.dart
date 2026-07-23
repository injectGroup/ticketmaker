part of 'interactive_seating_cubit.dart';

class InteractiveSeatingState extends Equatable {
  const InteractiveSeatingState({
    required this.event,
    required this.seats,
    required this.unitPrice,
  });

  final Event event;
  final List<Seat> seats;
  final double unitPrice;

  List<Seat> get selectedSeats =>
      seats.where((s) => s.status == SeatStatus.selected).toList();

  int get selectedCount => selectedSeats.length;

  List<String> get selectedLabels =>
      selectedSeats.map((s) => s.displayLabel).toList();

  List<String> get selectedShortCodes =>
      selectedSeats.map((s) => s.shortCode).toList();

  double get totalPrice => selectedCount * unitPrice;

  String get totalPriceLabel =>
      InteractiveSeatingCubit.formatTotal(totalPrice);

  bool get canCheckout => selectedCount > 0;

  Map<String, List<Seat>> get seatsByRow {
    final map = <String, List<Seat>>{};
    for (final seat in seats) {
      map.putIfAbsent(seat.row, () => []).add(seat);
    }
    return map;
  }

  InteractiveSeatingState copyWith({
    Event? event,
    List<Seat>? seats,
    double? unitPrice,
  }) {
    return InteractiveSeatingState(
      event: event ?? this.event,
      seats: seats ?? this.seats,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [event, seats, unitPrice];
}
