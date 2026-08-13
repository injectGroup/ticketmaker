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

  test('ticket ID tokens are dark ink on opaque white', () {
    expect(ColorContrast.ticketIdInk, const Color(0xFF1A1A1A));
    expect(ColorContrast.ticketIdField, const Color(0xFFFFFFFF));
    expect(ColorContrast.ticketIdInk.computeLuminance(), lessThan(0.05));
    expect(ColorContrast.ticketIdField.computeLuminance(), greaterThan(0.99));
  });

  group('qrInk', () {
    test('keeps a module colour dark enough to read', () {
      const navy = Color(0xFF0F3460);
      expect(ColorContrast.qrInk(navy), navy);
    });

    test('swaps in ink for colours that would fade into the field', () {
      for (final pale in const [
        Colors.white,
        Color(0xFFF9CF58), // comedy yellow
        Color(0xFFC9A227), // wedding gold
        Color(0xFF4ECDC4), // birthday teal
      ]) {
        expect(
          ColorContrast.qrInk(pale),
          ColorContrast.onLight,
          reason: '$pale is too pale to scan',
        );
      }
    });

    test('judges a translucent colour by how it lands on the field', () {
      // Alpha is lost on paper, so a wash is measured once blended.
      expect(
        ColorContrast.qrInk(const Color(0x220F172A)),
        ColorContrast.onLight,
      );
    });
  });
}
