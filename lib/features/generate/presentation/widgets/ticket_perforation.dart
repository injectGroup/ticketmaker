import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashed_divider.dart';

/// Ticket stub with white side notches and a dashed blue tear-line.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({
    super.key,
    this.notchColor = AppColors.secondaryBackground,
    this.bandColor = AppColors.brandDarkPlum,
    this.dashColor = AppColors.primary,
  });

  /// Matches the canvas behind the pass so cutouts look punched out.
  final Color notchColor;
  final Color bandColor;
  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      color: bandColor,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 24,
            decoration: BoxDecoration(
              color: notchColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DashedDivider(
                thickness: 2,
                dashWidth: 6,
                dashSpace: 4,
                color: dashColor,
              ),
            ),
          ),
          Container(
            width: 16,
            height: 24,
            decoration: BoxDecoration(
              color: notchColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(100),
                bottomLeft: Radius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
