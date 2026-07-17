import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/tickets/data/ticket_local_repository.dart';
import 'features/tickets/presentation/bloc/tickets_cubit.dart';

class TicketMakerApp extends StatelessWidget {
  const TicketMakerApp({super.key, this.ticketsRepository});

  /// Optional override for tests.
  final TicketLocalRepository? ticketsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TicketsCubit(ticketsRepository ?? TicketLocalRepository())
            ..loadTickets(),
      child: MaterialApp.router(
        title: 'Quick Ticket Maker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
