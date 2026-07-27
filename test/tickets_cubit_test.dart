import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_image_store.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';
import 'package:ticket_maker/features/tickets/presentation/bloc/tickets_cubit.dart';

Ticket _sample({required String imagePath}) {
  return Ticket(
    id: 'default',
    headerLabel: 'VIP',
    title: 'Concert',
    subtitle: 'Venue',
    venue: '',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 18, 20),
    code: '1111-2222',
    qrData: 'https://example.com',
    imagePath: imagePath,
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFFFF9800),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late TicketLocalRepository repository;
  late TicketImageStore imageStore;
  late TicketsCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('tickets_cubit_');
    final imagesDir = Directory('${tempRoot.path}/ticket_images');
    imageStore = TicketImageStore(overrideImagesDirectory: imagesDir);
    repository = TicketLocalRepository();
    cubit = TicketsCubit(repository, imageStore: imageStore);
  });

  tearDown(() async {
    await cubit.close();
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('saveTicket keeps imagePath when persist fails', () async {
    final missing = '${tempRoot.path}/gone.jpg';
    await cubit.saveTicket(_sample(imagePath: missing));

    final saved = cubit.state.tickets.single;
    expect(saved.imagePath, missing);
    expect(cubit.state.message, 'Ticket saved successfully!');
  });

  test('saveTicket stores durable path when file exists', () async {
    final source = File('${tempRoot.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(20, 1));

    await cubit.saveTicket(_sample(imagePath: source.path));
    expect(cubit.state.message, 'Ticket saved successfully!');

    // Image compress + local persist runs in the background.
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final saved = cubit.state.tickets.single;
    expect(saved.imagePath, isNotEmpty);
    expect(File(saved.imagePath).existsSync(), isTrue);
    expect(saved.imagePath.contains('ticket_images'), isTrue);
  });

  test('loadTickets repairs missing path from durable file by id', () async {
    final source = File('${tempRoot.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(10, 2));
    await cubit.saveTicket(_sample(imagePath: source.path));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final id = cubit.state.tickets.single.id;
    final durable = cubit.state.tickets.single.imagePath;

    // Point prefs at a dead path while leaving the durable file in place.
    final broken = cubit.state.tickets.single.copyWith(
      imagePath: '${tempRoot.path}/missing-elsewhere.jpg',
    );
    await repository.saveTickets([broken]);

    await cubit.loadTickets();

    expect(cubit.state.tickets.single.id, id);
    expect(cubit.state.tickets.single.imagePath, durable);
    expect(File(cubit.state.tickets.single.imagePath).existsSync(), isTrue);
  });

  test('clearAllTickets empties list, prefs, and durable images', () async {
    final source = File('${tempRoot.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(12, 3));
    await cubit.saveTicket(_sample(imagePath: source.path));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final durable = cubit.state.tickets.single.imagePath;
    expect(File(durable).existsSync(), isTrue);
    expect((await repository.loadTickets()), hasLength(1));

    await cubit.clearAllTickets();

    expect(cubit.state.tickets, isEmpty);
    expect(cubit.state.message, 'All tickets cleared');
    expect(await repository.loadTickets(), isEmpty);
    expect(File(durable).existsSync(), isFalse);
  });

  test('deleteTickets removes selected tickets and can soft-delete images', () async {
    final source = File('${tempRoot.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(8, 4));
    await cubit.saveTicket(_sample(imagePath: source.path));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await cubit.saveTicket(
      _sample(imagePath: '').copyWith(title: 'Second'),
    );
    expect(cubit.state.tickets, hasLength(2));

    final keepId = cubit.state.tickets.first.id;
    final removeId = cubit.state.tickets.last.id;
    final removePath = cubit.state.tickets.last.imagePath;

    final removed = await cubit.deleteTickets(
      [removeId],
      deleteImages: false,
      message: null,
    );

    expect(removed, hasLength(1));
    expect(removed.single.id, removeId);
    expect(cubit.state.tickets.map((t) => t.id), [keepId]);
    expect(await repository.loadTickets(), hasLength(1));
    if (removePath.isNotEmpty) {
      expect(File(removePath).existsSync(), isTrue);
    }

    await cubit.restoreTickets(removed, atIndex: 1);
    expect(cubit.state.tickets, hasLength(2));
    expect(cubit.state.tickets[1].id, removeId);
  });

  test('repository clearTickets removes storage key', () async {
    await repository.saveTickets([_sample(imagePath: '')]);
    expect(await repository.loadTickets(), hasLength(1));

    await repository.clearTickets();

    expect(await repository.loadTickets(), isEmpty);
  });
}
