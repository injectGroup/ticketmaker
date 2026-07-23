import 'package:flutter/material.dart';

/// Material 3 chip-style badge for tags and labels.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = backgroundColor ?? scheme.primary.withValues(alpha: 0.12);
    final fg = foregroundColor ?? scheme.primary;

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: bg,
      side: BorderSide.none,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
    );
  }
}
