import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Layout-only Discover feed: scaffold, search header, scrollable list area.
class DiscoverFeedTemplate extends StatelessWidget {
  const DiscoverFeedTemplate({
    super.key,
    required this.title,
    required this.locationSearchBar,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyMessage,
    required this.eventTiles,
  });

  final String title;
  final Widget locationSearchBar;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> eventTiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: locationSearchBar,
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading && eventTiles.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        emptyMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: eventTiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => eventTiles[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
