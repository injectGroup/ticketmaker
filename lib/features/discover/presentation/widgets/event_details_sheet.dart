import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_gate.dart';
import '../../domain/entities/event.dart';
import '../theme/event_theme.dart';
import 'event_hero_header.dart';

Future<void> showEventDetailsSheet(
  BuildContext context, {
  required Event event,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.secondaryBackground,
    builder: (sheetContext) {
      return EventDetailsSheet(event: event);
    },
  );
}

class EventDetailsSheet extends StatelessWidget {
  const EventDetailsSheet({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = EventTheme.accent(event.category);
    final onAccent = EventTheme.onAccent(event.category);
    final height = MediaQuery.sizeOf(context).height;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  EventHeroHeader(
                    event: event,
                    height: height * 0.22,
                    borderRadius: BorderRadius.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(event.category),
                              backgroundColor: EventTheme.chipBackground(
                                event.category,
                              ),
                              side: BorderSide.none,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Date & time',
                          value: '${event.dateLabel} · ${event.timeLabel}',
                          accent: accent,
                        ),
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: 'Venue',
                          value: '${event.venue}, ${event.city}',
                          accent: accent,
                        ),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Host',
                          value: event.host,
                          accent: accent,
                        ),
                        _InfoRow(
                          icon: Icons.sell_outlined,
                          label: 'Pricing',
                          value: event.priceLabel,
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'About',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => requireAuthThenBook(context, event),
                    child: const Text('Book a Spot'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
