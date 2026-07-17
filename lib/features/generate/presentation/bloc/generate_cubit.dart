import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';

part 'generate_state.dart';

class GenerateCubit extends Cubit<GenerateState> {
  GenerateCubit({Random? random})
      : _random = random ?? Random(),
        super(GenerateState(ticket: _defaultTicket));

  final Random _random;

  static final Ticket _defaultTicket = Ticket(
    id: 'default',
    headerLabel: 'My Ticket',
    title: 'Circu Du Freak',
    subtitle: 'Vision & Sound Experience',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    code: '1234-5678-910',
    qrData: 'https://www.linkedin.com/in/abdulkadirmohammed/',
    imageUrl: 'https://picsum.photos/seed/695/600',
    eyeColor: AppColors.error,
    dataModuleColor: AppColors.warning,
    isSquare: false,
    topGradientStart: const Color(0x354B39EF),
    topGradientEnd: const Color(0x3A39D2C0),
    bottomGradientStart: const Color(0x8039D2C0),
    bottomGradientEnd: const Color(0x804B39EF),
  );

  static const List<(Color, Color)> _qrPalettes = [
    (AppColors.error, AppColors.warning),
    (AppColors.primary, AppColors.secondary),
    (Color(0xFF1A1A2E), Color(0xFFE94560)),
    (Color(0xFF0F3460), Color(0xFF16C79A)),
    (Color(0xFF6A0572), Color(0xFFFFB703)),
  ];

  static const List<(Color, Color)> _bgPalettes = [
    (Color(0x354B39EF), Color(0x3A39D2C0)),
    (Color(0x55FF5963), Color(0x55F9CF58)),
    (Color(0x5539D2C0), Color(0x554B39EF)),
    (Color(0x55EE8B60), Color(0x554B39EF)),
    (Color(0x5514181B), Color(0x5539D2C0)),
  ];

  void cycleQrColors() {
    final current = (state.ticket.eyeColor, state.ticket.dataModuleColor);
    final index = _qrPalettes.indexWhere(
      (p) => p.$1 == current.$1 && p.$2 == current.$2,
    );
    final next = _qrPalettes[(index + 1) % _qrPalettes.length];
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          eyeColor: next.$1,
          dataModuleColor: next.$2,
        ),
      ),
    );
  }

  void toggleQrShape() {
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(isSquare: !state.ticket.isSquare),
      ),
    );
  }

  /// Solid / gradient presets shown in the top background customizer sheet.
  static const List<Color> topBgColorPresets = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.error,
    AppColors.warning,
    Color(0xFF1A1A2E),
    Color(0xFFE94560),
    Color(0xFF0F3460),
    Color(0xFF16C79A),
    Color(0xFF6A0572),
    Color(0xFFFFB703),
    Color(0xFF14181B),
    Color(0xFFFFFFFF),
  ];

  /// Accepts `#RRGGBB` or `RRGGBB` (case-insensitive).
  static Color? tryParseHexColor(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^#?([A-Fa-f0-9]{6})$').firstMatch(trimmed);
    if (match == null) return null;
    final value = int.parse(match.group(1)!, radix: 16);
    return Color(0xFF000000 | value);
  }

  void setTopBackgroundGradient({
    required Color start,
    required Color end,
  }) {
    final ticket = state.ticket;
    if (ticket.topGradientStart.toARGB32() == start.toARGB32() &&
        ticket.topGradientEnd.toARGB32() == end.toARGB32()) {
      return;
    }
    emit(
      state.copyWith(
        ticket: ticket.copyWith(
          topGradientStart: start,
          topGradientEnd: end,
        ),
      ),
    );
  }

  /// Sets both top gradient stops to the same solid color.
  void applyTopBackgroundSolid(Color color) {
    setTopBackgroundGradient(start: color, end: color);
  }

  /// Parses `#RRGGBB` and applies a solid top background. Returns false if invalid.
  bool applyTopBackgroundSolidHex(String raw) {
    final color = tryParseHexColor(raw);
    if (color == null) return false;
    applyTopBackgroundSolid(color);
    return true;
  }

  /// Parses two hex colors into topGradientStart / topGradientEnd.
  /// Returns false if either value is invalid.
  bool applyTopBackgroundGradientHex({
    required String startRaw,
    required String endRaw,
  }) {
    final start = tryParseHexColor(startRaw);
    final end = tryParseHexColor(endRaw);
    if (start == null || end == null) return false;
    setTopBackgroundGradient(start: start, end: end);
    return true;
  }

  void cycleBackgroundColors() {
    final current = (
      state.ticket.topGradientStart,
      state.ticket.topGradientEnd,
    );
    final index = _bgPalettes.indexWhere(
      (p) => p.$1 == current.$1 && p.$2 == current.$2,
    );
    final next = _bgPalettes[(index + 1) % _bgPalettes.length];
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          topGradientStart: next.$1,
          topGradientEnd: next.$2,
          bottomGradientStart: next.$2.withValues(alpha: 0.5),
          bottomGradientEnd: next.$1.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void refreshImage() {
    final seed = _random.nextInt(10000);
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          imageUrl: 'https://picsum.photos/seed/$seed/600',
        ),
      ),
    );
  }

  void generateTicketCode() {
    final code =
        '${_four()}-${_four()}-${_three()}';
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          code: code,
          qrData: 'https://ticketmaker.app/t/$code',
        ),
        message: 'QR code generated',
      ),
    );
  }

  void updateHeaderLabel(String headerLabel) {
    if (headerLabel == state.ticket.headerLabel) return;
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(headerLabel: headerLabel),
      ),
    );
  }

  void updateTitle(String title) {
    if (title == state.ticket.title) return;
    emit(state.copyWith(ticket: state.ticket.copyWith(title: title)));
  }

  void updateSubtitle(String subtitle) {
    if (subtitle == state.ticket.subtitle) return;
    emit(state.copyWith(ticket: state.ticket.copyWith(subtitle: subtitle)));
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }

  String _four() => (_random.nextInt(9000) + 1000).toString();
  String _three() => (_random.nextInt(900) + 100).toString();
}
