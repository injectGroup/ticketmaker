import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  static const String termsPath = '/account/terms';
  static const String privacyPath = '/account/privacy';
  static const String termsName = 'terms';
  static const String privacyName = 'privacy';

  static const String termsBody =
      'Quick Ticket Maker Terms of Service (demo stub).\n\n'
      'By creating an account you agree to use the app for personal event '
      'ticketing and QR generation. This sample app stores account data '
      'locally on your device for demonstration only.\n\n'
      'Do not use real production passwords. Contact support for the full '
      'legal agreement when the product ships.';

  static const String privacyBody =
      'Quick Ticket Maker Privacy Policy (demo stub).\n\n'
      'We store your profile fields (name, email, phone, preferences) locally '
      'on this device. No cloud backend is used in this demo build.\n\n'
      'Optional marketing consent controls promotional messages only.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryText,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
