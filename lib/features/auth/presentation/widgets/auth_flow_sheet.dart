import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../account/presentation/pages/legal_document_page.dart';
import '../bloc/auth_cubit.dart';

enum AuthSheetMode { signIn, signUp }

/// Shows the sign-in / sign-up flow.
/// Returns `true` if the user ends authenticated.
Future<bool> showAuthFlow(
  BuildContext context, {
  AuthSheetMode initialMode = AuthSheetMode.signIn,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.secondaryBackground,
    builder: (sheetContext) {
      return AuthFlowSheet(initialMode: initialMode);
    },
  );
  return result ?? false;
}

class AuthFlowSheet extends StatefulWidget {
  const AuthFlowSheet({super.key, this.initialMode = AuthSheetMode.signIn});

  final AuthSheetMode initialMode;

  @override
  State<AuthFlowSheet> createState() => _AuthFlowSheetState();
}

class _AuthFlowSheetState extends State<AuthFlowSheet> {
  late AuthSheetMode _mode;

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _acceptedTerms = false;
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;

  bool get _showAppleButton =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _signInEmail.dispose();
    _signInPassword.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _signInEmail.text.trim();
    final password = _signInPassword.text.trim();
    debugPrint(
      '--- SIGN IN BUTTON TAPPED --- emailLen=${email.length} '
      'passwordEmpty=${password.isEmpty}',
    );
    context.read<AuthCubit>().clearMessage();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final ok = await context.read<AuthCubit>().signIn(
          email: email,
          password: password,
        );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _submitSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final email = _signUpEmail.text.trim();
    final password = _signUpPassword.text.trim();
    final confirm = _confirmPassword.text.trim();
    debugPrint(
      '--- SIGN UP BUTTON TAPPED --- emailLen=${email.length} '
      'passwordEmpty=${password.isEmpty}',
    );
    context.read<AuthCubit>().clearMessage();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please accept the Terms & Conditions.')),
        );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
      return;
    }

    final ok = await context.read<AuthCubit>().signUp(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _socialGoogle() async {
    context.read<AuthCubit>().clearMessage();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final ok = await context.read<AuthCubit>().signInWithGoogle();
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _socialApple() async {
    context.read<AuthCubit>().clearMessage();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final ok = await context.read<AuthCubit>().signInWithApple();
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  void _setMode(AuthSheetMode mode) {
    if (_mode == mode) return;
    context.read<AuthCubit>().clearMessage();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.message != c.message && c.message != null,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<AuthCubit>().clearMessage();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: _mode == AuthSheetMode.signUp ? 0.92 : 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or create an account to save your ticket.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<AuthSheetMode>(
                  segments: const [
                    ButtonSegment(
                      value: AuthSheetMode.signIn,
                      label: Text('Sign In'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: AuthSheetMode.signUp,
                      label: Text('Sign Up'),
                      icon: Icon(Icons.person_add_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (next) {
                    _setMode(next.first);
                  },
                ),
                const SizedBox(height: 20),
                if (_mode == AuthSheetMode.signIn) ..._signIn(theme),
                if (_mode == AuthSheetMode.signUp) ..._signUp(theme),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _socialButtons({required bool requireTerms}) {
    final disabledByTerms = requireTerms && !_acceptedTerms;
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Or continue with',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 12),
      BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
        builder: (context, state) {
          final busy = state.isSubmitting;
          return Column(
            children: [
              OutlinedButton.icon(
                onPressed: (busy || disabledByTerms) ? null : _socialGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.primaryText,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              if (_showAppleButton) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (busy || disabledByTerms) ? null : _socialApple,
                  icon: const Icon(Icons.apple, size: 22),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _signIn(ThemeData theme) {
    return [
      TextField(
        controller: _signInEmail,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(
          labelText: 'Email Address',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _signInPassword,
        obscureText: _obscureSignIn,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: 'Password',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscureSignIn = !_obscureSignIn),
            icon: Icon(
              _obscureSignIn ? Icons.visibility_outlined : Icons.visibility_off,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
        builder: (context, state) {
          return AppButton(
            label: state.isSubmitting ? 'Signing in…' : 'Sign In',
            onPressed: state.isSubmitting ? null : _submitSignIn,
          );
        },
      ),
      ..._socialButtons(requireTerms: false),
    ];
  }

  List<Widget> _signUp(ThemeData theme) {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _signUpEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _signUpPassword,
        obscureText: _obscureSignUp,
        decoration: InputDecoration(
          labelText: 'Password',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscureSignUp = !_obscureSignUp),
            icon: Icon(
              _obscureSignUp ? Icons.visibility_outlined : Icons.visibility_off,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmPassword,
        obscureText: _obscureConfirm,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _acceptedTerms,
        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text.rich(
          TextSpan(
            text: 'I agree to the ',
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: 'Terms & Conditions',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push(LegalDocumentPage.termsPath),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
        builder: (context, state) {
          return AppButton(
            label: state.isSubmitting ? 'Creating…' : 'Create Account',
            onPressed: state.isSubmitting ? null : _submitSignUp,
          );
        },
      ),
      ..._socialButtons(requireTerms: true),
    ];
  }
}
