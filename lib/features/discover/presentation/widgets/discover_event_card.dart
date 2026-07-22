import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/event.dart';

class DiscoverEventCard extends StatelessWidget {
  const DiscoverEventCard({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(event.category),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${event.venue} · ${event.city}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  '${event.dateLabel} · ${event.timeLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(child: ColoredBox(color: event.eyeColor)),
                    Expanded(child: ColoredBox(color: event.dataModuleColor)),
                    Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              event.backgroundStart.withValues(alpha: 1),
                              event.backgroundEnd.withValues(alpha: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
