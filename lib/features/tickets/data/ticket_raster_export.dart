import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import '../../generate/domain/entities/ticket.dart';

/// Builds a downloadable ticket PNG with [package:image] + [package:qr].
///
/// Does **not** use [RepaintBoundary.toImage] / CanvasKit OffscreenCanvas, so
/// Flutter Web LateInitializationError during export cannot block downloads.
class TicketRasterExport {
  TicketRasterExport._();

  static const int _width = 420;
  static const int _photoW = 300;
  static const int _photoH = 200;
  static const int _qrSize = 150;

  /// Returns PNG bytes, or null on failure.
  static Future<Uint8List?> toPngBytes(
    Ticket ticket, {
    Uint8List? eventImageBytes,
  }) async {
    try {
      // Always sync — Ticket/Color are not isolate-safe via compute on all
      // platforms, and CanvasKit LateInit is the problem we are avoiding.
      return _composeSync(ticket, eventImageBytes);
    } catch (e, st) {
      debugPrint('TicketRasterExport failed: $e\n$st');
      return null;
    }
  }

  static Uint8List? _composeSync(Ticket ticket, Uint8List? eventImageBytes) {
    final canvas = img.Image(width: _width, height: 760, numChannels: 4);
    final start = _toImgColor(ticket.topGradientStart);
    final end = _toImgColor(ticket.topGradientEnd);
    _fillVerticalGradient(canvas, start, end);

    final onCard = _onGradient(ticket.topGradientStart, ticket.topGradientEnd);
    final textColor = _toImgColor(onCard);
    final pad = _qrPad(ticket.dataModuleColor);

    var y = 24;
    _drawCentered(
      canvas,
      _safeText(ticket.headerLabel, fallback: 'My Ticket'),
      y: y,
      font: img.arial24,
      color: textColor,
    );
    y += 40;

    final qrLeft = (_width - _qrSize) ~/ 2;
    _drawQr(
      canvas,
      data: ticket.qrData.trim().isEmpty ? ticket.code : ticket.qrData,
      left: qrLeft,
      top: y,
      size: _qrSize,
      moduleColor: _toImgColor(ticket.dataModuleColor),
      eyeColor: _toImgColor(ticket.eyeColor),
      background: _toImgColor(pad),
    );
    y += _qrSize + 16;

    final code = _safeText(ticket.code, fallback: '----');
    _drawBadge(canvas, code, y: y, fg: textColor, bg: _withAlpha(onCard, 0.14));
    y += 44;

    _drawDashedLine(canvas, y: y, color: _withAlpha(onCard, 0.45));
    y += 24;

    _drawCentered(
      canvas,
      _safeText(ticket.title, fallback: 'Event'),
      y: y,
      font: img.arial24,
      color: textColor,
    );
    y += 36;

    final photoLeft = (_width - _photoW) ~/ 2;
    _drawEventPhoto(
      canvas,
      left: photoLeft,
      top: y,
      bytes: eventImageBytes,
      placeholderColor: _withAlpha(onCard, 0.12),
      borderColor: _withAlpha(onCard, 0.35),
    );
    y += _photoH + 20;

    _drawCentered(
      canvas,
      _safeText(ticket.subtitle, fallback: ''),
      y: y,
      font: img.arial14,
      color: textColor,
    );
    y += 28;

    final when =
        '${_safeText(ticket.dateLabel, fallback: '')}  ·  ${_safeText(ticket.timeLabel, fallback: '')}';
    _drawCentered(
      canvas,
      when.trim(),
      y: y,
      font: img.arial14,
      color: textColor,
    );
    y += 24;

    final venue = ticket.venue.trim();
    if (venue.isNotEmpty) {
      _drawCentered(
        canvas,
        _safeText(venue, fallback: ''),
        y: y,
        font: img.arial14,
        color: textColor,
      );
    }

    final encoded = img.encodePng(canvas);
    if (encoded.isEmpty) return null;
    return Uint8List.fromList(encoded);
  }

  static void _fillVerticalGradient(
    img.Image canvas,
    img.Color start,
    img.Color end,
  ) {
    final maxRow = (canvas.height - 1).clamp(1, 100000);
    for (var row = 0; row < canvas.height; row++) {
      final t = row / maxRow;
      final color = img.ColorRgba8(
        _lerp(start.r.toInt(), end.r.toInt(), t),
        _lerp(start.g.toInt(), end.g.toInt(), t),
        _lerp(start.b.toInt(), end.b.toInt(), t),
        255,
      );
      for (var col = 0; col < canvas.width; col++) {
        canvas.setPixel(col, row, color);
      }
    }
  }

  static int _lerp(int a, int b, double t) =>
      (a + ((b - a) * t)).round().clamp(0, 255);

  static img.ColorRgba8 _toImgColor(Color c) {
    final v = c.toARGB32();
    return img.ColorRgba8(
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
      (v >> 24) & 0xFF,
    );
  }

  static img.ColorRgba8 _withAlpha(Color c, double alpha) {
    final v = c.toARGB32();
    return img.ColorRgba8(
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
      (alpha.clamp(0.0, 1.0) * 255).round(),
    );
  }

