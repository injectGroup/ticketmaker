import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_pdf_export.dart';

import 'pdf_content_probe.dart';

/// The PDF a guest shares is built entirely in memory, so these tests read the
/// returned bytes directly. Structural assertions (`%PDF-`, `%%EOF`) are what a
/// reader actually requires; the text assertions run with the standard-font
/// fallback because embedded TrueType text is written as glyph ids, not ASCII.
Ticket _ticket({
  String id = 'tkt-1',
  String title = "Ejike's Birthday Bash",
  String subtitle = 'VIP Guest Pass',
  String venue = 'Private gathering',
  String code = '1234-5678-910',
  bool checkedIn = false,
  String qrData =
      'https://quick-ticket-maker-sandbox.web.app/verify/1234-5678-910',
}) {
  return Ticket(
    id: id,
    headerLabel: 'GUEST PASS',
    title: title,
    subtitle: subtitle,
    venue: venue,
    dateLabel: 'Fri, 31 Jul 2026',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 31, 20),
    code: code,
    qrData: qrData,
    imagePath: '',
    checkedInAt: checkedIn ? DateTime(2026, 7, 31, 20, 30) : null,
    eyeColor: const Color(0xFFE0405B),
    dataModuleColor: const Color(0xFF2B1B2E),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );
}

/// A guest who pasted an essay into every field. Nothing here is unusual
/// enough to justify losing the QR code.
Ticket _wordyTicket() {
  return _ticket(
    title: 'The Grand Annual Harvest Gala and Anniversary Celebration '
        'Weekend Extravaganza Hosted By The Lagos Society Of Friends And '
        'Neighbours Incorporated, Twenty Sixth Edition, In Aid Of The '
        'Riverside Childrens Hospital Building Fund And The Neighbourhood '
        'Music School Scholarship Programme For The Coming Season',
    subtitle: 'VIP Guest Pass with backstage access and dinner seating in '
        'the garden marquee, plus valet parking, welcome cocktails, and an '
        'after-party wristband for the rooftop lounge session that runs '
        'until sunrise on Saturday morning, breakfast included, with a '
        'shuttle back to the hotel and a keepsake photograph taken at the '
        'entrance arch on the way in',
    venue: 'The Riverside Pavilion, 1200 Lakeshore Boulevard, Victoria '
        'Island, Lagos, Nigeria, by the old lighthouse and the community '
        'centre near the marina gates, fourth gate on the left, ask for the '
        'garden entrance behind the bell tower and follow the lantern path '
        'down to the water where the marquee is pitched',
    checkedIn: true,
  );
}

/// Smallest valid PNG (1x1, transparent) so the encoder has real bytes.
Uint8List _onePixelPng() {
  return Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
}

String _asLatin1(Uint8List bytes) => String.fromCharCodes(bytes);

void _expectValidPdf(Uint8List? bytes) {
  expect(bytes, isNotNull);
  expect(bytes!, isNotEmpty);
  expect(
    _asLatin1(bytes.sublist(0, 5)),
    '%PDF-',
    reason: 'a PDF must start with the %PDF- header',
  );
  expect(
    _asLatin1(bytes.sublist(bytes.length - 32)),
    contains('%%EOF'),
    reason: 'a truncated document would not open in a reader',
  );
}

