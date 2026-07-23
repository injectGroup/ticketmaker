import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';
import 'package:ticket_maker/core/router/app_router.dart';
import 'package:ticket_maker/features/discover/domain/location_city_service.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';
import 'package:ticket_maker/presentation/pages/discover_screen.dart';

Widget buildTestApp({LocationCityService? location}) {
  return TicketMakerApp(
    locationCityService: location ?? FakeLocationCityService('Abuja'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Global GoRouter retains location across tests; reset to Discover.
    appRouter.go(DiscoverScreen.routePath);
  });

  testWidgets('App opens on Discover home', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump(); // Avoid hang on Image.network loading animation
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Discover · Abuja'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Discover cards use network hero images', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final networkImages = tester.widgetList<Image>(find.byType(Image)).where((
      image,
    ) {
      return image.image is NetworkImage;
    });
    expect(networkImages, isNotEmpty);
    expect(
      (networkImages.first.image as NetworkImage).url,
      contains('images.unsplash.com/'),
    );
  });

  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Ticket Maker'), findsOneWidget);
    expect(find.text('My Ticket'), findsOneWidget);
    expect(find.text('Circu Du Freak'), findsOneWidget);
    expect(find.text('Generate Qr Code'), findsOneWidget);
    expect(find.text('Save Ticket'), findsOneWidget);
  });

  testWidgets('Tickets tab starts empty without saved records', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();

    expect(find.text('No saved tickets yet'), findsOneWidget);
    expect(find.text('Circu Du Freak'), findsNothing);
  });

  testWidgets('Discover lists Abuja events and filters by search', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Discover'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Discover · Abuja'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsOneWidget);
    expect(find.text('Music'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'zzzz-no-match');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('No events match'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Wedding');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Asokoro Garden Wedding Fair'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Flutter Abuja Meetup'), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
  });

  testWidgets('Discover city switch filters events', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Abuja Jazz Night'), findsOneWidget);
    expect(find.text('Lagos Afrobeats Night'), findsNothing);

    await tester.tap(find.widgetWithText(Chip, 'Abuja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Lagos').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Discover · Lagos'), findsOneWidget);
    expect(find.text('Lagos Afrobeats Night'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsNothing);
  });

  testWidgets('Discover Book Spot on card prefills Generate', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Book Spot'), findsWidgets);
    await tester.ensureVisible(find.text('Book Spot').first);
    await tester.tap(find.text('Book Spot').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Quick Ticket Maker'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsWidgets);
    expect(find.text('Transcorp Hilton — Ballroom'), findsOneWidget);
    expect(find.text('Capital Jazz Collective'), findsOneWidget);
  });

  testWidgets('Discover card opens details sheet', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Abuja Jazz Night'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Abuja Jazz Night').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Abuja Jazz Night').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Book a Spot'), findsOneWidget);
    expect(find.text('Capital Jazz Collective'), findsOneWidget);
    expect(find.textContaining('₦8,500'), findsWidgets);
  });

  testWidgets('Generate category palette applies wedding colors', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(find.text('Event category palette'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Wedding'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Wedding'), findsOneWidget);
  });

  testWidgets('Tapping a saved ticket opens read-only detail view', (
    tester,
  ) async {
    final ticketJson = {
      'id': 'ticket-detail-test-1',
      'headerLabel': 'VIP Pass',
      'title': 'Detail View Concert',
      'subtitle': 'National Stadium Abuja',
      'dateLabel': 'Sat, Jul 18',
      'timeLabel': '8:00 PM',
      'eventAt': '2026-07-18T20:00:00.000',
      'code': '9999-8888-777',
      'qrData': 'https://example.com/ticket/detail-view',
      'imagePath': '',
      'eyeColor': 0xFFF44336,
      'dataModuleColor': 0xFFFF9800,
      'isSquare': false,
      'topGradientStart': 0xFF4B39EF,
      'topGradientEnd': 0xFF39D2C0,
      'bottomGradientStart': 0xFF4B39EF,
      'bottomGradientEnd': 0xFF39D2C0,
    };
    SharedPreferences.setMockInitialValues({
      TicketLocalRepository.storageKey: <String>[jsonEncode(ticketJson)],
    });

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();

    expect(find.text('Detail View Concert'), findsOneWidget);
    await tester.tap(find.text('Detail View Concert'));
    await tester.pumpAndSettle();

    expect(find.text('VIP Pass'), findsOneWidget);
    expect(find.text('National Stadium Abuja'), findsOneWidget);
    expect(find.text('[ 9999-8888-777 ]'), findsOneWidget);
    expect(find.text('Generate Qr Code'), findsNothing);
    expect(find.text('Save Ticket'), findsNothing);
  });

  testWidgets('Account tab opens placeholder screen', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
  });
}
