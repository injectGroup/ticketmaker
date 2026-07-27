import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Default QR + background colors for a ticket event category (Generate).
class TicketCategoryPalette extends Equatable {
  const TicketCategoryPalette({
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

/// Canonical category labels and Generate color defaults.
/// Personal gatherings are listed first for the V1 personal-ticket flow.
abstract final class TicketCategoryPalettes {
  static const String birthday = 'Birthday';
  static const String dinner = 'Dinner';
  static const String privateGathering = 'Private gathering';
  static const String wedding = 'Wedding';
  static const String anniversary = 'Anniversary';
  static const String graduation = 'Graduation';
  static const String generalParty = 'General party';
  static const String music = 'Music';
  static const String comedy = 'Comedy';
  static const String sports = 'Sports';
  static const String tech = 'Tech';
  static const String generalEvent = 'General event';

  static const List<String> all = [
    birthday,
    dinner,
    privateGathering,
    wedding,
    anniversary,
    graduation,
    generalParty,
    music,
    comedy,
    sports,
    tech,
    generalEvent,
  ];

  /// Translucent bg alpha matching existing ticket gradients (~0x55).
  static const int _bgAlpha = 0x55;

  static Color _bg(int rgb) => Color((_bgAlpha << 24) | (rgb & 0x00FFFFFF));

  static TicketCategoryPalette forCategory(String category) {
    switch (category) {
      case music:
        return const TicketCategoryPalette(
          eyeColor: AppColors.primary,
          dataModuleColor: Colors.white,
          backgroundStart: AppColors.brandDarkPlum,
          backgroundEnd: AppColors.brandDarkPlum,
        );
      case tech:
        return const TicketCategoryPalette(
          eyeColor: AppColors.primary,
          dataModuleColor: AppColors.secondary,
          backgroundStart: Color(0x5539D2C0),
          backgroundEnd: Color(0x554B39EF),
        );
      case sports:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFF0F3460),
          dataModuleColor: const Color(0xFF16C79A),
          backgroundStart: _bg(0x16C79A),
          backgroundEnd: _bg(0x0F3460),
        );
      case comedy:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFEE8B60),
          dataModuleColor: const Color(0xFFF9CF58),
          backgroundStart: _bg(0xEE8B60),
          backgroundEnd: _bg(0xF9CF58),
        );
      case wedding:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFE8B4B8),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0xFFF8F0),
          backgroundEnd: _bg(0xF5D0D4),
        );
      case birthday:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFFF6B6B),
          dataModuleColor: const Color(0xFF4ECDC4),
          backgroundStart: _bg(0xFF6B6B),
          backgroundEnd: _bg(0x4ECDC4),
        );
      case dinner:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFF8B4513),
          dataModuleColor: const Color(0xFFF5E6D3),
          backgroundStart: _bg(0x8B4513),
          backgroundEnd: _bg(0xC9A227),
        );
      case privateGathering:
        return TicketCategoryPalette(
          eyeColor: AppColors.primary,
          dataModuleColor: Colors.white,
          backgroundStart: _bg(0x6A0572),
          backgroundEnd: _bg(0xFF6B6B),
        );
      case anniversary:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFC9A227),
          dataModuleColor: const Color(0xFFFFFFFF),
          backgroundStart: _bg(0xC9A227),
          backgroundEnd: _bg(0xFFFFFF),
        );
      case graduation:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFF14181B),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0x14181B),
          backgroundEnd: _bg(0xC0C0C0),
        );
      case generalParty:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFFFFFFF),
          dataModuleColor: AppColors.primary,
          backgroundStart: _bg(0xFFFFFF),
          backgroundEnd: _bg(0xC0C0C0),
        );
      case generalEvent:
      default:
        return TicketCategoryPalette(
          eyeColor: const Color(0xFFFFF8E7),
          dataModuleColor: const Color(0xFFC9A227),
          backgroundStart: _bg(0xFFF8E7),
          backgroundEnd: _bg(0xC9A227),
        );
    }
  }
}
