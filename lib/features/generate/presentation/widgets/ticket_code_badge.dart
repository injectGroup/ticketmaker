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
    this.showInfo = false,
  });

  final String code;
  final Color? foreground;
  final Color? background;

  /// Places an info icon inside the pill beside the code.
  final bool showInfo;

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
    final bg = background ?? const Color(0xFFF1F5F9);

    return Material(
      color: bg,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.22)),
          ),
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
              Icon(
                Icons.copy_rounded,
                size: 15,
                color: fg.withValues(alpha: 0.75),
              ),
              if (showInfo) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: fg.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
