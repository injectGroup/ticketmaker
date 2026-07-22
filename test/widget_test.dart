import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';

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

  testWidgets('Account tab opens placeholder screen', (tester) async {
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
  });
}
