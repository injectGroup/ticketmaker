import 'package:flutter/material.dart';

/// Centered product tagline pinned to the bottom of a ticket card.
class TicketBrandingFooter extends StatelessWidget {
  const TicketBrandingFooter({super.key, required this.color});

  /// Card foreground color; the tagline is drawn dimmed against it.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Text(
        'Powered by Quick Ticket',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color.withValues(alpha: 0.55),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          height: 1.2,
        ),
      ),
    );
  }
}
