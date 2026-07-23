import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/tickets_cubit.dart';
import '../widgets/saved_ticket_card.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const String routeName = 'tickets';
  static const String routePath = '/tickets';

  Future<void> _confirmClearAll(BuildContext context) async {
    final cubit = context.read<TicketsCubit>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all tickets?'),
          content: const Text(
            'This permanently removes all saved tickets from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-clear-all-tickets'),
              onPressed: () async {
                await cubit.clearAllTickets();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, TicketsState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.tickets.isEmpty) {
      return Center(
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
                'No saved tickets yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Customize a ticket on Generate, then tap Save Ticket.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return SavedTicketCard(ticket: state.tickets[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketsCubit, TicketsState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<TicketsCubit>().clearMessage();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            title: const Text('My Tickets'),
            automaticallyImplyLeading: false,
            actions: [
              if (state.tickets.isNotEmpty)
                TextButton(
                  key: const Key('clear-all-tickets'),
                  onPressed: () => _confirmClearAll(context),
                  child: const Text('Clear all'),
                ),
            ],
          ),
          body: _body(context, state),
        );
      },
    );
  }
}
