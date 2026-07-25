import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/generate/presentation/bloc/generate_cubit.dart';
import 'features/tickets/data/ticket_local_repository.dart';
import 'features/tickets/presentation/bloc/tickets_cubit.dart';

class TicketMakerApp extends StatelessWidget {
  const TicketMakerApp({
    super.key,
    this.ticketsRepository,
    this.authRepository,
  });

  /// Optional override for tests.
  final TicketLocalRepository? ticketsRepository;

  /// Optional override for tests.
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(repository: authRepository),
        ),
        BlocProvider(
          create: (_) =>
              TicketsCubit(ticketsRepository ?? TicketLocalRepository())
                ..loadTickets(),
        ),
        BlocProvider(create: (_) => GenerateCubit()),
      ],
      child: MaterialApp.router(
        title: 'Quick Ticket Maker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
