import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../discover/domain/entities/event.dart';
import '../../data/seating_layout_factory.dart';
import '../../domain/seat.dart';
import '../../domain/seat_status.dart';

part 'interactive_seating_state.dart';

class InteractiveSeatingCubit extends Cubit<InteractiveSeatingState> {
  InteractiveSeatingCubit({required Event event})
    : super(
        InteractiveSeatingState(
          event: event,
          seats: SeatingLayoutFactory.build(eventId: event.id),
          unitPrice: parseUnitPrice(event.priceLabel),
        ),
      );

  static double parseUnitPrice(String priceLabel) {
    final normalized = priceLabel.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'free' ||
        normalized == '₦0' ||
        normalized == '₦0.00') {
      return 0;
    }
    final digits = priceLabel.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  static String formatTotal(double amount) {
    if (amount <= 0) return 'FREE';
    final whole = amount.truncate();
    final cents = ((amount - whole) * 100).round().abs().toString().padLeft(
      2,
      '0',
    );
    return '₦$whole.$cents';
  }

  void toggleSeat(String seatId) {
    final seats = [...state.seats];
    final index = seats.indexWhere((s) => s.id == seatId);
    if (index < 0) return;
    final seat = seats[index];
    if (seat.status == SeatStatus.soldOut) return;

    seats[index] = seat.copyWith(
      status: seat.status == SeatStatus.selected
          ? SeatStatus.available
          : SeatStatus.selected,
    );
    emit(state.copyWith(seats: seats));
  }
}
