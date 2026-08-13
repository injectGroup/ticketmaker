import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_maker/core/theme/app_theme.dart';
import 'package:ticket_maker/core/utils/color_contrast.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/generate/presentation/widgets/ticket_code_badge.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/saved_ticket_view.dart';

Ticket _darkTicket() {
  return Ticket(
    id: 'ticket-id-contrast',
    headerLabel: 'GUEST PASS',
    title: 'High Contrast Bash',
    subtitle: 'VIP Guest Pass',
    venue: 'Private gathering',
    dateLabel: 'Thu, Aug 13',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 8, 13, 20),
    code: '4458-9833-435',
    qrData: 'https://example.com/verify/4458-9833-435',
    imagePath: '',
    eyeColor: const Color(0xFFE0405B),
    dataModuleColor: const Color(0xFF14181B),
    isSquare: true,
    topGradientStart: AppColors.brandDarkPlum,
    topGradientEnd: AppColors.brandDarkPlum,
    bottomGradientStart: AppColors.brandDarkPlum,
    bottomGradientEnd: AppColors.brandDarkPlum,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ticket ID code is bold dark ink on a solid white pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketCodeBadge(code: '4458-9833-435'),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('4458-9833-435'));
    expect(text.style?.color, ColorContrast.ticketIdInk);
    expect(text.style?.fontWeight, FontWeight.w700);

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TicketCodeBadge),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, ColorContrast.ticketIdField);
    expect(material.color?.a, 1.0);
  });

  testWidgets('saved tickets keep high-contrast ID on a dark card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SavedTicketView(ticket: _darkTicket()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('4458-9833-435'));
    expect(text.style?.color, ColorContrast.ticketIdInk);
    expect(text.style?.fontWeight, FontWeight.w700);

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TicketCodeBadge),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, Colors.white);
  });
}
