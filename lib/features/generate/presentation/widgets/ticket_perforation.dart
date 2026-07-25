import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashed_divider.dart';

/// Ticket stub with side notches and a subtle dashed tear-line.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({
    super.key,
    this.notchColor = AppColors.primaryBackground,
    this.bandColor,
    this.dashColor = Colors.white70,
  });

  /// Matches the page/canvas behind the pass card so cutouts look punched out.
  final Color notchColor;

  /// Band behind the tear-line. Null = transparent (continuous card look).
  final Color? bandColor;

  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      color: bandColor ?? Colors.transparent,
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
                thickness: 1.5,
                dashWidth: 5,
                dashSpace: 5,
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
