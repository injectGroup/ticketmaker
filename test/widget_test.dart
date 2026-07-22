import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(const TicketMakerApp());
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

  testWidgets('Discover and Account tabs open placeholder screens', (
    tester,
  ) async {
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Discover events'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
  });
}
