import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_share_helper.dart';
import '../pages/tickets_page.dart';

/// List card for a persisted ticket, with a native share action.
class SavedTicketCard extends StatelessWidget {
  const SavedTicketCard({super.key, required this.ticket});

  final Ticket ticket;

  Future<void> _share(BuildContext buttonContext) async {
    await TicketShareHelper.share(
      buttonContext,
      ticket,
      sharePositionOrigin: TicketShareHelper.shareOriginFrom(buttonContext),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '${TicketsPage.routePath}/${Uri.encodeComponent(ticket.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(ticket.subtitle, style: theme.textTheme.bodySmall),
                    if (ticket.venue.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(ticket.venue, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${ticket.dateLabel} · ${ticket.timeLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (buttonContext) {
                  return IconButton(
                    tooltip: 'Share',
                    onPressed: () => _share(buttonContext),
                    icon: const Icon(Icons.share_outlined),
                    color: AppColors.primary,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
