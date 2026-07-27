import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../data/ticket_category_palettes.dart';
import '../../domain/entities/ticket.dart';

part 'generate_state.dart';

class GenerateCubit extends Cubit<GenerateState> {
  GenerateCubit({Random? random}) : this._(random ?? Random());

  GenerateCubit._(this._random)
    : super(GenerateState(ticket: _buildDefaultTicket(random: _random)));

  final Random _random;

  /// Public ticket link template; [code] is the generated ticket id.
  static String ticketPayloadUrl(String code) =>
      'https://ticketmaker.app/t/$code';

  static Ticket _buildDefaultTicket({required Random random}) {
    final eventAt = DateTime.now();
    final code = _makeCode(random);
    return Ticket(
      id: 'default',
      headerLabel: 'GUEST PASS',
      title: "Ejike's Birthday Bash",
      subtitle: 'VIP Guest Pass',
      venue: 'Private gathering',
      dateLabel: formatDateLabel(eventAt),
      timeLabel: formatTimeLabel(eventAt),
      eventAt: eventAt,
      code: code,
      qrData: ticketPayloadUrl(code),
      imagePath: '',
      // Brand pink corners + white modules on dark plum card.
      eyeColor: AppColors.primary,
      dataModuleColor: Colors.white,
      isSquare: false,
      topGradientStart: AppColors.brandDarkPlum,
      topGradientEnd: AppColors.brandDarkPlum,
      bottomGradientStart: AppColors.brandDarkPlum,
      bottomGradientEnd: AppColors.brandDarkPlum,
    );
  }

  static String _makeCode(Random random) {
    String four() => (random.nextInt(9000) + 1000).toString();
    String three() => (random.nextInt(900) + 100).toString();
    return '${four()}-${four()}-${three()}';
  }

  static const List<(Color, Color)> _qrPalettes = [
    (AppColors.primary, Colors.white),
    (AppColors.primary, AppColors.brandDarkPlum),
    (AppColors.error, AppColors.warning),
    (AppColors.primary, AppColors.secondary),
    (Color(0xFF0F3460), Color(0xFF16C79A)),
    (Color(0xFF6A0572), Color(0xFFFFB703)),
  ];

  static const List<(Color, Color)> _bgPalettes = [
    (AppColors.brandDarkPlum, AppColors.brandDarkPlum),
    (AppColors.brandBlush, AppColors.brandBlush),
    (Color(0x55FF5963), Color(0x55F9CF58)),
    (Color(0x5539D2C0), Color(0x554B39EF)),
    (Color(0x55EE8B60), Color(0x554B39EF)),
    (Color(0x5514181B), Color(0x5539D2C0)),
  ];

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDateLabel(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
  }

  static String formatTimeLabel(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

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

  /// Solid / gradient presets shown in the background customizer sheet.
  static const List<Color> topBgColorPresets = [
    AppColors.brandDarkPlum,
    AppColors.primary,
    AppColors.brandBlush,
    AppColors.secondary,
    AppColors.error,
    AppColors.warning,
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

  /// Applies the same solid/gradient to both ticket halves.
  /// Syncs QR corners to brand pink and modules to high-contrast white/dark.
  void setTopBackgroundGradient({required Color start, required Color end}) {
    final ticket = state.ticket;
    final onFg = ColorContrast.onGradient(start, end);
    final darkCard = onFg == ColorContrast.onDark;
    final eye = AppColors.primary;
    final modules = darkCard ? Colors.white : AppColors.brandDarkPlum;

    if (ticket.topGradientStart.toARGB32() == start.toARGB32() &&
        ticket.topGradientEnd.toARGB32() == end.toARGB32() &&
        ticket.bottomGradientStart.toARGB32() == start.toARGB32() &&
        ticket.bottomGradientEnd.toARGB32() == end.toARGB32() &&
        ticket.eyeColor.toARGB32() == eye.toARGB32() &&
        ticket.dataModuleColor.toARGB32() == modules.toARGB32()) {
      return;
    }
    emit(
      state.copyWith(
        ticket: ticket.copyWith(
          topGradientStart: start,
          topGradientEnd: end,
          bottomGradientStart: start,
          bottomGradientEnd: end,
          eyeColor: eye,
          dataModuleColor: modules,
        ),
      ),
    );
  }

  /// Sets both halves to the same solid color.
  void applyTopBackgroundSolid(Color color) {
    setTopBackgroundGradient(start: color, end: color);
  }

  /// Parses `#RRGGBB` and applies a solid background. Returns false if invalid.
  bool applyTopBackgroundSolidHex(String raw) {
    final color = tryParseHexColor(raw);
    if (color == null) return false;
    applyTopBackgroundSolid(color);
    return true;
  }

  /// Parses two hex colors into shared top/bottom gradient stops.
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
    setTopBackgroundGradient(start: next.$1, end: next.$2);
  }

  void setImagePath(String path) {
    if (path == state.ticket.imagePath && state.imageBytes == null) return;
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(imagePath: path),
        clearImageBytes: true,
      ),
    );
  }

  /// Sets the gallery path and optional bytes (required for Flutter Web preview).
  void setPickedImage({required String path, required Uint8List bytes}) {
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(imagePath: path),
        imageBytes: bytes,
      ),
    );
  }

  void setEventDateTime(DateTime eventAt) {
    if (eventAt == state.ticket.eventAt) return;
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          eventAt: eventAt,
          dateLabel: formatDateLabel(eventAt),
          timeLabel: formatTimeLabel(eventAt),
        ),
      ),
    );
  }

  /// Assigns a fresh ticket code + `ticketmaker.app` payload URL.
  /// Called on Save so Share Ticket has a unique link (no Generate button).
  void ensureTicketPayload() {
    final code = _makeCode(_random);
    emit(
      state.copyWith(
        ticket: state.ticket.copyWith(
          code: code,
          qrData: ticketPayloadUrl(code),
        ),
      ),
    );
  }

  void updateHeaderLabel(String headerLabel) {
    if (headerLabel == state.ticket.headerLabel) return;
    emit(
      state.copyWith(ticket: state.ticket.copyWith(headerLabel: headerLabel)),
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

  void updateVenue(String venue) {
    if (venue == state.ticket.venue) return;
    emit(state.copyWith(ticket: state.ticket.copyWith(venue: venue)));
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }

  /// Applies QR + background defaults for an event [category].
  void applyCategoryPalette(String category) {
    final palette = TicketCategoryPalettes.forCategory(category);
    final ticket = state.ticket;
    emit(
      state.copyWith(
        selectedCategory: category,
        ticket: ticket.copyWith(
          eyeColor: palette.eyeColor,
          dataModuleColor: palette.dataModuleColor,
          topGradientStart: palette.backgroundStart,
          topGradientEnd: palette.backgroundEnd,
          bottomGradientStart: palette.backgroundStart,
          bottomGradientEnd: palette.backgroundEnd,
        ),
      ),
    );
  }

  /// Restores the editor to the initial default ticket configuration.
  void resetToDefault() {
    emit(GenerateState(ticket: _buildDefaultTicket(random: _random)));
  }
}
