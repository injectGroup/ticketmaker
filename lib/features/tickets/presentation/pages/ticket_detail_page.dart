import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../bloc/tickets_cubit.dart';
import '../widgets/saved_ticket_view.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  static const String routeName = 'ticketDetail';

  final String ticketId;

  Future<void> _share(BuildContext buttonContext, Ticket ticket) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final Rect sharePositionOrigin;
    if (box != null &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0) {
      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final size = MediaQuery.sizeOf(buttonContext);
      sharePositionOrigin = Rect.fromLTWH(
        size.width / 2 - 1,
        size.height / 2 - 1,
        2,
        2,
      );
    }

    // sharePositionOrigin is required on iOS/iPadOS so the popover anchors.
    // ignore: deprecated_member_use
    await Share.share(
      ticket.toShareText(),
      subject: 'My Custom Ticket Design',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        Ticket? ticket;
        for (final entry in state.tickets) {
          if (entry.id == ticketId) {
            ticket = entry;
            break;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            title: Text(ticket?.title ?? 'Ticket'),
            actions: [
              if (ticket != null)
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      tooltip: 'Share',
                      onPressed: () => _share(buttonContext, ticket!),
                      icon: const Icon(Icons.share_outlined),
                    );
                  },
                ),
            ],
          ),
          body: ticket == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 56,
                          color: AppColors.secondaryText.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ticket not found',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This ticket may have been removed.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: SavedTicketView(ticket: ticket),
                ),
        );
      },
    );
  }
}
