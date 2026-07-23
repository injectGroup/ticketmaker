import 'package:flutter/material.dart';

import '../../../generate/data/ticket_category_palettes.dart';

/// UI accents derived from Generate category palettes for Discover cards/sheets.
abstract final class EventTheme {
  static TicketCategoryPalette paletteFor(String category) =>
      TicketCategoryPalettes.forCategory(category);

  static Color accent(String category) =>
      paletteFor(category).dataModuleColor;

  static Color onAccent(String category) {
    final accent = EventTheme.accent(category);
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF14181B);
  }

  static LinearGradient headerGradient(String category) {
    final palette = paletteFor(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        palette.backgroundStart.withValues(alpha: 1),
        palette.backgroundEnd.withValues(alpha: 1),
        accent(category),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static Color chipBackground(String category) =>
      accent(category).withValues(alpha: 0.14);

  static Color softSurface(String category) =>
      accent(category).withValues(alpha: 0.08);
}
