import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/seat.dart';
import 'seat_button.dart';

class SeatingGrid extends StatelessWidget {
  const SeatingGrid({
    super.key,
    required this.seatsByRow,
    required this.onSeatTap,
  });

  final Map<String, List<Seat>> seatsByRow;
  final ValueChanged<String> onSeatTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final seatSize = width < 360
            ? 28.0
            : width < 600
            ? 34.0
            : 42.0;
        final gap = width < 360 ? 4.0 : 6.0;

        return Column(
          children: [
            for (final entry in seatsByRow.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: AppColors.secondaryText),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final seat in entry.value)
                            SeatButton(
                              seat: seat,
                              size: seatSize,
                              onTap: () => onSeatTap(seat.id),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
