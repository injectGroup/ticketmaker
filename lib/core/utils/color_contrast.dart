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

  /// The field a QR code sits on, on screen and on paper alike.
  ///
  /// Readers look for dark modules on a light field, so a code cannot be
  /// inverted onto a dark pad however well that suits the ticket.
  static const Color qrField = Colors.white;

  /// Darkest a module may be while still reading as ink on [qrField]. Set at
  /// a ~3.5:1 contrast ratio, below which readers start to miss the code
  /// entirely.
  static const double maxQrInkLuminance = 0.3;

  /// [pattern] if it is dark enough to scan, otherwise [onLight].
  ///
  /// Keeps the guest's colour whenever it survives being scanned and swaps in
  /// ink when it would not, which matters most for the pale palettes: white
  /// modules on a white field are simply not there.
  static Color qrInk(Color pattern) {
    final opaque = Color.alphaBlend(pattern, qrField);
    return opaque.computeLuminance() <= maxQrInkLuminance ? opaque : onLight;
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
