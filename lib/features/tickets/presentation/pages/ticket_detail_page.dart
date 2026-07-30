import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_share_helper.dart';
import '../bloc/tickets_cubit.dart';
import '../widgets/saved_ticket_view.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  static const String routeName = 'ticketDetail';

  final String ticketId;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final GlobalKey _ticketBoundaryKey = GlobalKey();

  Future<void> _share(BuildContext buttonContext, Ticket ticket) async {
    try {
      final bytes =
          context.read<TicketsCubit>().state.imageBytesFor(ticket.id);
      final origin = TicketShareHelper.shareOriginFrom(buttonContext);

      // If the ticket card isn't painted / capture fails, never crash —
      // fall back to link/text share (clipboard on web, share sheet native).
      final png = await TicketShareHelper.capturePngBytes(_ticketBoundaryKey);
      if (!mounted) return;

      if (png == null || png.isEmpty) {
        await TicketShareHelper.share(
          context,
          ticket,
          sharePositionOrigin: origin,
          eventImageBytes: bytes,
          attachTicketImage: false,
        );
        return;
      }

      await TicketShareHelper.share(
        context,
        ticket,
        boundaryKey: _ticketBoundaryKey,
        sharePositionOrigin: origin,
        eventImageBytes: bytes,
      );
    } catch (e, st) {
      debugPrint('TicketDetailPage share failed: $e\n$st');
      if (!mounted) return;
      // Last-resort link share so the Share button still completes.
      try {
        final origin = buttonContext.mounted
            ? TicketShareHelper.shareOriginFrom(buttonContext)
            : null;
        await TicketShareHelper.share(
          context,
          ticket,
          sharePositionOrigin: origin,
          attachTicketImage: false,
        );
      } catch (fallbackError, fallbackSt) {
        debugPrint('TicketDetailPage link fallback failed: $fallbackError\n$fallbackSt');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not share ticket. Try again.'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        Ticket? ticket;
        for (final entry in state.tickets) {
          if (entry.id == widget.ticketId) {
            ticket = entry;
            break;
          }
        }
        final imageBytes =
            ticket == null ? null : state.imageBytesFor(ticket.id);

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            title: Text(ticket?.title ?? 'Ticket'),
            actions: [
              if (ticket != null) ...[
                IconButton(
                  tooltip: 'Publish for door scan',
                  onPressed: () async {
                    final ok = await context
                        .read<TicketsCubit>()
                        .republishForDoorScan(ticket!.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Door scan ready: ${ticket.code}'
                                : 'Could not publish door scan link.',
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.qr_code_2_outlined),
                ),
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      tooltip: 'Share Ticket',
                      onPressed: () => _share(buttonContext, ticket!),
                      icon: const Icon(Icons.share_outlined),
                    );
                  },
                ),
              ],
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
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _ticketBoundaryKey,
                        child: SavedTicketView(
                          ticket: ticket,
                          imageBytes: imageBytes,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Text(
                          'Door scan: ${ticket.qrData}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
