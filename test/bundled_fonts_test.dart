import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_maker/core/theme/app_theme.dart';
import 'package:ticket_maker/features/generate/presentation/widgets/ticket_code_badge.dart';

/// Guards the pre-bundled font assets declared in `pubspec.yaml`.
///
/// Runtime fetching is disabled here, so `google_fonts` must satisfy every
/// variant the app asks for from `assets/fonts/`. If a new call site requests a
/// variant that is not bundled, `google_fonts` throws and these tests fail —
/// which is the signal to add the matching `<Family>-<Variant>.ttf` file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Filenames follow `GoogleFontsFamilyWithVariant.toApiFilenamePrefix()`.
  const List<String> bundledVariants = <String>[
    // Body/labels via readexProTextTheme (w400) and titles/labels (w500).
    'ReadexPro-Regular.ttf',
    'ReadexPro-Medium.ttf',
    // AppTheme titleMedium (w600).
    'ReadexPro-SemiBold.ttf',
    // AppTheme headlineMedium / appBar title (w500) and headlineLarge (w600).
    'Outfit-Medium.ttf',
    'Outfit-SemiBold.ttf',
    // Ticket code + date pills request w600; Space Mono's nearest is w700.
    'SpaceMono-Bold.ttf',
  ];

  test('every declared font variant is bundled as an asset', () async {
    for (final String name in bundledVariants) {
      final ByteData data = await rootBundle.load('assets/fonts/$name');
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: '$name should be bundled under assets/fonts/',
      );
    }
  });

  testWidgets('app theme and ticket text styles need no runtime font fetch', (
    tester,
  ) async {
    // Building AppTheme.light resolves the Readex Pro text theme plus the
    // Outfit overrides; TicketCodeBadge resolves Space Mono.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              final TextTheme text = Theme.of(context).textTheme;
              return ListView(
                children: <Widget>[
                  for (final TextStyle? style in <TextStyle?>[
                    text.displayLarge,
                    text.displayMedium,
                    text.displaySmall,
                    text.headlineLarge,
                    text.headlineMedium,
                    text.headlineSmall,
                    text.titleLarge,
                    text.titleMedium,
                    text.titleSmall,
                    text.bodyLarge,
                    text.bodyMedium,
                    text.bodySmall,
                    text.labelLarge,
                    text.labelMedium,
                    text.labelSmall,
                  ])
                    // Punctuation the UI actually renders; a missing glyph here
                    // is what sends the web engine looking for Noto fallbacks.
                    Text('Aa 09 … • · —', style: style),
                  const TicketCodeBadge(code: '1234-5678-910'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
