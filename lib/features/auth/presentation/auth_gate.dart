import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../account/presentation/pages/account_page.dart';
import '../../discover/domain/entities/event.dart';
import '../../generate/presentation/bloc/generate_cubit.dart';
import '../../seating/presentation/pages/interactive_seating_page.dart';
import '../../tickets/presentation/bloc/tickets_cubit.dart';
import '../../tickets/presentation/pages/tickets_page.dart';
import '../domain/pending_auth_action.dart';
import 'bloc/auth_cubit.dart';
import 'widgets/auth_flow_sheet.dart';

/// Ensures authentication, then runs [action] (book or save).
Future<void> requireAuthThen(
  BuildContext context,
  PendingAuthAction action,
) async {
  final auth = context.read<AuthCubit>();
  if (auth.state.status == AuthStatus.unknown) {
    await auth.restoreSession();
    if (!context.mounted) return;
  }
  final justSignedUpBefore = auth.state.justSignedUp;

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
  final cameFromSignUp = auth.state.justSignedUp || justSignedUpBefore;
  await _executePending(context, pending);

  if (!context.mounted) return;
  if (cameFromSignUp) {
    auth.clearJustSignedUp();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Complete your profile for better recommendations.',
          ),
          action: SnackBarAction(
            label: 'Profile',
            onPressed: () =>
                context.go('${AccountPage.routePath}?personalize=1'),
          ),
        ),
      );
  }
}

Future<void> requireAuthThenBook(BuildContext context, Event event) {
  return requireAuthThen(context, PendingBookAction(event));
}

Future<void> requireAuthThenSaveTicket(BuildContext context) {
  return requireAuthThen(context, const PendingSaveTicketAction());
}

Future<void> _executePending(
  BuildContext context,
  PendingAuthAction action,
) async {
  switch (action) {
    case PendingBookAction(:final event):
      final navigator = Navigator.of(context, rootNavigator: false);
      if (navigator.canPop()) {
        navigator.pop();
      }
      context.go(InteractiveSeatingPage.routePath, extra: event);
    case PendingSaveTicketAction():
      final generateCubit = context.read<GenerateCubit>();
      try {
        await context
            .read<TicketsCubit>()
            .saveTicket(generateCubit.state.ticket)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                  'Save timed out after 10 seconds',
                );
              },
            );
        // Keep the user's current Generate edits; show the saved list.
        if (!context.mounted) return;
        context.go(TicketsPage.routePath);
      } catch (e, st) {
        debugPrint('Failed to save ticket: $e\n$st');
        rethrow;
      }
  }
}
