import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'ticket_section_label.dart';

/// Compact, tappable ticket code chip that copies to the clipboard.
class TicketCodeBadge extends StatelessWidget {
  const TicketCodeBadge({
    super.key,
    required this.code,
    this.foreground,
    this.background,
    this.showInfo = false,
    this.showIdLabel = false,
  });

  final String code;
  final Color? foreground;
  final Color? background;

  /// Places an info icon inside the pill beside the code.
  final bool showInfo;

  /// Adds a dimmed `TICKET ID` caption directly above the pill.
  final bool showIdLabel;

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

    final pill = Material(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                code,
                style: GoogleFonts.spaceMono(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.6,
                  height: 1.2,
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

    if (!showIdLabel) return pill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TicketSectionLabel(text: 'Ticket ID', color: fg),
        const SizedBox(height: 6),
        pill,
      ],
    );
  }
}
