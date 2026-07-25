import 'dart:async';
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

/// Captures a ticket image and opens the native share sheet (or downloads on web).
class TicketShareHelper {
  TicketShareHelper._();

  static const String _subject = 'My Custom Ticket Design';
  static const String _webFileName = 'ticket.jpg';
  static const String _fallbackShareText = 'Check out my event ticket!';

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

  /// Encodes [boundaryKey]'s [RepaintBoundary] to JPEG bytes in memory.
  static Future<Uint8List?> captureJpegBytes(
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
      if (jpeg == null || jpeg.isEmpty) return null;
      return jpeg;
    } catch (e, st) {
      debugPrint('captureJpegBytes failed: $e\n$st');
      return null;
    }
  }

  /// Encodes [boundaryKey]'s [RepaintBoundary] to PNG bytes in memory.
  static Future<Uint8List?> capturePngBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 2,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (!boundary.hasSize ||
        boundary.size.width <= 0 ||
        boundary.size.height <= 0) {
      return null;
    }
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } catch (e, st) {
      debugPrint('capturePngBytes failed: $e\n$st');
      return null;
    }
  }

  /// Shares [ticket] as a JPEG (plus caption on native).
  ///
  /// Prefers cached [imageBytes] (list items are not painted as tickets), then
  /// an on-screen [boundaryKey], then an offscreen [SavedTicketView] capture.
  ///
  /// **Web:** tries [Share.shareXFiles]; on failure / cancel / unsupported,
  /// falls back to an HTML blob download of `ticket.jpg`.
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
      jpegBytes = await _prepareTicketJpeg(
        context,
        ticket,
        boundaryKey: boundaryKey,
        imageBytes: imageBytes,
      );
      if (!context.mounted) return;

      if (jpegBytes == null || jpegBytes.isEmpty) {
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not prepare ticket image to share.'),
            ),
          );
        return;
      }

      if (kIsWeb) {
        await _shareOrDownloadWeb(
          context,
          jpegBytes,
          ticket: ticket,
          origin: origin,
          messenger: messenger,
        );
        return;
      }

      final shareText = _shareTextFor(ticket);
      const fileName = _webFileName;
      final xFile = XFile.fromData(
        jpegBytes,
        mimeType: 'image/jpeg',
        name: fileName,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          fileNameOverrides: [fileName],
          text: shareText,
          subject: _subject,
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
    } catch (e, st) {
      debugPrint('Share failed: $e\n$st');
      if (!context.mounted) return;
      if (kIsWeb && jpegBytes != null && jpegBytes.isNotEmpty) {
        downloadBytesAsFile(jpegBytes, _webFileName);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Ticket image downloaded')),
          );
        return;
      }
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Could not prepare ticket image to share.'
                  : 'Could not share ticket. Try again.',
            ),
          ),
        );
    }
  }

  static String _shareTextFor(Ticket ticket) {
    try {
      final text = ticket.toShareText().trim();
      return text.isEmpty ? _fallbackShareText : text;
    } catch (_) {
      return _fallbackShareText;
    }
  }

  /// Web: attempt share_plus file share; always fall back to blob download.
  static Future<void> _shareOrDownloadWeb(
    BuildContext context,
    Uint8List jpegBytes, {
    required Ticket ticket,
    required Rect origin,
    ScaffoldMessengerState? messenger,
  }) async {
    var shared = false;
    try {
      final xFile = XFile.fromData(
        jpegBytes,
        mimeType: 'image/jpeg',
        name: _webFileName,
      );
      // shareXFiles is the Web Share API path when the browser supports it.
      await Share.shareXFiles(
        [xFile],
        text: _shareTextFor(ticket),
        subject: _subject,
        sharePositionOrigin: origin,
      );
      shared = true;
    } catch (e, st) {
      debugPrint('Web Share.shareXFiles failed, downloading: $e\n$st');
    }

    if (!context.mounted) return;

    if (!shared) {
      downloadBytesAsFile(jpegBytes, _webFileName);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Ticket image downloaded')),
        );
      return;
    }

    messenger?.hideCurrentSnackBar();
  }

  /// Builds JPEG bytes for share.
  ///
  /// Order: on-screen [boundaryKey] (detail) → session [imageBytes] (list) →
  /// offscreen [SavedTicketView] → network `ticket.imagePath` last resort.
  static Future<Uint8List?> _prepareTicketJpeg(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Uint8List? imageBytes,
  }) async {
    try {
      if (boundaryKey != null) {
        final captured = await captureJpegBytes(boundaryKey);
        if (captured != null && captured.isNotEmpty) return captured;
      }

      // List cards are not painted as tickets — prefer session photo bytes.
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fromCache = await compressImageToJpeg(imageBytes);
        if (fromCache.isNotEmpty) return fromCache;
      }

      if (!context.mounted) return null;

      final png = await _captureViaOverlay(
        context,
        ticket,
        imageBytes: imageBytes,
      );
      if (png != null && png.isNotEmpty) {
        return await compressImageToJpeg(png);
      }

      final fromUrl = await _bytesFromNetworkPath(ticket.imagePath);
      if (fromUrl != null && fromUrl.isNotEmpty) {
        return await compressImageToJpeg(fromUrl);
      }
      return null;
    } catch (e, st) {
      debugPrint('Ticket JPEG prepare failed: $e\n$st');
      return null;
    }
  }

  /// Download bytes from an http(s) [path], or null.
  static Future<Uint8List?> _bytesFromNetworkPath(String path) async {
    final trimmed = path.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return null;
    }

    try {
      final provider = NetworkImage(trimmed);
      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (Object e, StackTrace? st) {
          if (!completer.isCompleted) {
            completer.completeError(e, st);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final image = await completer.future.timeout(
        const Duration(seconds: 8),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } catch (e, st) {
      debugPrint('Could not load ticket.imagePath bytes: $e\n$st');
      return null;
    }
  }

  /// Offscreen full-opacity ticket render (avoids near-zero Opacity paint skips).
  static Future<Uint8List?> _captureViaOverlay(
    BuildContext context,
    Ticket ticket, {
    Uint8List? imageBytes,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    final width = MediaQuery.sizeOf(context).width.clamp(280.0, 420.0);

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: -10000,
          top: 0,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: 0,
                  maxHeight: double.infinity,
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
      await Future<void>.delayed(const Duration(milliseconds: 120));
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
