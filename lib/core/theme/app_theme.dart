import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application color tokens for Quick Ticket Maker.
abstract final class AppColors {
  /// Brand rose — primary actions, QR accents, active states.
  static const Color primary = Color(0xFFE0405B);

  /// Sleek dark plum — default ticket card fill.
  static const Color brandDarkPlum = Color(0xFF1A1A2E);

  /// Soft blush alternate ticket fill.
  static const Color brandBlush = Color(0xFFF4EEFF);

  /// Crisp off-white for editable pill inputs on the ticket card.
  static const Color pillBackground = Color(0xFFF8FAFC);

  /// High-contrast ink for pill input text.
  static const Color pillText = Color(0xFF0F172A);

  /// Dark neutral for floating controls (e.g. Bg color FAB).
  static const Color fabNeutral = Color(0xFF1E293B);

  static const Color secondary = Color(0xFF39D2C0);
  static const Color error = Color(0xFFFF5963);
  static const Color warning = Color(0xFFF9CF58);
  static const Color primaryBackground = Color(0xFFF8F9FA);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF14181B);
  static const Color secondaryText = Color(0xFF57636C);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.secondaryBackground,
      ),
      scaffoldBackgroundColor: AppColors.primaryBackground,
    );

    return base.copyWith(
      textTheme: GoogleFonts.readexProTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
        titleMedium: GoogleFonts.readexPro(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        titleSmall: GoogleFonts.readexPro(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
        bodyMedium: GoogleFonts.readexPro(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryText,
        ),
        bodySmall: GoogleFonts.readexPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}
