import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';
import 'package:ticket_maker/core/router/app_router.dart';
import 'package:ticket_maker/features/auth/data/auth_repository.dart';
import 'package:ticket_maker/features/discover/domain/location_city_service.dart';
import 'package:ticket_maker/features/generate/presentation/pages/generate_page.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';

Widget buildTestApp({
  LocationCityService? location,
  AuthRepository? authRepository,
}) {
  return TicketMakerApp(
    locationCityService: location ?? FakeLocationCityService('Abuja'),
    authRepository: authRepository,
  );
}

Future<AuthRepository> seedSignedInUser() async {
  final prefs = await SharedPreferences.getInstance();
  final repo = AuthRepository(prefs: prefs);
  await repo.signUp(
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    phone: '+2348000000000',
    password: 'secret1',
    dateOfBirth: DateTime(1990, 1, 1),
    marketingOptIn: false,
  );
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Global GoRouter retains location across tests; reset to Generate.
    appRouter.go(GeneratePage.routePath);
  });

  testWidgets('App opens on Generate home with Generate and Tickets nav', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Quick Ticket Maker'), findsOneWidget);
    expect(find.text('Circu Du Freak'), findsOneWidget);
    expect(find.text('Generate Qr Code'), findsOneWidget);
    expect(find.text('Save Ticket'), findsOneWidget);

    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(buildTestApp());
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

  testWidgets('Guest Save Ticket opens auth gate', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Save Ticket'));
    await tester.tap(find.text('Save Ticket'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Sign in to book'), findsOneWidget);
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

  testWidgets('Clear all confirms and empties Tickets list', (tester) async {
    final ticketJson = {
      'id': 'ticket-clear-test-1',
      'headerLabel': 'VIP',
      'title': 'Clear Me Concert',
      'subtitle': 'Venue',
      'dateLabel': 'Sat, Jul 18',
      'timeLabel': '8:00 PM',
      'eventAt': '2026-07-18T20:00:00.000',
      'code': '1111-2222-333',
      'qrData': 'https://example.com/ticket/clear',
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

    expect(find.text('Clear Me Concert'), findsOneWidget);
    expect(find.byKey(const Key('clear-all-tickets')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-all-tickets')));
    await tester.pumpAndSettle();
    expect(find.text('Clear all tickets?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-clear-all-tickets')));
    await tester.pumpAndSettle();

    expect(find.text('No saved tickets yet'), findsOneWidget);
    expect(find.text('Clear Me Concert'), findsNothing);
    expect(find.text('All tickets cleared'), findsOneWidget);
  });
}