/// Anything drawn outside the page box is invisible to a reader and to a
/// printer, so a ticket that "exists" off-page is a ticket the guest lost.
void _expectOnPage(ProbeRect rect, PdfPageFormat format) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.bottom, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(format.width));
  expect(rect.top, lessThanOrEqualTo(format.height));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildDocumentBytes', () {
    test('returns a complete in-memory PDF document', () async {
      _expectValidPdf(await TicketPdfExport.buildDocumentBytes(_ticket()));
    });

    test('carries the ticket details as selectable text', () async {
      final bytes = await TicketPdfExport.buildDocumentBytes(
        _ticket(),
        compress: false,
        embedBundledFonts: false,
      );
      _expectValidPdf(bytes);

      // The encoder positions every word as its own text run, so the document
      // is searched a word at a time rather than by whole phrase.
      final content = _asLatin1(bytes!);
      for (final expected in const <String>[
        'Birthday',
        'Bash',
        'Guest',
        'Pass',
        'gathering',
        '1234-5678-910',
        'entrance',
        'Powered',
      ]) {
        expect(
          content,
          contains('($expected)'),
          reason: 'the ticket must stay readable when printed: '
              'no text run draws "$expected"',
        );
      }
    });

    test('embeds the fonts it draws with, so no reader substitutes them',
        () async {
      final bytes = await TicketPdfExport.buildDocumentBytes(
        _ticket(),
        compress: false,
      );
      _expectValidPdf(bytes);

      expect(
        _asLatin1(bytes!),
        contains('FontFile2'),
        reason: 'the bundled TrueType font should be embedded in the document',
      );
    });

    test('draws the QR payload as vector content that grows with the payload',
        () async {
      final short = await TicketPdfExport.buildDocumentBytes(
        _ticket(qrData: 'x'),
        compress: false,
      );
      final long = await TicketPdfExport.buildDocumentBytes(
        _ticket(
          qrData: 'https://quick-ticket-maker-sandbox.web.app/verify/'
              '${'9' * 180}',
        ),
        compress: false,
      );

      _expectValidPdf(short);
      _expectValidPdf(long);
      expect(
        long!.length,
        greaterThan(short!.length),
        reason: 'a denser QR code should add drawing operations, which is only '
            'true if the code is generated rather than pasted as an image',
      );
    });

    test('embeds the event photo when usable bytes are supplied', () async {
      final withoutPhoto = await TicketPdfExport.buildDocumentBytes(
        _ticket(),
        compress: false,
      );
      final withPhoto = await TicketPdfExport.buildDocumentBytes(
        _ticket(),
        eventImageBytes: _onePixelPng(),
        compress: false,
      );

      _expectValidPdf(withoutPhoto);
      _expectValidPdf(withPhoto);
      expect(
        withPhoto!.length,
        greaterThan(withoutPhoto!.length),
        reason: 'the embedded photo should add an image object',
      );
    });

    test('still produces a ticket when the photo bytes are unusable', () async {
      final garbage = Uint8List.fromList(List<int>.filled(64, 0x7F));

      _expectValidPdf(
        await TicketPdfExport.buildDocumentBytes(
          _ticket(),
          eventImageBytes: garbage,
        ),
      );
      _expectValidPdf(
        await TicketPdfExport.buildDocumentBytes(
          _ticket(),
          eventImageBytes: Uint8List(0),
        ),
      );
    });

    test('survives a ticket with empty text fields', () async {
      _expectValidPdf(
        await TicketPdfExport.buildDocumentBytes(
          _ticket(title: '', subtitle: '', venue: '', code: '', qrData: ''),
        ),
      );
    });
  });

  /// The QR code is the only part of the ticket the door cannot work around,
  /// so these tests read the drawing operators back and check where the code
  /// actually landed rather than trusting that the bytes are well formed.
  group('page layout', () {
    Future<PdfPageProbe> probe(
      Ticket ticket, {
      Uint8List? photo,
      PdfPageFormat? format,
      bool embedBundledFonts = false,
    }) async {
      final bytes = await TicketPdfExport.buildDocumentBytes(
        ticket,
        eventImageBytes: photo,
        compress: false,
        embedBundledFonts: embedBundledFonts,
        format: format,
      );
      _expectValidPdf(bytes);
      return PdfPageProbe.parse(bytes!);
    }

    test('draws the QR code above the scan caption', () async {
      final page = await probe(_ticket());

      final qr = page.qrBounds();
      final caption = page.textAt('Scan');
      expect(qr, isNotNull, reason: 'no QR code was drawn on the page');
      expect(caption, isNotNull, reason: 'the scan caption is missing');
      expect(
        caption!.y,
        lessThan(qr!.bottom),
        reason: 'the caption must read as a label for the code above it',
      );
      expect(caption.x, greaterThanOrEqualTo(qr.left));
      expect(caption.x, lessThanOrEqualTo(qr.right));
      expect(qr.width, closeTo(TicketPdfExport.qrSize, 2));
      expect(qr.height, closeTo(TicketPdfExport.qrSize, 2));
    });

    test('keeps the QR code above the caption when a photo is embedded',
        () async {
      final bare = await probe(_ticket());
      final illustrated = await probe(_ticket(), photo: _onePixelPng());

      final bareQr = bare.qrBounds();
      final qr = illustrated.qrBounds();
      final caption = illustrated.textAt('Scan');
      expect(qr, isNotNull, reason: 'the photo displaced the QR code');
      expect(caption, isNotNull);
      expect(caption!.y, lessThan(qr!.bottom));
      expect(
        qr.height,
        closeTo(TicketPdfExport.qrSize, 2),
        reason: 'the code must not be squeezed to make room for the photo',
      );
      _expectOnPage(qr, TicketPdfExport.pageFormat);

      final displaced = bareQr!.bottom - qr.bottom;
      expect(displaced, greaterThan(0));
      expect(
        displaced,
        lessThanOrEqualTo(TicketPdfExport.photoMaxHeight + 1),
        reason: 'the photo band must stay within its cap so the code below '
            'it keeps its place on the page',
      );
    });

    test('keeps the whole ticket on the page when every field is long',
        () async {
      final page = await probe(_wordyTicket(), photo: _onePixelPng());

      final qr = page.qrBounds();
      expect(
        qr,
        isNotNull,
        reason: 'a wordy ticket must not cost the guest their QR code',
      );
      _expectOnPage(qr!, TicketPdfExport.pageFormat);
      expect(page.textAt('Scan')!.y, lessThan(qr.bottom));
      expect(
        page.textAt('Powered'),
        isNotNull,
        reason: 'content pushed past the page bottom is dropped whole, so a '
            'missing footer means the page overflowed',
      );
    });

    test('scales the ticket down rather than losing it on a small page',
        () async {
      const small = PdfPageFormat(300, 380);
      final page = await probe(
        _wordyTicket(),
        photo: _onePixelPng(),
        format: small,
      );

      final qr = page.qrBounds();
      expect(qr, isNotNull, reason: 'the code must survive a cramped page');
      _expectOnPage(qr!, small);
      expect(page.textAt('Scan')!.y, lessThan(qr.bottom));
      expect(
        qr.width,
        lessThan(TicketPdfExport.qrSize),
        reason: 'a card taller than the page should shrink to fit',
      );
    });

    test('draws the QR code with the bundled fonts in place', () async {
      final page = await probe(
        _wordyTicket(),
        photo: _onePixelPng(),
        embedBundledFonts: true,
      );

      final qr = page.qrBounds();
      expect(qr, isNotNull);
      _expectOnPage(qr!, TicketPdfExport.pageFormat);
      expect(qr.height, closeTo(TicketPdfExport.qrSize, 2));
    });
  });

  group('fileNameFor', () {
    test('names the file after the ticket id', () {
      expect(
        TicketPdfExport.fileNameFor(_ticket(id: 'abc-123')),
        'Ticket_abc-123.pdf',
      );
    });

    test('replaces unsafe characters and falls back for a blank id', () {
      expect(
        TicketPdfExport.fileNameFor(_ticket(id: 'a b/c:d')),
        'Ticket_a_b_c_d.pdf',
      );
      expect(
        TicketPdfExport.fileNameFor(_ticket(id: '   ')),
        'Ticket_ticket.pdf',
      );
    });
  });

  group('offline guarantee', () {
    test('does not reach for network-hosted PDF fonts', () {
      final source =
          File('lib/features/tickets/data/ticket_pdf_export.dart')
              .readAsStringSync();

      expect(
        source,
        isNot(contains('PdfGoogleFonts')),
        reason: 'PdfGoogleFonts downloads a typeface at runtime, which would '
            'undo the bundled-font work guarded by bundled_fonts_test.dart',
      );
    });
  });
}
