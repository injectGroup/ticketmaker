import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const String routeName = 'account';
  static const String routePath = '/account';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outlined,
                size: 56,
                color: AppColors.secondaryText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Profile and settings will live here soon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
