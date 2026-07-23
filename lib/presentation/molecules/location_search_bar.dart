import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Search field paired with a current-location indicator / switcher control.
class LocationSearchBar extends StatelessWidget {
  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.locationLabel,
    required this.onQueryChanged,
    required this.onLocationTap,
    this.nearYou = false,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final String locationLabel;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onLocationTap;
  final bool nearYou;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              nearYou ? Icons.my_location : Icons.location_city_outlined,
              size: 18,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nearYou ? 'Near you · $locationLabel' : 'Showing · $locationLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(20),
              child: Chip(
                avatar: const Icon(Icons.place, size: 16),
                label: Text(locationLabel),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.secondaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                    onQueryChanged('');
                  },
                  icon: const Icon(Icons.clear),
                );
              },
            ),
          ),
          onChanged: onQueryChanged,
        ),
      ],
    );
  }
}
