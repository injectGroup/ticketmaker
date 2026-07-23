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
}
