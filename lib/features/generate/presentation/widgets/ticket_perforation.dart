import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashed_divider.dart';

/// Ticket stub with side notches and a dashed perforation line.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({
    super.key,
    this.notchColor = AppColors.primaryBackground,
    this.bandColor = AppColors.secondary,
  });

  /// Matches the page/canvas behind the pass card so cutouts look punched out.
  final Color notchColor;
  final Color bandColor;

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
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: DashedDivider(thickness: 2.5, color: AppColors.primary),
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
