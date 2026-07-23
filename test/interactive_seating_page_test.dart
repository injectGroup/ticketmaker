import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/core/theme/app_theme.dart';
import 'package:ticket_maker/features/discover/domain/entities/event.dart';
import 'package:ticket_maker/features/generate/presentation/bloc/generate_cubit.dart';
import 'package:ticket_maker/features/seating/domain/seat_status.dart';
import 'package:ticket_maker/features/seating/presentation/bloc/interactive_seating_cubit.dart';
import 'package:ticket_maker/features/seating/presentation/pages/interactive_seating_page.dart';
import 'package:ticket_maker/features/seating/presentation/widgets/seat_button.dart';
import 'package:ticket_maker/features/seating/presentation/widgets/seating_grid.dart';

Event _event() {
  return Event(
    id: 'evt-widget-seating',
    title: 'Map Night',
    venue: 'Hall',
    city: 'Abuja',
    eventAt: DateTime(2026, 8, 1, 20),
    category: 'Concert',
    description: 'Desc',
    host: 'Host',
    priceLabel: '₦2,000',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('legend visible; Proceed disabled until seat selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => GenerateCubit(),
          child: InteractiveSeatingPage(event: _event()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Sold Out'), findsOneWidget);
    expect(find.text('STAGE / FRONT'), findsOneWidget);

    final proceed = find.widgetWithText(FilledButton, 'Proceed to Checkout');
    expect(tester.widget<FilledButton>(proceed).onPressed, isNull);

    final cubit = tester.element(find.byType(SeatingGrid)).read<InteractiveSeatingCubit>();
    final available = cubit.state.seats.firstWhere(
      (s) => s.status == SeatStatus.available,
    );

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is SeatButton && w.seat.id == available.id,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(proceed).onPressed, isNotNull);
    expect(find.textContaining(available.shortCode), findsWidgets);
  });
}
