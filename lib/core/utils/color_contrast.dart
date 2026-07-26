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

  /// Opaque-stop luminance below this → may prefer [onDark] when alpha is high.
  static const double darkStopLuminanceThreshold = 0.45;

  /// Minimum alpha before the opaque-dark → white rule applies.
  /// Low-alpha brand washes (e.g. `0x35…`) stay judged by blended luminance.
  static const double minAlphaForOpaqueDarkRule = 0.30;

  /// Returns [onLight] or [onDark] for best contrast on [background].
  ///
  /// Semi-transparent colors are alpha-blended onto [surface] first so
  /// luminance matches what the user actually sees.
  static Color onColor(Color background, {Color surface = blendSurface}) {
    final opaque = Color.alphaBlend(background, surface);
    return opaque.computeLuminance() > 0.5 ? onLight : onDark;
  }

  /// QR pad behind modules/eyes so patterns stay scanner-legible.
  /// Light modules (e.g. white) sit on dark plum; dark modules on white.
  static Color qrPadForPattern(Color dataModuleColor) {
    return dataModuleColor.computeLuminance() > 0.5
        ? AppColors.brandDarkPlum
        : Colors.white;
  }

  /// Contrasting color for a two-stop gradient.
  ///
  /// Prefers luminance of alpha-blended stops (what shows on [surface]).
  /// Only forces [onDark] when a stop is both substantially opaque and dark
  /// when fully opaque (e.g. graduation charcoal at ~`0x55` alpha).
  static Color onGradient(
    Color start,
    Color end, {
    Color surface = blendSurface,
  }) {
    if (_isSubstantialDarkFill(start) || _isSubstantialDarkFill(end)) {
      return onDark;
    }

    final mid = Color.lerp(start, end, 0.5) ?? start;
    final samples = <Color>[
      Color.alphaBlend(start, surface),
      Color.alphaBlend(mid, surface),
      Color.alphaBlend(end, surface),
    ];
    // Darkest blended sample → worst-case readability across the gradient.
    var darkest = samples.first;
    var darkestLum = darkest.computeLuminance();
    for (final sample in samples.skip(1)) {
      final lum = sample.computeLuminance();
      if (lum < darkestLum) {
        darkest = sample;
        darkestLum = lum;
      }
    }
    return darkestLum > 0.5 ? onLight : onDark;
  }

  static bool _isSubstantialDarkFill(Color color) {
    if (color.a < minAlphaForOpaqueDarkRule) return false;
    return color.withValues(alpha: 1).computeLuminance() <
        darkStopLuminanceThreshold;
  }
}
