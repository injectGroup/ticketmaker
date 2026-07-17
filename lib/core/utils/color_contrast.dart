import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Picks readable foreground colors from background luminance.
abstract final class ColorContrast {
  /// Opaque color against which translucent gradients are blended for luminance.
  static const Color blendSurface = AppColors.secondaryBackground;

  /// Dark text for light backgrounds.
  static const Color onLight = AppColors.primaryText;

  /// Light text for dark backgrounds.
  static const Color onDark = Colors.white;

  /// Returns [onLight] or [onDark] for best contrast on [background].
  ///
  /// Semi-transparent colors are alpha-blended onto [surface] first so
  /// luminance matches what the user actually sees.
  static Color onColor(
    Color background, {
    Color surface = blendSurface,
  }) {
    final opaque = Color.alphaBlend(background, surface);
    return opaque.computeLuminance() > 0.5 ? onLight : onDark;
  }

  /// Contrasting color for a two-stop gradient (midpoint sample).
  static Color onGradient(
    Color start,
    Color end, {
    Color surface = blendSurface,
  }) {
    final mid = Color.lerp(start, end, 0.5) ?? start;
    return onColor(mid, surface: surface);
  }
}
