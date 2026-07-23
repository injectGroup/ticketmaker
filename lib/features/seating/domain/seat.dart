import 'package:equatable/equatable.dart';

import 'seat_status.dart';

class Seat extends Equatable {
  const Seat({
    required this.id,
    required this.row,
    required this.number,
    required this.status,
  });

  final String id;
  final String row;
  final int number;
  final SeatStatus status;

  String get displayLabel => 'Row $row - Seat $number';

  String get shortCode => '$row$number';

  Seat copyWith({SeatStatus? status}) {
    return Seat(
      id: id,
      row: row,
      number: number,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, row, number, status];
}
