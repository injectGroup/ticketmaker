import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import '../../../core/utils/color_contrast.dart';
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

  /// The margin a scanner needs around a code, measured in modules.
  static const int _quietZoneModules = 4;

  /// Draws just the ticket's QR code as square PNG bytes, or null on failure.
  ///
  /// The PDF export prints this image; [_composeSync] paints the same code
  /// onto the shared PNG.
  static Uint8List? qrPngBytes(Ticket ticket, {int pixels = 512}) {
    try {
      final side = pixels < 64 ? 64 : pixels;
      // Opaque: the field covers the whole square, and an alpha channel would
      // only add a soft mask for a printer to interpret.
      final canvas = img.Image(width: side, height: side, numChannels: 3);
      _drawScannableQr(canvas, ticket, left: 0, top: 0, size: side);
      final encoded = img.encodePng(canvas);
      if (encoded.isEmpty) return null;
      return Uint8List.fromList(encoded);
    } catch (e, st) {
      debugPrint('Ticket QR PNG failed: $e\n$st');
      return null;
    }
  }

  /// Draws [ticket]'s code as a reader expects to find it: dark modules on a
  /// light field, ringed by a quiet zone.
  ///
  /// The ticket's palette only reaches the modules when it is dark enough to
  /// scan. Wearing the card's own colours — pale modules inverted onto a dark
  /// pad — produced a code that readers do not decode at all.
  static void _drawScannableQr(
    img.Image canvas,
    Ticket ticket, {
    required int left,
    required int top,
    required int size,
  }) {
    final data = ticket.qrData.trim().isEmpty ? ticket.code : ticket.qrData;
    final field = _toImgColor(ColorContrast.qrField);
    img.fillRect(
      canvas,
      x1: left,
      y1: top,
      x2: left + size,
      y2: top + size,
      color: field,
    );

    final margin = _quietZoneWidth(data, size);
    _drawQr(
      canvas,
      data: data,
      left: left + margin,
      top: top + margin,
      size: size - margin * 2,
      moduleColor: _toImgColor(ColorContrast.qrInk(ticket.dataModuleColor)),
      eyeColor: _toImgColor(ColorContrast.qrInk(ticket.eyeColor)),
      background: field,
    );
  }

  /// Splits [side] between the code and the quiet zone on either side of it,
  /// so both are measured in the same modules.
  static int _quietZoneWidth(String data, int side) {
    final modules = QrImage(
      QrCode.fromData(
        data: data.isEmpty ? 'ticket' : data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      ),
    ).moduleCount;
    return (_quietZoneModules * side / (modules + _quietZoneModules * 2))
        .floor();
  }

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
    _drawScannableQr(canvas, ticket, left: qrLeft, top: y, size: _qrSize);
    y += _qrSize + 16;

    final code = _safeText(ticket.code, fallback: '----');
    _drawBadge(canvas, code, y: y);
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
  }) {
    const padX = 16;
    const padY = 8;
    final textW = code.length * 8;
    final boxW = textW + padX * 2;
    final boxH = 14 + padY * 2;
    final left = (_width - boxW) ~/ 2;
    final bg = _toImgColor(ColorContrast.ticketIdField);
    final fg = _toImgColor(ColorContrast.ticketIdInk);
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
    final covered = _coverTo(decoded, _photoW, _photoH);
    img.compositeImage(canvas, covered, dstX: left, dstY: top);
  }

  /// Scales [src] to fill [width]×[height] then centre-crops — BoxFit.cover.
  static img.Image _coverTo(img.Image src, int width, int height) {
    if (src.width <= 0 || src.height <= 0) return src;
    final scale = math.max(width / src.width, height / src.height);
    var resizedW = math.max(width, (src.width * scale).round());
    var resizedH = math.max(height, (src.height * scale).round());
    final resized = img.copyResize(
      src,
      width: resizedW,
      height: resizedH,
      interpolation: img.Interpolation.linear,
    );
    final x = ((resized.width - width) / 2).round().clamp(0, resized.width);
    final y = ((resized.height - height) / 2).round().clamp(0, resized.height);
    final cropW = math.min(width, resized.width - x);
    final cropH = math.min(height, resized.height - y);
    return img.copyCrop(
      resized,
      x: x,
      y: y,
      width: cropW,
      height: cropH,
    );
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
          // Rounded edges tile exactly: no gaps, and no module spilling into
          // its neighbour. Growing each one outwards instead swallows the
          // light modules between them once the cells are only a few pixels
          // wide, and a reader sees no code at all.
          final x1 = left + (col * cell).round();
          final y1 = top + (row * cell).round();
          final x2 = left + ((col + 1) * cell).round() - 1;
          final y2 = top + ((row + 1) * cell).round() - 1;
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
