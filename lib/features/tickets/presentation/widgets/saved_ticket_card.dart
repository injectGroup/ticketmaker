import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';

/// List card for a persisted ticket, with a native share action.
class SavedTicketCard extends StatelessWidget {
  const SavedTicketCard({super.key, required this.ticket});

  final Ticket ticket;

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    Rect origin;
    if (box != null &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final size = MediaQuery.sizeOf(buttonContext);
      origin = Rect.fromLTWH(size.width / 2 - 1, size.height / 2 - 1, 2, 2);
    }

    // share_plus requires a non-zero sharePositionOrigin on iOS for the sheet
    // to present reliably from the tapped control.
    // ignore: deprecated_member_use
    await Share.share(
      ticket.toShareText(),
      subject: ticket.title,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
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
    );
  }
}
