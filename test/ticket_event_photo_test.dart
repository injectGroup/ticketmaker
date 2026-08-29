import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_maker/core/widgets/ticket_event_photo_frame.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/generate/presentation/bloc/generate_cubit.dart';
import 'package:ticket_maker/features/generate/presentation/widgets/ticket_details_section.dart';
import 'package:ticket_maker/features/tickets/data/ticket_network_image.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/saved_ticket_view.dart';

Ticket _ticket() {
  return Ticket(
    id: 'photo-fit-1',
    headerLabel: 'GUEST PASS',
    title: 'Photo Fit Bash',
    subtitle: 'VIP Guest Pass',
    venue: 'Private gathering',
    dateLabel: 'Sat, Aug 29',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 8, 29, 20),
    code: '4458-9833-435',
    qrData: 'https://example.com/verify/4458-9833-435',
    imagePath: '',
    eyeColor: const Color(0xFFE0405B),
    dataModuleColor: const Color(0xFF14181B),
    isSquare: true,
    topGradientStart: const Color(0xFF1A1A2E),
    topGradientEnd: const Color(0xFF1A1A2E),
    bottomGradientStart: const Color(0xFF1A1A2E),
    bottomGradientEnd: const Color(0xFF1A1A2E),
  );
}

/// Tall red PNG so a stretching slot would squash it; cover must crop instead.
Uint8List _tallPng() {
  final image = img.Image(width: 8, height: 80, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(200, 24, 24));
  return Uint8List.fromList(img.encodePng(image));
}

void _expectCoveredPhotoSlot(WidgetTester tester) {
  expect(find.byKey(TicketEventPhotoFrame.frameKey), findsOneWidget);
  final frameSize = tester.getSize(find.byKey(TicketEventPhotoFrame.frameKey));
  expect(frameSize.width, TicketEventPhotoFrame.width);
  expect(frameSize.height, TicketEventPhotoFrame.height);
  expect(
    frameSize.width / frameSize.height,
    closeTo(TicketEventPhotoFrame.aspectRatio, 0.01),
  );

  final photo = tester.widget<Image>(find.byType(Image));
  expect(photo.fit, BoxFit.cover);
  expect(photo.alignment, Alignment.center);

  expect(
    find.descendant(
      of: find.byKey(TicketEventPhotoFrame.frameKey),
      matching: find.byType(Center),
    ),
    findsNothing,
    reason: 'Center around the photo prevents cover from filling the slot',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('network ticket photos default to BoxFit.cover', () {
    const widget = TicketCorsSafeNetworkImage(
      url: 'https://example.com/photo.jpg',
    );
    expect(widget.fit, BoxFit.cover);
  });

  testWidgets('saved ticket photo covers a clipped 3:2 frame', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SavedTicketView(
              ticket: _ticket(),
              imageBytes: _tallPng(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectCoveredPhotoSlot(tester);
  });

  testWidgets('generate ticket photo covers a clipped 3:2 frame', (
    tester,
  ) async {
    final cubit = GenerateCubit();
    addTearDown(cubit.close);
    final ticket = cubit.state.ticket;
    final title = TextEditingController(text: ticket.title);
    final subtitle = TextEditingController(text: ticket.subtitle);
    final venue = TextEditingController(text: ticket.venue);
    addTearDown(title.dispose);
    addTearDown(subtitle.dispose);
    addTearDown(venue.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider.value(
              value: cubit,
              child: TicketDetailsSection(
                ticket: ticket,
                titleController: title,
                subtitleController: subtitle,
                venueController: venue,
                imageBytes: _tallPng(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectCoveredPhotoSlot(tester);
  });
}
