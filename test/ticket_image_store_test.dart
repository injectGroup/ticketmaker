import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_image_store.dart';

void main() {
  late Directory tempRoot;
  late Directory imagesDir;
  late TicketImageStore store;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ticket_image_store_');
    imagesDir = Directory('${tempRoot.path}/ticket_images');
    store = TicketImageStore(overrideImagesDirectory: imagesDir);
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('import copies picker file into durable directory', () async {
    final source = File('${tempRoot.path}/picker_temp.jpg')
      ..writeAsBytesSync(List<int>.filled(16, 7));

    final durable = await store.import(sourcePath: source.path);

    expect(durable, isNotEmpty);
    expect(File(durable).existsSync(), isTrue);
    expect(durable.contains('ticket_images'), isTrue);
    expect(File(durable).readAsBytesSync(), source.readAsBytesSync());
  });

  test('import writes bytes when path is missing', () async {
    final durable = await store.import(
      bytes: Uint8List.fromList(List<int>.filled(12, 9)),
    );

    expect(durable, isNotEmpty);
    expect(File(durable).existsSync(), isTrue);
    expect(File(durable).readAsBytesSync().length, 12);
  });

  test('import returns empty when source is missing', () async {
    final durable = await store.import(
      sourcePath: '${tempRoot.path}/missing.jpg',
    );
    expect(durable, isEmpty);
  });

  test('persistForTicket writes stable ticket id filename', () async {
    final source = File('${tempRoot.path}/draft.png')
      ..writeAsBytesSync(List<int>.filled(8, 3));

    final durable = await store.persistForTicket(
      sourcePath: source.path,
      ticketId: 'ticket-42',
    );

    expect(durable, endsWith('${Platform.pathSeparator}ticket-42.png'));
    expect(File(durable).existsSync(), isTrue);
  });

  test('import is no-op for file already under images dir', () async {
    await imagesDir.create(recursive: true);
    final existing = File('${imagesDir.path}/already.jpg')
      ..writeAsBytesSync(const [1, 2, 3]);

    final durable = await store.import(sourcePath: existing.path);
    expect(durable, existing.absolute.path);
  });

  test('findExistingForTicket locates durable file by id', () async {
    await imagesDir.create(recursive: true);
    final file = File('${imagesDir.path}/ticket-99.jpg')
      ..writeAsBytesSync(const [4, 5, 6]);

    final found = await store.findExistingForTicket('ticket-99');
    expect(found, file.path);
  });
}
