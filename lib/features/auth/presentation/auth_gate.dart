import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../generate/presentation/bloc/generate_cubit.dart';
import '../../tickets/presentation/bloc/tickets_cubit.dart';
import '../../tickets/presentation/pages/tickets_page.dart';
import '../domain/pending_auth_action.dart';
import 'bloc/auth_cubit.dart';
import 'widgets/auth_flow_sheet.dart';

/// Ensures authentication, then runs [action] (save ticket).
Future<void> requireAuthThen(
  BuildContext context,
  PendingAuthAction action,
) async {
  final auth = context.read<AuthCubit>();
  if (auth.state.status == AuthStatus.unknown) {
    await auth.restoreSession();
    if (!context.mounted) return;
  }

  if (!auth.state.isAuthenticated) {
    auth.setPendingAction(action);
    final signedIn = await showAuthFlow(context);
    if (!context.mounted) return;
    if (!signedIn || !auth.state.isAuthenticated) {
      auth.setPendingAction(null);
      return;
    }
  }

  final pending = auth.takePendingAction() ?? action;
  if (auth.state.justSignedUp) {
    auth.clearJustSignedUp();
  }
  await _executePending(context, pending);
}

Future<void> requireAuthThenSaveTicket(BuildContext context) {
  return requireAuthThen(context, const PendingSaveTicketAction());
}

Future<void> _executePending(
  BuildContext context,
  PendingAuthAction action,
) async {
  switch (action) {
    case PendingSaveTicketAction():
      final generateCubit = context.read<GenerateCubit>();
      try {
        await context
            .read<TicketsCubit>()
            .saveTicket(
              generateCubit.state.ticket,
              imageBytes: generateCubit.state.imageBytes,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                  'Save timed out after 10 seconds',
                );
              },
            );
        // Reset Generate to defaults for the next ticket, then show the list.
        generateCubit.resetToDefault();
        if (!context.mounted) return;
        context.go(TicketsPage.routePath);
      } catch (e, st) {
        debugPrint('Failed to save ticket: $e\n$st');
        rethrow;
      }
  }
}
