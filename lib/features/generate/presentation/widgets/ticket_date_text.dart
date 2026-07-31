import 'package:flutter/material.dart';

import '../bloc/generate_cubit.dart';

/// Renders the longest date label that fits the available width.
///
/// Tries [GenerateCubit.formatFullDateLabel] first, then
/// [GenerateCubit.formatCompactDateLabel]. Keeps [TextOverflow.ellipsis] as a
/// last-resort safety net when even the compact form is too wide.
class TicketDateText extends StatelessWidget {
  const TicketDateText({
    super.key,
    required this.eventAt,
    this.style,
  });

  final DateTime eventAt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveStyle =
            DefaultTextStyle.of(context).style.merge(style);
        final textScaler = MediaQuery.textScalerOf(context);
        final candidates = <String>[
          GenerateCubit.formatFullDateLabel(eventAt),
          GenerateCubit.formatCompactDateLabel(eventAt),
        ];

        var chosen = candidates.last;
        for (final candidate in candidates) {
          if (_fits(
            candidate,
            style: effectiveStyle,
            textScaler: textScaler,
            maxWidth: constraints.maxWidth,
          )) {
            chosen = candidate;
            break;
          }
        }

        return Text(
          chosen,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
    );
  }

  static bool _fits(
    String text, {
    required TextStyle style,
    required TextScaler textScaler,
    required double maxWidth,
  }) {
    if (!maxWidth.isFinite) return true;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: textScaler,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    final width = painter.width;
    painter.dispose();
    return width <= maxWidth;
  }
}
