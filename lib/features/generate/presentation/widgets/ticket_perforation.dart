import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashed_divider.dart';

/// Ticket stub with side notches and a dashed perforation line.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.secondary,
      child: Row(
        children: [
          Container(
            width: 15,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: DashedDivider(
                thickness: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          Container(
            width: 15,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.only(
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
