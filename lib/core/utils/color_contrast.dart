import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Picks readable foreground colors from background luminance.
abstract final class ColorContrast {
  /// Opaque color against which translucent gradients are blended for luminance.
  /// Matches the scaffold behind ticket stubs ([AppColors.primaryBackground]).
  static const Color blendSurface = AppColors.primaryBackground;

  /// Dark text for light backgrounds.
  static const Color onLight = AppColors.primaryText;

  /// Light text for dark backgrounds.
  static const Color onDark = Colors.white;

  /// Opaque-stop luminance below this → prefer [onDark] for ticket gradients.
  static const double darkStopLuminanceThreshold = 0.45;

  /// Returns [onLight] or [onDark] for best contrast on [background].
  ///
  /// Semi-transparent colors are alpha-blended onto [surface] first so
  /// luminance matches what the user actually sees.
  static Color onColor(Color background, {Color surface = blendSurface}) {
    final opaque = Color.alphaBlend(background, surface);
    return opaque.computeLuminance() > 0.5 ? onLight : onDark;
  }

  /// Contrasting color for a two-stop gradient (midpoint sample).
  ///
  /// If either stop is dark when fully opaque (e.g. graduation charcoal),
  /// returns [onDark] so translucent fills still get white text.
  static Color onGradient(
    Color start,
    Color end, {
    Color surface = blendSurface,
  }) {
    final opaqueStart = start.withValues(alpha: 1);
    final opaqueEnd = end.withValues(alpha: 1);
    if (opaqueStart.computeLuminance() < darkStopLuminanceThreshold ||
        opaqueEnd.computeLuminance() < darkStopLuminanceThreshold) {
      return onDark;
    }
    final mid = Color.lerp(start, end, 0.5) ?? start;
    return onColor(mid, surface: surface);
  }
}
