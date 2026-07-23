import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/discover/domain/entities/event.dart';
import 'package:ticket_maker/features/seating/domain/seat_status.dart';
import 'package:ticket_maker/features/seating/presentation/bloc/interactive_seating_cubit.dart';

Event _event({String priceLabel = '₦8,500'}) {
  return Event(
    id: 'evt-seating-test',
    title: 'Test Concert',
    venue: 'Arena',
    city: 'Abuja',
    eventAt: DateTime(2026, 8, 1, 20),
    category: 'Concert',
    description: 'Desc',
    host: 'Host',
    priceLabel: priceLabel,
  );
}

void main() {
  InteractiveSeatingCubit? cubit;

  tearDown(() async {
    await cubit?.close();
    cubit = null;
  });

  test('parseUnitPrice Free is 0 and digits parse to amount', () {
    expect(InteractiveSeatingCubit.parseUnitPrice('Free'), 0);
    expect(InteractiveSeatingCubit.parseUnitPrice('₦8,500'), 8500);
  });

  test('toggleSeat selects available and ignores soldOut', () {
    cubit = InteractiveSeatingCubit(event: _event());
    final sold = cubit!.state.seats.firstWhere(
      (s) => s.status == SeatStatus.soldOut,
    );
    final available = cubit!.state.seats.firstWhere(
      (s) => s.status == SeatStatus.available,
    );

    cubit!.toggleSeat(sold.id);
    expect(
      cubit!.state.seats.firstWhere((s) => s.id == sold.id).status,
      SeatStatus.soldOut,
    );
    expect(cubit!.state.selectedCount, 0);

    cubit!.toggleSeat(available.id);
    expect(
      cubit!.state.seats.firstWhere((s) => s.id == available.id).status,
      SeatStatus.selected,
    );
    expect(cubit!.state.selectedCount, 1);
    expect(cubit!.state.canCheckout, isTrue);
    expect(cubit!.state.selectedLabels.first, contains('Row'));
  });

  test('totalPrice equals selectedCount times unitPrice', () {
    cubit = InteractiveSeatingCubit(event: _event(priceLabel: '₦1,000'));
    final available = cubit!.state.seats
        .where((s) => s.status == SeatStatus.available)
        .take(2)
        .toList();

    cubit!.toggleSeat(available[0].id);
    cubit!.toggleSeat(available[1].id);

    expect(cubit!.state.selectedCount, 2);
    expect(cubit!.state.unitPrice, 1000);
    expect(cubit!.state.totalPrice, 2000);
    expect(cubit!.state.totalPriceLabel, '₦2000.00');
  });

  test('toggleSeat deselects selected seat', () {
    cubit = InteractiveSeatingCubit(event: _event());
    final available = cubit!.state.seats.firstWhere(
      (s) => s.status == SeatStatus.available,
    );
    cubit!.toggleSeat(available.id);
    cubit!.toggleSeat(available.id);
    expect(
      cubit!.state.seats.firstWhere((s) => s.id == available.id).status,
      SeatStatus.available,
    );
    expect(cubit!.state.canCheckout, isFalse);
  });
}
