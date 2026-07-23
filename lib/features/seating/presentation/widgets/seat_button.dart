import 'package:flutter/material.dart';

import '../../domain/seat.dart';
import '../../domain/seat_status.dart';

abstract final class SeatButtonColors {
  static const Color available = Color(0xFF2E7D32);
  static const Color selected = Color(0xFF1565C0);
  static const Color soldOut = Color(0xFF9E9E9E);
}

class SeatButton extends StatelessWidget {
  const SeatButton({
    super.key,
    required this.seat,
    required this.size,
    required this.onTap,
  });

  final Seat seat;
  final double size;
  final VoidCallback? onTap;

  Color get _fill {
    switch (seat.status) {
      case SeatStatus.available:
        return SeatButtonColors.available;
      case SeatStatus.selected:
        return SeatButtonColors.selected;
      case SeatStatus.soldOut:
        return SeatButtonColors.soldOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final soldOut = seat.status == SeatStatus.soldOut;
    final selected = seat.status == SeatStatus.selected;
    final label = soldOut
        ? '${seat.shortCode} sold out'
        : selected
        ? '${seat.shortCode} selected'
        : '${seat.shortCode} available';

    return Semantics(
      button: true,
      enabled: !soldOut,
      selected: selected,
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: _fill,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: soldOut ? null : onTap,
            borderRadius: BorderRadius.circular(6),
            child: Center(
              child: Text(
                '${seat.number}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.35,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
