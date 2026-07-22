import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Structured empty / error state for the ticket event photo slot.
class TicketPhotoPlaceholder extends StatelessWidget {
  const TicketPhotoPlaceholder({
    super.key,
    this.width = 300,
    this.height = 200,
    this.broken = false,
  });

  final double width;
  final double height;

  /// When true, shows a broken-image affordance instead of "add photo".
  final bool broken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondaryText.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            broken
                ? Icons.broken_image_outlined
                : Icons.add_photo_alternate_outlined,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 8),
          Text(
            broken ? 'Photo unavailable' : 'No photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
