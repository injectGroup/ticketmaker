import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_share_helper.dart';
import 'package:ticket_maker/features/tickets/data/ticket_share_transport.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/share_format_dialog.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/saved_ticket_view.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/web_share_options_dialog.dart';

/// Records what the app hands to the platform, so the share workflow can be
/// asserted without a share sheet or a plugin.
class _RecordedShare {
  _RecordedShare({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.text,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String text;

  String get header => String.fromCharCodes(
        bytes.sublist(0, bytes.length < 8 ? bytes.length : 8),
      );
}

class _RecordingTransport implements TicketShareTransport {
  final List<_RecordedShare> shares = <_RecordedShare>[];

  @override
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    shares.add(
      _RecordedShare(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        text: text,
      ),
    );
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    shares.add(
      _RecordedShare(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        text: text,
      ),
    );
  }
}

Ticket _ticket() {
  return Ticket(
    id: 'share-fmt-1',
    headerLabel: 'GUEST PASS',
    title: 'Share Format Concert',
    subtitle: 'VIP Guest Pass',
    venue: 'National Stadium',
    dateLabel: 'Fri, 31 Jul 2026',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 31, 20),
    code: '1111-2222-333',
    qrData: 'https://quick-ticket-maker-sandbox.web.app/verify/1111-2222-333',
    imagePath: '',
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFF2B1B2E),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );
}

/// Hosts the ticket so the share path has a painted boundary to capture.
Widget _host(GlobalKey boundaryKey, Ticket ticket) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SavedTicketView(ticket: ticket),
        ),
      ),
    ),
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late _RecordingTransport transport;

  setUp(() {
    transport = _RecordingTransport();
    TicketShareHelper.transport = transport;
  });

  tearDown(TicketShareHelper.resetTransport);

  group('format chooser', () {
    testWidgets('offers an image and a PDF, and reports the choice', (
      tester,
    ) async {
      TicketShareFormat? choice;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showShareFormatDialog(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('share-format-dialog')), findsOneWidget);
      expect(find.byKey(const Key('share-format-image')), findsOneWidget);
      expect(find.byKey(const Key('share-format-pdf')), findsOneWidget);

      await tester.tap(find.byKey(const Key('share-format-pdf')));
      await tester.pumpAndSettle();
      expect(choice, TicketShareFormat.pdf);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('share-format-image')));
      await tester.pumpAndSettle();
      expect(choice, TicketShareFormat.image);
    });
  });

  group('web share options', () {
    testWidgets('adds a PDF choice beside the image and the link', (
      tester,
    ) async {
      WebShareOption? choice;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showWebShareOptionsDialog(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('web-share-download-ticket')), findsOneWidget);
      expect(find.byKey(const Key('web-share-share-pdf')), findsOneWidget);
      expect(find.byKey(const Key('web-share-copy-link')), findsOneWidget);

      await tester.tap(find.byKey(const Key('web-share-share-pdf')));
      await tester.pumpAndSettle();
      expect(choice, WebShareOption.sharePdf);
    });
  });

  group('shareAsPdf', () {
    testWidgets('hands a PDF document to the platform, named for the ticket', (
      tester,
    ) async {
      final ticket = _ticket();
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(_host(boundaryKey, ticket));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      TicketShareHelper.shareAsPdf(context, ticket);
      await _pumpFor(tester, const Duration(seconds: 2));

      expect(transport.shares, hasLength(1));
      final shared = transport.shares.single;
      expect(shared.mimeType, 'application/pdf');
      expect(shared.fileName, 'Ticket_share-fmt-1.pdf');
      expect(shared.header, startsWith('%PDF-'));
      expect(
        shared.text,
        contains('quick-ticket-maker-sandbox.web.app'),
        reason: 'the caption should still carry the verification link',
      );
    });
  });

  group('shareAsImage', () {
    testWidgets('hands PNG bytes of the whole ticket to the platform', (
      tester,
    ) async {
      final ticket = _ticket();
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(_host(boundaryKey, ticket));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      await tester.runAsync(() async {
        await TicketShareHelper.shareAsImage(
          context,
          ticket,
          boundaryKey: boundaryKey,
        );
      });

      expect(transport.shares, hasLength(1));
      final shared = transport.shares.single;
      expect(shared.mimeType, 'image/png');
      expect(shared.fileName, 'Ticket_share-fmt-1.png');
      expect(
        shared.bytes.take(8).toList(),
        const <int>[137, 80, 78, 71, 13, 10, 26, 10],
        reason: 'PNG magic header',
      );
      expect(shared.text, "You're invited to my event!");
      expect(shared.text, isNot(contains('http://')));
      expect(shared.text, isNot(contains('https://')));
    });
  });

  group('share', () {
    testWidgets('shares a PNG image without asking for a format', (tester) async {
      final ticket = _ticket();
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(_host(boundaryKey, ticket));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      await tester.runAsync(() async {
        await TicketShareHelper.share(
          context,
          ticket,
          boundaryKey: boundaryKey,
        );
      });

      expect(find.byKey(const Key('share-format-dialog')), findsNothing);
      expect(transport.shares, hasLength(1));
      expect(transport.shares.single.mimeType, 'image/png');
      expect(transport.shares.single.text, "You're invited to my event!");
    });

    testWidgets('does not ask for a format when no ticket image is attached', (
      tester,
    ) async {
      final ticket = _ticket();
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(_host(boundaryKey, ticket));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      TicketShareHelper.share(context, ticket, attachTicketImage: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('share-format-dialog')), findsNothing);
    });
  });

  group('PDF share stays in memory', () {
    test('the PDF builder never writes to the file system', () {
      const path = 'lib/features/tickets/data/ticket_pdf_export.dart';
      final source = File(path).readAsStringSync();
      for (final needle in <String>[
        'getTemporaryDirectory',
        'getApplicationDocumentsDirectory',
        'writeAsBytes',
        'dart:io',
      ]) {
        expect(
          source,
          isNot(contains(needle)),
          reason: '$path should build the PDF in memory, but references '
              '"$needle"',
        );
      }
    });
  });

  group('image share uses a physical temp file', () {
    test('native image XFile is written via getTemporaryDirectory', () {
      final source = File(
        'lib/features/tickets/data/ticket_share_image_xfile_io.dart',
      ).readAsStringSync();
      expect(source, contains('getTemporaryDirectory'));
      expect(source, contains('writeAsBytes'));
      expect(source, contains('XFile('));
      expect(source, contains('mimeType:'));
    });
  });
}
