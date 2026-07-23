import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/pages/discover_screen.dart';
import '../../../discover/domain/entities/event.dart';
import '../../../generate/presentation/bloc/generate_cubit.dart';
import '../../../generate/presentation/pages/generate_page.dart';
import '../bloc/interactive_seating_cubit.dart';
import '../widgets/seating_grid.dart';
import '../widgets/seating_header.dart';
import '../widgets/seating_legend.dart';
import '../widgets/seating_summary_drawer.dart';
import '../widgets/stage_indicator.dart';

class InteractiveSeatingPage extends StatelessWidget {
  const InteractiveSeatingPage({super.key, required this.event});

  static const routePath = '/seating';
  static const routeName = 'seating';

  final Event event;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InteractiveSeatingCubit(event: event),
      child: const _InteractiveSeatingView(),
    );
  }
}

class _InteractiveSeatingView extends StatelessWidget {
  const _InteractiveSeatingView();

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(DiscoverScreen.routePath);
    }
  }

  void _onCheckout(BuildContext context, InteractiveSeatingState state) {
    final seatsSummary = state.selectedShortCodes.join(', ');
    context.read<GenerateCubit>().prefillFromEvent(
      state.event,
      seatSummary: seatsSummary,
    );
    context.go(GeneratePage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InteractiveSeatingCubit, InteractiveSeatingState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SeatingHeader(
                  event: state.event,
                  onBack: () => _onBack(context),
                ),
                const StageIndicator(),
                const SeatingLegend(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    child: SeatingGrid(
                      seatsByRow: state.seatsByRow,
                      onSeatTap: (id) =>
                          context.read<InteractiveSeatingCubit>().toggleSeat(id),
                    ),
                  ),
                ),
                SeatingSummaryDrawer(
                  state: state,
                  onCheckout: () => _onCheckout(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
