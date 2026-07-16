import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/app.dart';

void main() {
  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(const TicketMakerApp());
    await tester.pumpAndSettle();

    expect(find.text('Quick Ticket Maker'), findsOneWidget);
    expect(find.text('[ MY TICKET ]'), findsOneWidget);
    expect(find.text('Generate Qr Code'), findsOneWidget);
  });
}
