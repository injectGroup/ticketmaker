import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/interactive_seating_cubit.dart';

class SeatingSummaryDrawer extends StatelessWidget {
  const SeatingSummaryDrawer({
    super.key,
    required this.state,
    required this.onCheckout,
  });

  final InteractiveSeatingState state;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seatList = state.selectedShortCodes.isEmpty
        ? 'No seats selected'
        : state.selectedShortCodes.join(', ');

    return Material(
      elevation: 8,
      color: AppColors.secondaryBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.selectedCount} seat'
                          '${state.selectedCount == 1 ? '' : 's'} selected',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seatList,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    state.totalPriceLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.canCheckout ? onCheckout : null,
                child: const Text('Proceed to Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
