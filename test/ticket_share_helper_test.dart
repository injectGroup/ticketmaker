import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_share_helper.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/saved_ticket_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleTicket = Ticket(
    id: 'ticket-share-test',
    headerLabel: 'VIP Pass',
    title: 'Share Capture Concert',
    subtitle: 'National Stadium',
    venue: 'National Stadium',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 18, 20),
    code: '1111-2222-333',
    qrData: 'https://example.com/ticket/share-capture',
    imagePath: '',
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFFFF9800),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );

  testWidgets('capturePngBytes encodes SavedTicketView as non-empty PNG', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SavedTicketView(ticket: sampleTicket),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<int>? bytes;
    await tester.runAsync(() async {
      bytes = await TicketShareHelper.capturePngBytes(boundaryKey);
    });

    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    // PNG magic header.
    expect(bytes!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  testWidgets('capturePngBytes returns null when no ticket card is mounted', (
    tester,
  ) async {
    final detachedKey = GlobalKey();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    Uint8List? bytes = Uint8List(0);
    await tester.runAsync(() async {
      bytes = await TicketShareHelper.capturePngBytes(detachedKey);
    });

    expect(bytes, isNull);
  });

  testWidgets(
    'share composite from boundary is larger than raw event photo alone',
    (tester) async {
      final boundaryKey = GlobalKey();
      // Tiny 1x1 JPEG-ish payload — event photo stand-in (not a full ticket).
      final eventPhoto = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xD9, // minimal JPEG SOI/EOI
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SavedTicketView(
                  ticket: sampleTicket,
                  imageBytes: eventPhoto,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Uint8List? composite;
      await tester.runAsync(() async {
        composite = await TicketShareHelper.captureJpegBytes(boundaryKey);
      });

      expect(composite, isNotNull);
      expect(composite!, isNotEmpty);
      // Full ticket JPEG must not be just the tiny event photo bytes.
      expect(composite!.length, greaterThan(eventPhoto.length));
      expect(find.text('Share Capture Concert'), findsOneWidget);
      expect(find.text('1111-2222-333'), findsOneWidget);
    },
  );

  test('downloadFileNameFor uses Ticket_<id>.png', () {
    expect(
      TicketShareHelper.downloadFileNameFor(sampleTicket),
      'Ticket_ticket-share-test.png',
    );
  });

  testWidgets('composeTicketPngBytes captures on-screen SavedTicketView', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SavedTicketView(ticket: sampleTicket),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold));
    Uint8List? png;
    await tester.runAsync(() async {
      png = await TicketShareHelper.composeTicketPngBytes(
        context,
        sampleTicket,
        boundaryKey: boundaryKey,
      );
    });

    expect(png, isNotNull);
    expect(png!, isNotEmpty);
    expect(png!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  testWidgets('composeTicketPngBytes rasterizes without an on-screen ticket', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => const Text('list'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('list'));
    Uint8List? png;
    await tester.runAsync(() async {
      png = await TicketShareHelper.composeTicketPngBytes(
        context,
        sampleTicket,
      );
    });

    expect(png, isNotNull);
    expect(png!, isNotEmpty);
    expect(png!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
