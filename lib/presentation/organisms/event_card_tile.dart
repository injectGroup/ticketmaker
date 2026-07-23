import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/discover/domain/entities/event.dart';
import '../../features/discover/presentation/theme/event_theme.dart';
import '../../features/discover/presentation/widgets/event_hero_header.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/price_label.dart';
import '../molecules/event_meta_data.dart';

/// Discover event card: banner, meta, price, badge, and Book Spot CTA.
class EventCardTile extends StatelessWidget {
  const EventCardTile({
    super.key,
    required this.event,
    this.onTap,
    this.onBookSpot,
  });

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onBookSpot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = EventTheme.accent(event.category);
    final onAccent = EventTheme.onAccent(event.category);

    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventHeroHeader(event: event),
            Padding(
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
                      AppBadge(
                        label: event.category,
                        backgroundColor: EventTheme.chipBackground(
                          event.category,
                        ),
                        foregroundColor: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  EventMetaData(
                    dateLabel: '${event.dateLabel} · ${event.timeLabel}',
                    locationLabel: '${event.venue} · ${event.city}',
                    accentColor: accent,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PriceLabel(rawPrice: event.priceLabel),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Book Spot',
                    icon: Icons.confirmation_number_outlined,
                    backgroundColor: accent,
                    foregroundColor: onAccent,
                    onPressed: onBookSpot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
