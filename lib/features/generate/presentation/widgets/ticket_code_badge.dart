import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Compact, tappable ticket code chip that copies to the clipboard.
class TicketCodeBadge extends StatelessWidget {
  const TicketCodeBadge({
    super.key,
    required this.code,
    this.foreground,
    this.background,
  });

  final String code;
  final Color? foreground;
  final Color? background;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.primaryText;
    final bg = background ?? AppColors.primary.withValues(alpha: 0.14);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.copy_rounded, size: 16, color: fg.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}
