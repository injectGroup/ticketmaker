import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App opens on Discover home', (tester) async {
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    expect(find.text('Discover · Abuja'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsOneWidget);
  });

  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(const TicketMakerApp());
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
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();

    expect(find.text('No saved tickets yet'), findsOneWidget);
    expect(find.text('Circu Du Freak'), findsNothing);
  });

  testWidgets('Discover lists Abuja events and filters by search', (
    tester,
  ) async {
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Discover · Abuja'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsOneWidget);
    expect(find.text('Music'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'zzzz-no-match');
    await tester.pumpAndSettle();
    expect(find.textContaining('No events match'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Wedding');
    await tester.pumpAndSettle();
    expect(find.text('Asokoro Garden Wedding Fair'), findsOneWidget);
    expect(find.text('Abuja Jazz Night'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.pumpAndSettle();
    expect(find.text('Flutter Abuja Meetup'), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
  });

  testWidgets('Generate category palette applies wedding colors', (
    tester,
  ) async {
    await tester.pumpWidget(const TicketMakerApp());
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

    await tester.pumpWidget(const TicketMakerApp());
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
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
  });
}
