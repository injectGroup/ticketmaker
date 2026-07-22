import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  static const String routeName = 'discover';
  static const String routePath = '/discover';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Discover'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 56,
                color: AppColors.secondaryText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Discover events',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Browse upcoming events and ticket ideas here soon.',
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
