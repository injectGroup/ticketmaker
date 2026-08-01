import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/core/utils/color_contrast.dart';
import 'package:ticket_maker/features/generate/data/ticket_category_palettes.dart';

void main() {
  test('graduation palette yields white ticket text', () {
    final palette = TicketCategoryPalettes.forCategory(
      TicketCategoryPalettes.graduation,
    );
    expect(
      ColorContrast.onGradient(
        palette.backgroundStart,
        palette.backgroundEnd,
      ),
      ColorContrast.onDark,
    );
  });

  test('wedding palette yields dark ticket text', () {
    final palette = TicketCategoryPalettes.forCategory(
      TicketCategoryPalettes.wedding,
    );
    expect(
      ColorContrast.onGradient(
        palette.backgroundStart,
        palette.backgroundEnd,
      ),
      ColorContrast.onLight,
    );
  });

  test('substantial translucent dark fill still forces white text', () {
    const start = Color(0x5514181B);
    const end = Color(0x55C0C0C0);
    expect(ColorContrast.onGradient(start, end), Colors.white);
  });

  test('low-alpha brand wash uses blended luminance (dark text)', () {
    // Default Generate ticket-style wash: translucent purple → cyan.
    const start = Color(0x354B39EF);
    const end = Color(0x3A39D2C0);
    expect(
      ColorContrast.onGradient(start, end),
      ColorContrast.onLight,
    );
  });

  test('opaque light solid uses dark text', () {
    const fill = Color(0xFFF1F4F8);
    expect(ColorContrast.onGradient(fill, fill), ColorContrast.onLight);
  });

  test('opaque dark solid uses white text', () {
    const fill = Color(0xFF14181B);
    expect(ColorContrast.onGradient(fill, fill), ColorContrast.onDark);
  });

  test('brand dark plum default yields white ticket text', () {
    const fill = Color(0xFF1A1A2E);
    expect(ColorContrast.onGradient(fill, fill), ColorContrast.onDark);
  });

  test('white QR modules get dark plum pad', () {
    expect(
      ColorContrast.qrPadForPattern(Colors.white),
      const Color(0xFF1A1A2E),
    );
  });

  test('dark QR modules get white pad', () {
    expect(
      ColorContrast.qrPadForPattern(const Color(0xFF1A1A2E)),
      Colors.white,
    );
  });

  group('qrInkForPrint', () {
    test('keeps a module colour dark enough to read on paper', () {
      const navy = Color(0xFF0F3460);
      expect(ColorContrast.qrInkForPrint(navy), navy);
    });

    test('swaps in ink for colours that would fade into the page', () {
      for (final pale in const [
        Colors.white,
        Color(0xFFF9CF58), // comedy yellow
        Color(0xFFC9A227), // wedding gold
        Color(0xFF4ECDC4), // birthday teal
      ]) {
        expect(
          ColorContrast.qrInkForPrint(pale),
          ColorContrast.onLight,
          reason: '$pale prints too pale to scan',
        );
      }
    });

    test('judges a translucent colour by how it lands on the page', () {
      // Alpha is lost on paper, so a wash is measured once blended.
      expect(
        ColorContrast.qrInkForPrint(const Color(0x220F172A)),
        ColorContrast.onLight,
      );
    });
  });
}
