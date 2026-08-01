import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ticket_maker/core/utils/color_contrast.dart';
import 'package:ticket_maker/features/generate/presentation/widgets/generate_qr_code.dart';

/// The ticket's palette reaches the code only as far as a reader can still
/// follow it. Drawn in the palette's own colours the default code is white on
/// dark plum, which readers do not decode.
Future<QrImageView> _pump(
  WidgetTester tester, {
  required Color modules,
  required Color eyes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GenerateQrCode(
          data: 'https://ticketmaker.app/verify/tkt-1',
          eyeStyleColor: eyes,
          dataModuleStyleColor: modules,
          isSquare: false,
        ),
      ),
    ),
  );
  return tester.widget<QrImageView>(find.byType(QrImageView));
}

void main() {
  testWidgets('draws a pale palette in ink on a light field', (tester) async {
    final qr = await _pump(
      tester,
      modules: Colors.white,
      eyes: Colors.white,
    );

    expect(qr.backgroundColor, ColorContrast.qrField);
    expect(qr.dataModuleStyle.color, ColorContrast.onLight);
    expect(qr.eyeStyle.color, ColorContrast.onLight);
  });

  testWidgets('keeps a colour dark enough to scan', (tester) async {
    const brandPink = Color(0xFFE0405B);
    final qr = await _pump(
      tester,
      modules: const Color(0xFF0F3460),
      eyes: brandPink,
    );

    expect(qr.dataModuleStyle.color, const Color(0xFF0F3460));
    expect(qr.eyeStyle.color, brandPink);
  });

  testWidgets('a caller can still name the field behind the code',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GenerateQrCode(
            data: 'x',
            eyeStyleColor: Colors.black,
            dataModuleStyleColor: Colors.black,
            isSquare: true,
            backgroundColor: Color(0xFFFFF8E7),
          ),
        ),
      ),
    );

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, const Color(0xFFFFF8E7));
  });
}
