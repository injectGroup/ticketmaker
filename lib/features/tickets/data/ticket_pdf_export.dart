import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../generate/domain/entities/ticket.dart';

/// Builds a printable PDF of a ticket entirely in memory.
///
/// Callers receive bytes and hand them straight to the share sheet, so sharing
/// a ticket never leaves a copy behind in device storage.
///
/// The page is drawn from the ticket model rather than wrapped around a
/// screenshot: the details are real text and the QR code is vector artwork, so
/// the ticket stays legible and scannable at any print size. The optional event
/// photo is the only raster element.
class TicketPdfExport {
  TicketPdfExport._();

  /// A4 keeps the ticket printable on ordinary paper at the door.
  static const PdfPageFormat pageFormat = PdfPageFormat.a4;

  static const PdfColor _ink = PdfColor.fromInt(0xFF15161E);
  static const PdfColor _muted = PdfColor.fromInt(0xFF757780);
  static const PdfColor _hairline = PdfColor.fromInt(0xFFE0E3E7);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFFFF);

  static pw.ThemeData? _cachedTheme;
  static pw.Font? _cachedMonoFont;

  /// Sanitized share name: `Ticket_<ticket.id>.pdf`.
  static String fileNameFor(Ticket ticket) {
    final safe = ticket.id.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'Ticket_${safe.isEmpty ? 'ticket' : safe}.pdf';
  }

  /// Renders [ticket] to PDF bytes, embedding [eventImageBytes] when they look
  /// like an image the encoder can read.
  ///
  /// Returns `null` only when no document can be produced at all, so callers can
  /// fall back to sharing the image or the link instead of failing outright.
  ///
  /// Pass `compress: false` to keep the content streams readable, and
  /// `embedBundledFonts: false` to fall back to the PDF standard fonts — the
  /// same path taken automatically if the bundled font assets cannot be loaded.
  static Future<Uint8List?> buildDocumentBytes(
    Ticket ticket, {
    Uint8List? eventImageBytes,
    bool compress = true,
    bool embedBundledFonts = true,
  }) async {
    final theme = embedBundledFonts ? await _loadBundledTheme() : null;
    final photo = _usableImage(eventImageBytes);

    final bytes = await _save(
      ticket,
      theme: theme,
      monoFont: theme == null ? null : _cachedMonoFont,
      photo: photo,
      compress: compress,
    );
    if (bytes != null || photo == null) return bytes;

    // A photo the encoder rejects must not cost the guest their ticket.
    return _save(
      ticket,
      theme: theme,
      monoFont: theme == null ? null : _cachedMonoFont,
      photo: null,
      compress: compress,
    );
  }

  static Future<Uint8List?> _save(
    Ticket ticket, {
    required pw.ThemeData? theme,
    required pw.Font? monoFont,
    required pw.MemoryImage? photo,
    required bool compress,
  }) async {
    try {
      final document = pw.Document(
        compress: compress,
        theme: theme,
        title: _title(ticket),
        author: 'Quick Ticket Maker',
        subject: 'Event ticket',
      );

      final layout = _TicketPdfLayout(
        ticket: ticket,
        photo: photo,
        monoFont: monoFont,
        // Standard fonts only cover Latin-1, so typographic punctuation has to
        // be folded down when the bundled TrueType faces are unavailable.
        sanitizeText: theme == null,
      );

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => layout.build(),
        ),
      );

      return await document.save();
    } catch (e, st) {
      debugPrint('Ticket PDF build failed: $e\n$st');
      return null;
    }
  }

  /// Reuses the app's bundled typefaces so the document needs no network and
  /// prints with the same faces the guest saw on screen.
  static Future<pw.ThemeData?> _loadBundledTheme() async {
    if (_cachedTheme != null) return _cachedTheme;
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/ReadexPro-Regular.ttf'),
      );
      final semiBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/ReadexPro-SemiBold.ttf'),
      );
      _cachedMonoFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'),
      );
      _cachedTheme = pw.ThemeData.withFont(
        base: regular,
        bold: semiBold,
        italic: regular,
        boldItalic: semiBold,
      );
      return _cachedTheme;
    } catch (e) {
      debugPrint('Bundled PDF fonts unavailable, using standard fonts: $e');
      return null;
    }
  }

  /// Only PNG and JPEG reach the encoder; anything else is skipped rather than
  /// risked, since the photo is decoration and the ticket is not.
  static pw.MemoryImage? _usableImage(Uint8List? bytes) {
    if (bytes == null || bytes.length < 4) return null;
    final isPng = bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isJpeg =
        bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    if (!isPng && !isJpeg) return null;
    try {
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('Ticket PDF photo skipped, bytes not decodable: $e');
      return null;
    }
  }

  static String _title(Ticket ticket) {
    final title = ticket.title.trim();
    return title.isEmpty ? 'Event ticket' : title;
  }
}

