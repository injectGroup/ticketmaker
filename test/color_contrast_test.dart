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

  test('opaque dark stop forces white even when translucent mid is light', () {
    const start = Color(0x5514181B);
    const end = Color(0x55C0C0C0);
    expect(ColorContrast.onGradient(start, end), Colors.white);
  });
}
