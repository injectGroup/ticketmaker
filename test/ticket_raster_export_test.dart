import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_raster_export.dart';

/// Perceived brightness, on the same 0–1 scale the renderer picks its pad on.
double _luminance(img.Pixel pixel) =>
    (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;

void main() {
  final sampleTicket = Ticket(
    id: 'ticket-raster-test',
    headerLabel: 'VIP Pass',
    title: 'Raster Export Concert',
    subtitle: 'National Stadium',
    venue: 'National Stadium',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 18, 20),
    code: '1111-2222-333',
    qrData: 'https://example.com/ticket/raster-export',
    imagePath: '',
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFFFF9800),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );

  test('TicketRasterExport produces PNG without photo bytes', () async {
    final bytes = await TicketRasterExport.toPngBytes(sampleTicket);
    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test('TicketRasterExport embeds event photo bytes when provided', () async {
    // Minimal valid 1x1 PNG.
    final photo = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    final withPhoto = await TicketRasterExport.toPngBytes(
      sampleTicket,
      eventImageBytes: photo,
    );
    final withoutPhoto = await TicketRasterExport.toPngBytes(sampleTicket);

    expect(withPhoto, isNotNull);
    expect(withoutPhoto, isNotNull);
    expect(withPhoto!, isNotEmpty);
    // Composite with photo should differ from placeholder version.
    expect(withPhoto.length, isNot(withoutPhoto!.length));
  });

  /// The QR image these tests read is the one the PDF export prints, so a
  /// code that is wrong or invisible here is a guest turned away at the door.
  group('qrPngBytes', () {
    QrImage matrixFor(String data) => QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        );

    /// Where module ([row], [col]) was drawn, given the quiet zone the
    /// renderer reserves on all four sides.
    ({int x, int y}) centreOf(int row, int col, int modules, int side) {
      final margin = (4 * side / (modules + 8)).floor();
      final cell = (side - margin * 2) / modules;
      return (
        x: margin + ((col + 0.5) * cell).floor(),
        y: margin + ((row + 0.5) * cell).floor(),
      );
    }

    /// A module away from the three finder squares, which are drawn in the
    /// eye colour rather than the module colour.
    ({int row, int col}) findModule(QrImage matrix, {required bool dark}) {
      final modules = matrix.moduleCount;
      for (var row = 8; row < modules - 8; row++) {
        for (var col = 8; col < modules - 8; col++) {
          if (matrix.isDark(row, col) == dark) return (row: row, col: col);
        }
      }
      throw StateError('no ${dark ? 'dark' : 'light'} module in the body');
    }

    test('paints the payload module for module', () {
      final bytes = TicketRasterExport.qrPngBytes(sampleTicket);
      expect(bytes, isNotNull);

      final image = img.decodePng(bytes!);
      expect(image, isNotNull);

      final matrix = matrixFor(sampleTicket.qrData);
      final modules = matrix.moduleCount;

      // Modules are drawn in the guest's colours — data and finder squares in
      // different ones — so a module counts as drawn when it is anything
      // other than the pad behind it.
      final pad = image!.getPixel(0, 0);
      final wrong = <String>[];
      for (var row = 0; row < modules; row++) {
        for (var col = 0; col < modules; col++) {
          final at = centreOf(row, col, modules, image.width);
          final pixel = image.getPixel(at.x, at.y);
          final drawn =
              pixel.r != pad.r || pixel.g != pad.g || pixel.b != pad.b;
          if (drawn != matrix.isDark(row, col)) wrong.add('$row,$col');
        }
      }
      expect(
        wrong,
        isEmpty,
        reason: 'the picture must be the payload, not decoration: '
            '${wrong.length} of ${modules * modules} modules are wrong',
      );
    });

    test('surrounds the code with a quiet zone a reader can find it by', () {
      final bytes = TicketRasterExport.qrPngBytes(sampleTicket);
      final image = img.decodePng(bytes!)!;
      final pad = _luminance(image.getPixel(0, 0));
      final edge = image.width - 1;

      for (final corner in [
        image.getPixel(edge, 0),
        image.getPixel(0, edge),
        image.getPixel(edge, edge),
      ]) {
        expect(
          _luminance(corner),
          closeTo(pad, 0.01),
          reason: 'the margin around the code must be clear of modules',
        );
      }
    });

    test('prints dark modules on light paper whatever the palette holds', () {
      // The default palette draws white modules on a dark card. Printed as
      // they look on screen they are either invisible on white paper or an
      // inverted code, which readers do not decode.
      for (final palette in const [
        (module: Color(0xFFFFFFFF), eye: Color(0xFFFF5963)),
        (module: Color(0xFFF9CF58), eye: Color(0xFFEE8B60)),
        (module: Color(0xFF0F172A), eye: Color(0xFF0F3460)),
      ]) {
        final bytes = TicketRasterExport.qrPngBytes(
          sampleTicket.copyWith(
            dataModuleColor: palette.module,
            eyeColor: palette.eye,
          ),
        );
        final image = img.decodePng(bytes!)!;
        final matrix = matrixFor(sampleTicket.qrData);
        final modules = matrix.moduleCount;

        final module = findModule(matrix, dark: true);
        final background = findModule(matrix, dark: false);
        final inked = centreOf(module.row, module.col, modules, image.width);
        final bare = centreOf(
          background.row,
          background.col,
          modules,
          image.width,
        );

        expect(
          _luminance(image.getPixel(inked.x, inked.y)),
          lessThan(0.4),
          reason: 'a module printed in ${palette.module} is too pale to read',
        );
        expect(
          _luminance(image.getPixel(bare.x, bare.y)),
          greaterThan(0.9),
          reason: 'the field behind the code must stay light',
        );
      }
    });
  });
}
