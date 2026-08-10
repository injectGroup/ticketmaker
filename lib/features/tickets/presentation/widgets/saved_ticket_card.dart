import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_share_helper.dart';
import '../bloc/tickets_cubit.dart';
import '../pages/tickets_page.dart';
import 'share_auth_gate.dart';

/// List card for a persisted ticket, with a native share action.
class SavedTicketCard extends StatelessWidget {
  const SavedTicketCard({
    super.key,
    required this.ticket,
    this.selecting = false,
    this.selected = false,
    this.onLongPress,
    this.onSelectionToggle,
  });

  final Ticket ticket;
  final bool selecting;
  final bool selected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  Future<void> _share(BuildContext buttonContext) async {
    try {
      final allowed = await ensureAuthenticatedForShare(buttonContext);
      if (!buttonContext.mounted || !allowed) return;

      // List rows have no on-screen ticket RepaintBoundary. Share still
      // composes SavedTicketView off-screen / via modal from [ticket] data
      // (and optional event photo bytes) for Download on web.
      final eventBytes =
          buttonContext.read<TicketsCubit>().state.imageBytesFor(ticket.id);
      await TicketShareHelper.share(
        buttonContext,
        ticket,
        sharePositionOrigin: TicketShareHelper.shareOriginFrom(buttonContext),
        eventImageBytes: eventBytes,
        // Allow compose for web Download; native list still falls back to
        // link/text when image capture is unavailable.
        attachTicketImage: true,
      );
    } catch (e, st) {
      debugPrint('SavedTicketCard share failed: $e\n$st');
      if (!buttonContext.mounted) return;
      ScaffoldMessenger.of(buttonContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not share ticket. Try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selecting
            ? onSelectionToggle
            : () => context.push(
                '${TicketsPage.routePath}/${Uri.encodeComponent(ticket.id)}',
              ),
        onLongPress: selecting ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selecting) ...[
                Checkbox(
                  value: selected,
                  onChanged: (_) => onSelectionToggle?.call(),
                ),
                const SizedBox(width: 4),
              ],
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
              if (!selecting)
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      tooltip: 'Share Ticket',
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
