import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_flow_sheet.dart';

/// Ensures the guest is signed in before Share / PDF / download runs.
///
/// Uses [AuthCubit] (backed by Firebase Auth `currentUser` in production).
/// Guests see a themed gate dialog; authenticated users pass through.
Future<bool> ensureAuthenticatedForShare(BuildContext context) async {
  final auth = context.read<AuthCubit>();
  if (auth.state.status == AuthStatus.unknown) {
    await auth.restoreSession();
    if (!context.mounted) return false;
  }

  if (auth.state.isAuthenticated) {
    return true;
  }

  final wantsSignIn = await showShareAuthGate(context);
  if (!context.mounted) return false;
  if (wantsSignIn != true) {
    return false;
  }

  return showAuthFlow(
    context,
    subtitle: 'Sign in or create an account to share your tickets.',
  );
}

/// Share-specific prompt: Sign In / Sign Up, or Cancel.
///
/// Returns `true` when the guest chooses to continue to the auth flow.
Future<bool?> showShareAuthGate(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        key: const Key('share-auth-gate-sheet'),
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign In or Create an Account to Share Tickets'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Sharing tickets requires an account so your guest links stay '
              'tied to you.',
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ),
          SimpleDialogOption(
            key: const Key('share-auth-gate-sign-in'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.login, color: AppColors.primary),
              title: Text('Sign In / Sign Up'),
            ),
          ),
          SimpleDialogOption(
            key: const Key('share-auth-gate-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.close, color: AppColors.secondaryText),
              title: Text('Cancel'),
            ),
          ),
        ],
      );
    },
  );
}
