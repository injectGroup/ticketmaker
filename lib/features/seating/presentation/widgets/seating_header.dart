import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../discover/domain/entities/event.dart';

class SeatingHeader extends StatelessWidget {
  const SeatingHeader({
    super.key,
    required this.event,
    required this.onBack,
  });

  final Event event;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.dateLabel} · ${event.timeLabel}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${event.venue}, ${event.city}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
