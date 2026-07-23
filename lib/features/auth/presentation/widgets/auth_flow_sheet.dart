import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/atoms/app_button.dart';
import '../../../account/presentation/pages/legal_document_page.dart';
import '../bloc/auth_cubit.dart';

enum AuthSheetMode { gate, signIn, signUp }

/// Shows the auth gate / sign-in / sign-up flow.
/// Returns `true` if the user ends authenticated.
Future<bool> showAuthFlow(
  BuildContext context, {
  AuthSheetMode initialMode = AuthSheetMode.gate,
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
  const AuthFlowSheet({super.key, this.initialMode = AuthSheetMode.gate});

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
  final _phone = TextEditingController();
  final _signUpPassword = TextEditingController();

  DateTime? _dateOfBirth;
  bool _acceptedTerms = false;
  bool _marketingOptIn = false;
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;

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
    _phone.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submitSignIn() async {
    final ok = await context.read<AuthCubit>().signIn(
      email: _signInEmail.text,
      password: _signInPassword.text,
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _submitSignUp() async {
    if (!_acceptedTerms || _dateOfBirth == null) return;
    final ok = await context.read<AuthCubit>().signUp(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _signUpEmail.text,
      phone: _phone.text,
      password: _signUpPassword.text,
      dateOfBirth: _dateOfBirth!,
      marketingOptIn: _marketingOptIn,
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password reset will be available soon.'),
        ),
      );
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
          initialChildSize: _mode == AuthSheetMode.signUp ? 0.92 : 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  switch (_mode) {
                    AuthSheetMode.gate => 'Sign in to book',
                    AuthSheetMode.signIn => 'Sign In',
                    AuthSheetMode.signUp => 'Create account',
                  },
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  switch (_mode) {
                    AuthSheetMode.gate =>
                      'Create an account or sign in to book a spot and generate your ticket.',
                    AuthSheetMode.signIn =>
                      'Welcome back. Enter your email and password.',
                    AuthSheetMode.signUp =>
                      'Tell us a bit about yourself to get started.',
                  },
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                if (_mode == AuthSheetMode.gate) ..._gate(theme),
                if (_mode == AuthSheetMode.signIn) ..._signIn(theme),
                if (_mode == AuthSheetMode.signUp) ..._signUp(theme),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _gate(ThemeData theme) {
    return [
      AppButton(
        label: 'Sign In',
        icon: Icons.login,
        onPressed: () => setState(() => _mode = AuthSheetMode.signIn),
      ),
      const SizedBox(height: 12),
      AppButton(
        label: 'Sign Up',
        icon: Icons.person_add_outlined,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryText,
        onPressed: () => setState(() => _mode = AuthSheetMode.signUp),
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
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _forgotPassword,
          child: const Text('Forgot Password?'),
        ),
      ),
      BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
        builder: (context, state) {
          return AppButton(
            label: state.isSubmitting ? 'Signing in…' : 'Sign In',
            onPressed: state.isSubmitting ? null : _submitSignIn,
          );
        },
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Sign Up',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _mode = AuthSheetMode.signUp),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _signUp(ThemeData theme) {
    final canSubmit =
        _acceptedTerms &&
        _dateOfBirth != null &&
        _firstName.text.trim().isNotEmpty &&
        _lastName.text.trim().isNotEmpty &&
        _signUpEmail.text.trim().isNotEmpty &&
        _phone.text.trim().isNotEmpty &&
        _signUpPassword.text.trim().length >= 6;

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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Mobile Phone Number',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
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
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _dateOfBirth == null
              ? 'Date of Birth'
              : 'DOB: ${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.calendar_today_outlined),
        onTap: _pickDob,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.dividerColor),
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
                text: 'Terms of Service',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push(LegalDocumentPage.termsPath),
              ),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push(LegalDocumentPage.privacyPath),
              ),
            ],
          ),
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _marketingOptIn,
        onChanged: (v) => setState(() => _marketingOptIn = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          'Receive newsletters and early-bird discount codes',
          style: theme.textTheme.bodyMedium,
        ),
      ),
      const SizedBox(height: 8),
      BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
        builder: (context, state) {
          return AppButton(
            label: state.isSubmitting ? 'Creating…' : 'Sign Up',
            onPressed: (!canSubmit || state.isSubmitting) ? null : _submitSignUp,
          );
        },
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Sign In',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _mode = AuthSheetMode.signIn),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}