/// Page composition for a single ticket.
class _TicketPdfLayout {
  _TicketPdfLayout({
    required this.ticket,
    required this.photo,
    required this.monoFont,
    required this.sanitizeText,
  });

  final Ticket ticket;
  final pw.MemoryImage? photo;
  final pw.Font? monoFont;
  final bool sanitizeText;

  PdfColor get _bandStart => _toPdfColor(ticket.topGradientStart);
  PdfColor get _bandEnd => _toPdfColor(ticket.bottomGradientEnd);

  /// Header text has to stay readable over whatever gradient the guest picked.
  PdfColor get _onBand {
    final luminance = 0.299 * _bandStart.red +
        0.587 * _bandStart.green +
        0.114 * _bandStart.blue;
    return luminance > 0.6
        ? const PdfColor.fromInt(0xFF15161E)
        : const PdfColor.fromInt(0xFFFFFFFF);
  }

  pw.Widget build() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            color: TicketPdfExport._paper,
            border: pw.Border.all(color: TicketPdfExport._hairline),
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(),
              if (photo != null) _photo(),
              _body(),
            ],
          ),
        ),
        pw.Spacer(),
        _footer(),
      ],
    );
  }

  pw.Widget _header() {
    final onBand = _onBand;
    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [_bandStart, _bandEnd]),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(14),
          topRight: pw.Radius.circular(14),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _text(_label),
            style: pw.TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor(onBand.red, onBand.green, onBand.blue, 0.85),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _text(TicketPdfExport._title(ticket)),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: onBand,
            ),
          ),
          if (ticket.subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              _text(ticket.subtitle.trim()),
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor(onBand.red, onBand.green, onBand.blue, 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _photo() {
    return pw.Container(
      height: 190,
      width: double.infinity,
      child: pw.Image(photo!, fit: pw.BoxFit.cover),
    );
  }

  pw.Widget _body() {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(22),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _field('WHEN', _when),
                if (ticket.venue.trim().isNotEmpty)
                  _field('WHERE', ticket.venue.trim()),
                _field('TICKET ID', _code, mono: true),
                if (ticket.isCheckedIn)
                  _field('STATUS', 'Already checked in at the door'),
              ],
            ),
          ),
          if (ticket.qrData.trim().isNotEmpty) ...[
            pw.SizedBox(width: 18),
            _qrBlock(),
          ],
        ],
      ),
    );
  }

  pw.Widget _qrBlock() {
    return pw.Column(
      children: [
        pw.Container(
          width: 132,
          height: 132,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: ticket.qrData.trim(),
            drawText: false,
            color: _toPdfColor(ticket.dataModuleColor),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _text('Scan at entrance'),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.4,
            color: TicketPdfExport._muted,
          ),
        ),
      ],
    );
  }

  pw.Widget _field(String label, String value, {bool mono = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _text(label),
            style: pw.TextStyle(
              fontSize: 8,
              letterSpacing: 1.4,
              color: TicketPdfExport._muted,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _text(value),
            style: pw.TextStyle(
              font: mono ? monoFont : null,
              fontSize: mono ? 13 : 12,
              fontWeight: pw.FontWeight.bold,
              color: TicketPdfExport._ink,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer() {
    final link = ticket.qrData.trim();
    final showLink = link.startsWith('http://') || link.startsWith('https://');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: TicketPdfExport._hairline, thickness: 0.5),
        pw.SizedBox(height: 6),
        if (showLink)
          pw.Text(
            _text(link),
            style: const pw.TextStyle(
              fontSize: 8,
              color: TicketPdfExport._muted,
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Text(
          _text('Powered by Quick Ticket'),
          style: const pw.TextStyle(
            fontSize: 8,
            color: TicketPdfExport._muted,
          ),
        ),
      ],
    );
  }

  String get _label {
    final label = ticket.headerLabel.trim();
    return (label.isEmpty ? 'GUEST PASS' : label).toUpperCase();
  }

  String get _code {
    final code = ticket.code.trim();
    return code.isEmpty ? 'Not assigned' : code;
  }

  String get _when {
    final date = ticket.dateLabel.trim();
    final time = ticket.timeLabel.trim();
    if (date.isEmpty && time.isEmpty) return 'See invitation';
    if (time.isEmpty) return date;
    if (date.isEmpty) return time;
    return '$date at $time';
  }

  String _text(String value) => sanitizeText ? _foldToLatin1(value) : value;

  static String _foldToLatin1(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x2013 || 0x2014:
          buffer.write('-');
        case 0x2018 || 0x2019:
          buffer.write("'");
        case 0x201C || 0x201D:
          buffer.write('"');
        case 0x2022 || 0x00B7:
          buffer.write('-');
        case 0x2026:
          buffer.write('...');
        default:
          buffer.writeCharCode(rune <= 0xFF ? rune : 0x3F);
      }
    }
    return buffer.toString();
  }

  static PdfColor _toPdfColor(Color color) =>
      PdfColor.fromInt(color.toARGB32());
}
