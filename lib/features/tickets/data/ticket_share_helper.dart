import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../generate/domain/entities/ticket.dart';
import '../presentation/widgets/saved_ticket_view.dart';
import 'ticket_image_codec.dart';
import 'ticket_share_download_stub.dart'
    if (dart.library.js_interop) 'ticket_share_download_web.dart';

/// Captures a ticket image and opens the native / web share sheet.
class TicketShareHelper {
  TicketShareHelper._();

  static const String _subject = 'My Custom Ticket Design';
  static const String _webFileName = 'ticket.jpg';

  /// Share-sheet anchor rect for iOS/iPadOS popovers.
  static Rect shareOriginFrom(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromLTWH(size.width / 2 - 1, size.height / 2 - 1, 2, 2);
  }

  /// Encodes [boundaryKey]'s [RepaintBoundary] to JPEG bytes.
  static Future<List<int>?> captureJpegBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 1.5,
    int quality = 72,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final jpeg = await uiImageToJpeg(image, quality: quality);
      image.dispose();
      return jpeg;
    } catch (_) {
      return null;
    }
  }

  /// Encodes [boundaryKey]'s [RepaintBoundary] to PNG bytes.
  static Future<List<int>?> capturePngBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 2,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Shares [ticket] as a JPEG (plus caption).
  ///
  /// Web: JPEG [Uint8List] → [XFile.fromData] → [Share.shareXFiles]. Falls
  /// back to Blob download if the Web Share API / share_plus throws
  /// (e.g. LateInitializationError on desktop Chrome).
  static Future<void> share(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Rect? sharePositionOrigin,
    Uint8List? imageBytes,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Preparing share…'),
          duration: Duration(seconds: 2),
        ),
      );

    final origin = sharePositionOrigin ?? shareOriginFrom(context);
    Uint8List? jpegBytes;

    try {
      if (boundaryKey != null) {
        final captured = await captureJpegBytes(boundaryKey);
        if (captured != null && captured.isNotEmpty) {
          jpegBytes = Uint8List.fromList(captured);
        }
      }
      if (!context.mounted) return;

      if (jpegBytes == null || jpegBytes.isEmpty) {
        final png = await _captureViaOverlay(
          context,
          ticket,
          imageBytes: imageBytes,
        );
        if (png != null && png.isNotEmpty) {
          jpegBytes = await compressImageToJpeg(Uint8List.fromList(png));
        }
      }

      if (!context.mounted) return;

      if (jpegBytes != null && jpegBytes.isNotEmpty) {
        await _shareJpegBytes(
          context,
          ticket,
          jpegBytes: jpegBytes,
          origin: origin,
          messenger: messenger,
        );
        return;
      }

      // Text-only fallback when capture produced no image.
      // ignore: deprecated_member_use
      await Share.share(
        ticket.toShareText(),
        subject: _subject,
        sharePositionOrigin: origin,
      );
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
    } catch (e, st) {
      debugPrint('Share failed: $e\n$st');
      if (!context.mounted) return;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not share ticket: $e')),
        );
    }
  }

  /// Shares prepared JPEG bytes. Never touches uninitialized late fields.
  static Future<void> _shareJpegBytes(
    BuildContext context,
    Ticket ticket, {
    required Uint8List jpegBytes,
    required Rect origin,
    required ScaffoldMessengerState? messenger,
  }) async {
    final fileName = kIsWeb ? _webFileName : 'ticket_${ticket.id}.jpg';

    // Build XFile only from in-memory bytes — never read .path on web.
    final xFile = XFile.fromData(
      jpegBytes,
      mimeType: 'image/jpeg',
      name: fileName,
    );

    if (kIsWeb) {
      try {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          text: ticket.toShareText(),
          subject: _subject,
          sharePositionOrigin: origin,
          fileNameOverrides: [fileName],
        );
        if (!context.mounted) return;
        messenger?.hideCurrentSnackBar();
        return;
      } catch (e, st) {
        // Desktop Chrome often throws LateInitializationError / NotAllowedError.
        debugPrint('Share.shareXFiles failed on web, downloading: $e\n$st');
        downloadBytesAsFile(jpegBytes, fileName);
        if (!context.mounted) return;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Ticket image downloaded')),
          );
        return;
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        fileNameOverrides: [fileName],
        text: ticket.toShareText(),
        subject: _subject,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
    if (!context.mounted) return;
    messenger?.hideCurrentSnackBar();
  }

  static Future<List<int>?> _captureViaOverlay(
    BuildContext context,
    Ticket ticket, {
    Uint8List? imageBytes,
  }) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    final width = MediaQuery.sizeOf(context).width.clamp(280.0, 420.0);

    // Nullable instead of `late` so we never read an uninitialized field.
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Align(
              alignment: Alignment.topLeft,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SavedTicketView(
                      ticket: ticket,
                      imageBytes: imageBytes,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final captureContext = boundaryKey.currentContext;
      if (captureContext != null && captureContext.mounted) {
        await _precacheTicketImages(
          captureContext,
          ticket,
          imageBytes: imageBytes,
        );
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return await capturePngBytes(boundaryKey);
    } finally {
      entry.remove();
    }
  }

  static Future<void> _precacheTicketImages(
    BuildContext context,
    Ticket ticket, {
    Uint8List? imageBytes,
  }) async {
    if (!context.mounted) return;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        await precacheImage(MemoryImage(imageBytes), context);
      } catch (_) {}
      return;
    }

    final path = ticket.imagePath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        await precacheImage(NetworkImage(path), context);
      } catch (_) {}
    }
  }
}
