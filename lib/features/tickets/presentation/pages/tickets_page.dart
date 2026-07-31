import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../bloc/tickets_cubit.dart';
import '../widgets/saved_ticket_card.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  static const String routeName = 'tickets';
  static const String routePath = '/tickets';

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _enterSelection([String? initialId]) {
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      if (initialId != null) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Ticket> tickets) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(tickets.map((t) => t.id));
    });
  }

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
                if (mounted) _exitSelection();
              },
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final cubit = context.read<TicketsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(count == 1 ? 'Delete ticket?' : 'Delete $count tickets?'),
          content: Text(
            count == 1
                ? 'This permanently removes the selected ticket from this device.'
                : 'This permanently removes the $count selected tickets from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-delete-selected-tickets'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final ids = Set<String>.from(_selectedIds);
    await cubit.deleteTickets(
      ids,
      message: ids.length == 1
          ? 'Ticket deleted'
          : '${ids.length} tickets deleted',
    );
    if (mounted) _exitSelection();
  }

  Future<void> _swipeDelete(Ticket ticket, int index) async {
    final cubit = context.read<TicketsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final removed = await cubit.deleteTickets(
      [ticket.id],
      deleteImages: false,
      message: null,
    );
    if (removed.isEmpty || !mounted) return;

    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Ticket deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            cubit.restoreTickets(removed, atIndex: index);
          },
        ),
      ),
    );

    final reason = await controller.closed;
    if (reason != SnackBarClosedReason.action) {
      await cubit.discardTicketImages(removed);
    }
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
        final ticket = state.tickets[index];
        final card = SavedTicketCard(
          key: Key('saved-ticket-${ticket.id}'),
          ticket: ticket,
          selecting: _selecting,
          selected: _selectedIds.contains(ticket.id),
          onLongPress: () => _enterSelection(ticket.id),
          onSelectionToggle: () => _toggleSelected(ticket.id),
        );

        if (_selecting) {
          return card;
        }

        return Dismissible(
          key: ValueKey('dismiss-${ticket.id}'),
          direction: DismissDirection.horizontal,
          background: _swipeBackground(Alignment.centerLeft),
          secondaryBackground: _swipeBackground(Alignment.centerRight),
          onDismissed: (_) => _swipeDelete(ticket, index),
          child: card,
        );
      },
    );
  }

  Widget _swipeBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  List<Widget> _appBarActions(TicketsState state) {
    if (state.tickets.isEmpty) return const [];

    final whiteStyle = TextButton.styleFrom(
      foregroundColor: Colors.white,
      overlayColor: Colors.white24,
    );

    if (_selecting) {
      final selectedCount = _selectedIds.length;
      final allSelected = selectedCount == state.tickets.length;
      return [
        TextButton(
          key: const Key('select-all-tickets'),
          onPressed: () {
            if (allSelected) {
              setState(() => _selectedIds.clear());
            } else {
              _selectAll(state.tickets);
            }
          },
          style: whiteStyle,
          child: Text(allSelected ? 'Deselect all' : 'Select all'),
        ),
        TextButton(
          key: const Key('delete-selected-tickets'),
          onPressed: selectedCount == 0
              ? null
              : () => _confirmDeleteSelected(context),
          style: whiteStyle,
          child: Text(
            selectedCount == 0
                ? 'Delete Selected'
                : 'Delete Selected ($selectedCount)',
          ),
        ),
        TextButton(
          key: const Key('cancel-ticket-selection'),
          onPressed: _exitSelection,
          style: whiteStyle,
          child: const Text('Done'),
        ),
      ];
    }

    return [
      TextButton(
        key: const Key('enter-ticket-selection'),
        onPressed: () => _enterSelection(),
        style: whiteStyle,
        child: const Text('Select'),
      ),
      TextButton.icon(
        key: const Key('clear-all-tickets'),
        onPressed: () => _confirmClearAll(context),
        style: whiteStyle,
        icon: const Icon(Icons.delete_sweep_outlined),
        label: const Text('Clear all'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketsCubit, TicketsState>(
      listenWhen: (previous, current) {
        if (previous.tickets.isNotEmpty && current.tickets.isEmpty) {
          return true;
        }
        return previous.message != current.message && current.message != null;
      },
      listener: (context, state) {
        if (state.tickets.isEmpty && _selecting) {
          _exitSelection();
        }
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
            title: Text(
              _selecting
                  ? (_selectedIds.isEmpty
                        ? 'Select tickets'
                        : '${_selectedIds.length} selected')
                  : 'My Tickets',
            ),
            automaticallyImplyLeading: false,
            actions: _appBarActions(state),
          ),
          body: _body(context, state),
        );
      },
    );
  }
}
