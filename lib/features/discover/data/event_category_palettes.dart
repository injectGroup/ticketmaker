import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Default QR + background colors for a Discover / ticket event category.
class EventPalette extends Equatable {
  const EventPalette({
    required this.eyeColor,
    required this.dataModuleColor,
    required this.backgroundStart,
    required this.backgroundEnd,
  });

  final Color eyeColor;
  final Color dataModuleColor;
  final Color backgroundStart;
  final Color backgroundEnd;

  @override
  List<Object?> get props => [
    eyeColor,
    dataModuleColor,
    backgroundStart,
    backgroundEnd,
  ];
}

/// Canonical category labels and their Generate-ready color defaults.
abstract final class EventCategoryPalettes {
  static const String music = 'Music';
  static const String tech = 'Tech';
  static const String sports = 'Sports';
  static const String comedy = 'Comedy';
  static const String wedding = 'Wedding';
  static const String birthday = 'Birthday';
  static const String anniversary = 'Anniversary';
  static const String graduation = 'Graduation';
  static const String generalParty = 'General party';
  static const String generalEvent = 'General event';

  static const List<String> all = [
    music,
    tech,
    sports,
    comedy,
    wedding,
    birthday,
    anniversary,
    graduation,
    generalParty,
    generalEvent,
  ];

  /// Translucent bg alpha matching existing ticket gradients (~0x55).
  static const int _bgAlpha = 0x55;

  static Color _bg(int rgb) => Color((_bgAlpha << 24) | (rgb & 0x00FFFFFF));

  static EventPalette forCategory(String category) {
    switch (category) {
      case music:
        // Dark + accent QR, warm bg
        return EventPalette(
          eyeColor: const Color(0xFF1A1A2E),
          dataModuleColor: const Color(0xFFE94560),
          backgroundStart: _bg(0xFF5963),
          backgroundEnd: _bg(0xF9CF58),
        );
      case tech:
        // Primary/secondary QR, cool bg
        return const EventPalette(
          eyeColor: AppColors.primary,
          dataModuleColor: AppColors.secondary,
          backgroundStart: Color(0x5539D2C0),
          backgroundEnd: Color(0x554B39EF),
        );
      case sports:
        // Green/teal palette
        return EventPalette(
          eyeColor: const Color(0xFF0F3460),
          dataModuleColor: const Color(0xFF16C79A),
          backgroundStart: _bg(0x16C79A),
          backgroundEnd: _bg(0x0F3460),
        );
      case comedy:
        // Bright warm palette
        return EventPalette(
          eyeColor: const Color(0xFFEE8B60),
          dataModuleColor: const Color(0xFFF9CF58),
          backgroundStart: _bg(0xEE8B60),
          backgroundEnd: _bg(0xF9CF58),
        );
      case wedding:
        // Ivory, blush pink & gold
        return EventPalette(
          eyeColor: const Color(0xFFE8B4B8),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0xFFF8F0),
          backgroundEnd: _bg(0xF5D0D4),
        );
      case birthday:
        // Multi-color rainbow accents
        return EventPalette(
          eyeColor: const Color(0xFFFF6B6B),
          dataModuleColor: const Color(0xFF4ECDC4),
          backgroundStart: _bg(0xFF6B6B),
          backgroundEnd: _bg(0x4ECDC4),
        );
      case anniversary:
        // Gold & white
        return EventPalette(
          eyeColor: const Color(0xFFC9A227),
          dataModuleColor: const Color(0xFFFFFFFF),
          backgroundStart: _bg(0xC9A227),
          backgroundEnd: _bg(0xFFFFFF),
        );
      case graduation:
        // Black, silver & gold
        return EventPalette(
          eyeColor: const Color(0xFF14181B),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0x14181B),
          backgroundEnd: _bg(0xC0C0C0),
        );
      case generalParty:
        // White, silver & primary accents
        return EventPalette(
          eyeColor: const Color(0xFFFFFFFF),
          dataModuleColor: AppColors.primary,
          backgroundStart: _bg(0xFFFFFF),
          backgroundEnd: _bg(0xC0C0C0),
        );
      case generalEvent:
      default:
        // White/cream & metallic gold
        return EventPalette(
          eyeColor: const Color(0xFFFFF8E7),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0xFFF8E7),
          backgroundEnd: _bg(0xC9A227),
        );
    }
  }
}
