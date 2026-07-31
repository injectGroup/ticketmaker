import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../generate/presentation/bloc/generate_cubit.dart';
import '../../tickets/presentation/bloc/tickets_cubit.dart';
import '../../tickets/presentation/pages/tickets_page.dart';
import '../../tickets/presentation/widgets/saved_ticket_view.dart';
import '../domain/pending_auth_action.dart';
import 'bloc/auth_cubit.dart';
import 'widgets/auth_flow_sheet.dart';

/// Ensures authentication, then runs [action].
///
/// Prefer [saveTicketAsGuest] for Save Ticket — guests may persist locally
/// without signing in.
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

/// Persists the current Generate ticket locally without Sign In / Sign Up.
///
/// Stores the Generate **event photo** (`GenerateCubit.imageBytes`) for the
/// ticket photo slot. Full-ticket share JPEGs are composed at share time from
/// [SavedTicketView] — never by re-sharing the event photo alone.
Future<void> saveTicketAsGuest(BuildContext context) {
  return _executePending(
    context,
    const PendingSaveTicketAction(),
  );
}

@Deprecated('Use saveTicketAsGuest — Save Ticket no longer requires auth.')
Future<void> requireAuthThenSaveTicket(BuildContext context) {
  return saveTicketAsGuest(context);
}

Future<void> _executePending(
  BuildContext context,
  PendingAuthAction action,
) async {
  switch (action) {
    case PendingSaveTicketAction():
      final generateCubit = context.read<GenerateCubit>();
      try {
        // Mint a unique guest link before persist — Share Ticket uses this URL.
        generateCubit.ensureTicketPayload();
        await context
            .read<TicketsCubit>()
            .saveTicket(
              generateCubit.state.ticket,
              // Event gallery photo only (not a full-ticket snapshot).
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
        // Never surface LateInitializationError from optional image work.
        if (e.toString().contains('LateInitialization')) {
          // Local metadata may already be saved; still surface a soft failure.
        }
        rethrow;
      }
  }
}
