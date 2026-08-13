import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_share_image_xfile_io.dart';

void main() {
  test('writes PNG bytes to a temp file and returns a path-based XFile', () async {
    final dir = await Directory.systemTemp.createTemp('ticket-share-image-');
    addTearDown(() => dir.delete(recursive: true));

    final png = Uint8List.fromList(const <int>[
      137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3,
    ]);

    final xFile = await ticketShareImageXFile(
      bytes: png,
      fileName: 'Ticket_share-fmt-1.png',
      mimeType: 'image/png',
      temporaryDirectoryPath: dir.path,
    );

    expect(xFile.mimeType, 'image/png');
    expect(xFile.name, 'Ticket_share-fmt-1.png');
    expect(
      xFile.path,
      '${dir.path}${Platform.pathSeparator}Ticket_share-fmt-1.png',
    );
    expect(File(xFile.path).existsSync(), isTrue);
    expect(await File(xFile.path).readAsBytes(), png);
  });
}
