import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Date and location rows with accent-tinted leading icons.
class EventMetaData extends StatelessWidget {
  const EventMetaData({
    super.key,
    required this.dateLabel,
    required this.locationLabel,
    required this.accentColor,
  });

  final String dateLabel;
  final String locationLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.secondaryText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_outlined, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Expanded(child: Text(dateLabel, style: secondary)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Expanded(child: Text(locationLabel, style: secondary)),
          ],
        ),
      ],
    );
  }
}