  static Color _onGradient(Color a, Color b) {
    final ar = (a.toARGB32() >> 16) & 0xFF;
    final ag = (a.toARGB32() >> 8) & 0xFF;
    final ab = a.toARGB32() & 0xFF;
    final br = (b.toARGB32() >> 16) & 0xFF;
    final bg = (b.toARGB32() >> 8) & 0xFF;
    final bb = b.toARGB32() & 0xFF;
    final lum = (0.299 * ((ar + br) / 2) +
            0.587 * ((ag + bg) / 2) +
            0.114 * ((ab + bb) / 2)) /
        255.0;
    return lum > 0.55 ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  }

  static Color _qrPad(Color module) {
    final v = module.toARGB32();
    final r = (v >> 16) & 0xFF;
    final g = (v >> 8) & 0xFF;
    final b = v & 0xFF;
    final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    return lum > 0.55 ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  }

  static String _safeText(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    final buf = StringBuffer();
    for (final unit in trimmed.codeUnits) {
      if (unit >= 32 && unit <= 126) {
        buf.writeCharCode(unit);
      } else {
        buf.write('?');
      }
    }
    final out = buf.toString().trim();
    return out.isEmpty ? fallback : out;
  }

  static void _drawCentered(
    img.Image canvas,
    String text, {
    required int y,
    required img.BitmapFont font,
    required img.Color color,
  }) {
    if (text.isEmpty) return;
    img.drawString(
      canvas,
      text,
      font: font,
      y: y,
      color: color,
    );
  }

  static void _drawBadge(
    img.Image canvas,
    String code, {
    required int y,
    required img.Color fg,
    required img.Color bg,
  }) {
    const padX = 16;
    const padY = 8;
    final textW = code.length * 8;
    final boxW = textW + padX * 2;
    final boxH = 14 + padY * 2;
    final left = (_width - boxW) ~/ 2;
    img.fillRect(
      canvas,
      x1: left,
      y1: y,
      x2: left + boxW,
      y2: y + boxH,
      color: bg,
    );
    img.drawString(
      canvas,
      code,
      font: img.arial14,
      x: left + padX,
      y: y + padY,
      color: fg,
    );
  }

  static void _drawDashedLine(
    img.Image canvas, {
    required int y,
    required img.Color color,
  }) {
    const margin = 30;
    var x = margin;
    while (x < _width - margin) {
      final end = (x + 8).clamp(0, _width - margin);
      img.drawLine(canvas, x1: x, y1: y, x2: end, y2: y, color: color);
      x += 14;
    }
  }

  static void _drawEventPhoto(
    img.Image canvas, {
    required int left,
    required int top,
    required Uint8List? bytes,
    required img.Color placeholderColor,
    required img.Color borderColor,
  }) {
    img.fillRect(
      canvas,
      x1: left,
      y1: top,
      x2: left + _photoW,
      y2: top + _photoH,
      color: placeholderColor,
    );
    img.drawRect(
      canvas,
      x1: left,
      y1: top,
      x2: left + _photoW - 1,
      y2: top + _photoH - 1,
      color: borderColor,
    );

    if (bytes == null || bytes.isEmpty) {
      img.drawString(
        canvas,
        'Photo',
        font: img.arial14,
        x: left + _photoW ~/ 2 - 20,
        y: top + _photoH ~/ 2 - 7,
        color: borderColor,
      );
      return;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    final resized = img.copyResize(
      decoded,
      width: _photoW,
      height: _photoH,
      interpolation: img.Interpolation.linear,
    );
    img.compositeImage(canvas, resized, dstX: left, dstY: top);
  }

  static void _drawQr(
    img.Image canvas, {
    required String data,
    required int left,
    required int top,
    required int size,
    required img.Color moduleColor,
    required img.Color eyeColor,
    required img.Color background,
  }) {
    img.fillRect(
      canvas,
      x1: left,
      y1: top,
      x2: left + size,
      y2: top + size,
      color: background,
    );

    try {
      final qrCode = QrCode.fromData(
        data: data.isEmpty ? 'ticket' : data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      final modules = qrImage.moduleCount;
      final cell = size / modules;
      for (var row = 0; row < modules; row++) {
        for (var col = 0; col < modules; col++) {
          if (!qrImage.isDark(row, col)) continue;
          final x1 = left + (col * cell).floor();
          final y1 = top + (row * cell).floor();
          final x2 = left + ((col + 1) * cell).ceil();
          final y2 = top + ((row + 1) * cell).ceil();
          final isFinder = (row < 7 && col < 7) ||
              (row < 7 && col >= modules - 7) ||
              (row >= modules - 7 && col < 7);
          img.fillRect(
            canvas,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            color: isFinder ? eyeColor : moduleColor,
          );
        }
      }
    } catch (e, st) {
      debugPrint('TicketRasterExport QR failed: $e\n$st');
      img.drawString(
        canvas,
        'QR',
        font: img.arial24,
        x: left + size ~/ 2 - 16,
        y: top + size ~/ 2 - 12,
        color: moduleColor,
      );
    }
  }
}
