import 'package:flutter/material.dart';

/// Small dimmed uppercase caption used above ticket card sections
/// (for example `TICKET ID` and `ABOUT THIS EVENT`).
class TicketSectionLabel extends StatelessWidget {
  const TicketSectionLabel({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;

  /// Card foreground color; the label is drawn dimmed against it.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color.withValues(alpha: 0.6),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }
}
