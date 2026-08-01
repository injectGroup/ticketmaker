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

  /// The QR image these tests read is the one the PDF prints and the shared
  /// PNG carries, so a code that is wrong or unreadable here is a guest
  /// turned away at the door.
  group('qrPngBytes', () {
    QrImage matrixFor(String data) => QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        );

    /// The pixels module ([row], [col]) owns, given the quiet zone the
    /// renderer reserves on all four sides.
    ({int left, int top, int right, int bottom, int centreX, int centreY})
        cellOf(int row, int col, int modules, int side) {
      final margin = (4 * side / (modules + 8)).floor();
      final cell = (side - margin * 2) / modules;
      return (
        left: margin + (col * cell).round(),
        top: margin + (row * cell).round(),
        right: margin + ((col + 1) * cell).round() - 1,
        bottom: margin + ((row + 1) * cell).round() - 1,
        centreX: margin + ((col + 0.5) * cell).floor(),
        centreY: margin + ((row + 0.5) * cell).floor(),
      );
    }

    /// Where module ([row], [col]) was drawn.
    ({int x, int y}) centreOf(int row, int col, int modules, int side) {
      final cell = cellOf(row, col, modules, side);
      return (x: cell.centreX, y: cell.centreY);
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

    // 150px is the size the shared ticket PNG draws at, where the cells are
    // only a few pixels wide and any overspill from one module rubs out the
    // light one beside it.
    for (final pixels in const [150, 512]) {
      test('paints the payload module for module at ${pixels}px', () {
        final bytes = TicketRasterExport.qrPngBytes(
          sampleTicket,
          pixels: pixels,
        );
        expect(bytes, isNotNull);

        final image = img.decodePng(bytes!);
        expect(image, isNotNull);

        final matrix = matrixFor(sampleTicket.qrData);
        final modules = matrix.moduleCount;

        // Modules are drawn in the guest's colours — data and finder squares
        // in different ones — so a module counts as drawn when it is anything
        // other than the field behind it.
        final field = image!.getPixel(0, 0);
        bool isField(int x, int y) {
          final pixel = image.getPixel(x, y);
          return pixel.r == field.r &&
              pixel.g == field.g &&
              pixel.b == field.b;
        }

        final wrong = <String>[];
        for (var row = 0; row < modules; row++) {
          for (var col = 0; col < modules; col++) {
            final cell = cellOf(row, col, modules, image.width);
            if (matrix.isDark(row, col)) {
              if (isField(cell.centreX, cell.centreY)) wrong.add('$row,$col');
              continue;
            }
            // A light module has to be clear across its whole cell, not just
            // at the middle: a neighbour that spills over even a pixel is what
            // rubs the code out at small sizes.
            for (var y = cell.top; y <= cell.bottom; y++) {
              for (var x = cell.left; x <= cell.right; x++) {
                if (!isField(x, y)) {
                  wrong.add('$row,$col');
                  y = cell.bottom;
                  break;
                }
              }
            }
          }
        }
        expect(
          wrong,
          isEmpty,
          reason: 'the picture must be the payload, not decoration: '
              '${wrong.length} of ${modules * modules} modules are wrong',
        );
      });
    }

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

    test('draws dark modules on a light field whatever the palette holds', () {
      // The default palette asks for white modules on a dark card. Drawn that
      // way the code is inverted, which readers do not decode, and on paper
      // it is not even visible.
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

    test('the shared ticket PNG carries the same readable code', () async {
      final bytes = await TicketRasterExport.toPngBytes(sampleTicket);
      final ticket = img.decodePng(bytes!)!;

      // The code is the only wide block of the light field on the card, so
      // its first full row is the top-left corner of the block.
      ({int x, int y})? corner;
      for (var y = 0; y < ticket.height && corner == null; y++) {
        var run = 0;
        for (var x = 0; x < ticket.width; x++) {
          final pixel = ticket.getPixel(x, y);
          if (pixel.r == 255 && pixel.g == 255 && pixel.b == 255) {
            run++;
            if (run >= 120) {
              corner = (x: x - run + 1, y: y);
              break;
            }
          } else {
            run = 0;
          }
        }
      }
      expect(
        corner,
        isNotNull,
        reason: 'the shared ticket shows no light field for a code to sit on',
      );

      const side = 150;
      final matrix = matrixFor(sampleTicket.qrData);
      final modules = matrix.moduleCount;
      final wrong = <String>[];
      for (var row = 0; row < modules; row++) {
        for (var col = 0; col < modules; col++) {
          final at = centreOf(row, col, modules, side);
          final pixel = ticket.getPixel(corner!.x + at.x, corner.y + at.y);
          final drawn = pixel.r != 255 || pixel.g != 255 || pixel.b != 255;
          if (drawn != matrix.isDark(row, col)) wrong.add('$row,$col');
        }
      }
      expect(
        wrong,
        isEmpty,
        reason: 'the code on the shared image must be the payload: '
            '${wrong.length} of ${modules * modules} modules are wrong',
      );
    });
  });
}
