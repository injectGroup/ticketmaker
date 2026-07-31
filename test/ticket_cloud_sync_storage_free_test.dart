import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/data/ticket_cloud_sync.dart';

void main() {
  group('TicketCloudSync Storage-free helpers', () {
    test('isFirebaseStorageUrl detects Storage hosts', () {
      expect(
        TicketCloudSync.isFirebaseStorageUrl(
          'https://firebasestorage.googleapis.com/v0/b/x/o/y',
        ),
        isTrue,
      );
      expect(
        TicketCloudSync.isFirebaseStorageUrl(
          'https://quick-ticket-maker-sandbox.firebasestorage.app/v0/b/x',
        ),
        isTrue,
      );
      expect(TicketCloudSync.isFirebaseStorageUrl('gs://bucket/obj'), isTrue);
      expect(
        TicketCloudSync.isFirebaseStorageUrl('https://example.com/a.jpg'),
        isFalse,
      );
      expect(
        TicketCloudSync.isFirebaseStorageUrl('data:image/jpeg;base64,abc'),
        isFalse,
      );
    });

    test('jpegBytesToDataUrl embeds Base64 under budget', () {
      final jpeg = Uint8List.fromList(List<int>.filled(32, 1));
      final url = TicketCloudSync.jpegBytesToDataUrl(jpeg);
      expect(url, isNotNull);
      expect(url!, startsWith('data:image/jpeg;base64,'));
      expect(base64Decode(url.split(',').last), jpeg);
    });
  });
}
