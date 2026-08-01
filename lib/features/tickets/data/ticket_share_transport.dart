import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'ticket_share_download_stub.dart'
    if (dart.library.js_interop) 'ticket_share_download_web.dart';

/// Hands finished ticket bytes to the platform.
///
/// Everything crosses this boundary as bytes held in memory — no ticket is
/// written to device storage on the way to the share sheet. Tests replace the
/// implementation to assert what would have been shared.
abstract class TicketShareTransport {
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  });

  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  });
}

/// Native share sheet, or the Web Share API with a browser download fallback.
class PlatformTicketShareTransport implements TicketShareTransport {
  const PlatformTicketShareTransport();

  @override
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String text,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'application/pdf',
                name: fileName,
              ),
            ],
            fileNameOverrides: [fileName],
            text: text,
            subject: subject,
            downloadFallbackEnabled: true,
          ),
        );
      } catch (e, st) {
        // Browsers without the Web Share API (or without file support) land
        // here; a plain download still gets the guest their ticket.
        debugPrint('Web PDF share unavailable, downloading instead: $e\n$st');
        downloadBytesAsFile(bytes, fileName, mimeType: 'application/pdf');
      }
      return;
    }

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
      subject: subject,
      bounds: sharePositionOrigin,
    );
  }
}
