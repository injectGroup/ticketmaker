import 'package:flutter/material.dart';

import 'seat_button.dart';

class SeatingLegend extends StatelessWidget {
  const SeatingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _LegendItem(
            color: SeatButtonColors.available,
            label: 'Available',
            style: theme.textTheme.bodySmall,
          ),
          _LegendItem(
            color: SeatButtonColors.selected,
            label: 'Selected',
            style: theme.textTheme.bodySmall,
          ),
          _LegendItem(
            color: SeatButtonColors.soldOut,
            label: 'Sold Out',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.style,
  });

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
