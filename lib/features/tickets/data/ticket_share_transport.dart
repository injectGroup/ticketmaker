import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'ticket_share_download_stub.dart'
    if (dart.library.js_interop) 'ticket_share_download_web.dart';
import 'ticket_share_image_xfile_stub.dart'
    if (dart.library.io) 'ticket_share_image_xfile_io.dart';

/// Hands finished ticket bytes to the platform.
///
/// Image shares write a temporary PNG so Android/iOS apps receive a real file
/// path. PDF shares stay in memory. Tests replace the implementation.
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
    final xFile = await ticketShareImageXFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
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
