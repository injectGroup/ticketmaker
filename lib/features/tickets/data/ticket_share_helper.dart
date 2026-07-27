import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  static const String _prepareFailedMessage =
      'Could not prepare ticket image to share.';
  static const String _shareFailedMessage =
      'Could not share ticket. Try again.';

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
    try {
      final context = boundaryKey.currentContext;
      if (context == null) return null;
      var boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      if (!boundary.hasSize ||
          boundary.size.width <= 0 ||
          boundary.size.height <= 0) {
        return null;
      }
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Re-check after yield — context may have detached.
        if (boundaryKey.currentContext == null) return null;
        boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null ||
            !boundary.hasSize ||
            boundary.size.width <= 0 ||
            boundary.size.height <= 0) {
          return null;
        }
      }
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
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
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

  /// Shares [ticket] as a JPEG when a painted [boundaryKey] or [imageBytes]
  /// is available; otherwise shares/copies the ticket text or link.
  ///
  /// List cards pass [allowOffscreenCapture] `false` — they do not paint a
  /// full ticket [RepaintBoundary], so JPEG capture is skipped to avoid
  /// web [LateInitializationError] from offscreen `toImage`.
  ///
  /// **Web:** tries Web Share via [SharePlus]; on failure / unsupported,
  /// falls back to an HTML blob download of `ticket.jpg`, then copying a
  /// shareable URL if image bytes are unavailable.
  static Future<void> share(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Rect? sharePositionOrigin,
    Uint8List? imageBytes,
    bool allowOffscreenCapture = true,
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
        allowOffscreenCapture: allowOffscreenCapture,
      );
      if (!context.mounted) return;

      if (jpegBytes == null || jpegBytes.isEmpty) {
        await _shareTextOrCopyLink(
          context,
          ticket,
          origin: origin,
          messenger: messenger,
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
      // Catch Exception and Error (e.g. LateInitializationError).
      debugPrint('Share failed: $e\n$st');
      if (!context.mounted) return;

      if (kIsWeb) {
        if (jpegBytes != null && jpegBytes.isNotEmpty) {
          try {
            downloadBytesAsFile(jpegBytes, _webFileName);
            messenger
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Ticket image downloaded')),
              );
            return;
          } catch (downloadError, downloadSt) {
            debugPrint('Web download fallback failed: $downloadError\n$downloadSt');
          }
        }
        await _shareTextOrCopyLink(
          context,
          ticket,
          origin: origin,
          messenger: messenger,
        );
        return;
      }

      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_friendlyErrorMessage(e))),
        );
    }
  }

  /// List / no-image path: native share sheet with text, or clipboard on web.
  static Future<void> _shareTextOrCopyLink(
    BuildContext context,
    Ticket ticket, {
    required Rect origin,
    ScaffoldMessengerState? messenger,
  }) async {
    final text = _linkOrShareText(ticket);

    if (kIsWeb) {
      final copied = await _copyShareableFallback(ticket);
      if (!context.mounted) return;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              copied
                  ? 'Ticket link copied to clipboard'
                  : _prepareFailedMessage,
            ),
          ),
        );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: _subject,
          sharePositionOrigin: origin,
        ),
      );
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
    } catch (e, st) {
      debugPrint('Text share failed: $e\n$st');
      if (!context.mounted) return;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(_shareFailedMessage)),
        );
    }
  }

  static String _linkOrShareText(Ticket ticket) {
    final qr = ticket.qrData.trim();
    if (qr.startsWith('http://') || qr.startsWith('https://')) {
      final caption = _shareTextFor(ticket);
      return '$caption\n$qr';
    }
    return _shareTextFor(ticket);
  }

  /// Never surface raw LateInitializationError / pigeon strings to users.
  static String _friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('LateInitializationError') ||
        text.contains('LateInitialization') ||
        text.contains('Null check operator')) {
      return kIsWeb ? _prepareFailedMessage : _shareFailedMessage;
    }
    return kIsWeb ? _prepareFailedMessage : _shareFailedMessage;
  }

  static String _shareTextFor(Ticket ticket) {
    try {
      final text = ticket.toShareText().trim();
      return text.isEmpty ? _fallbackShareText : text;
    } catch (_) {
      return _fallbackShareText;
    }
  }

  /// Prefer QR / ticket URL; otherwise share caption text.
  static Future<bool> _copyShareableFallback(Ticket ticket) async {
    try {
      final qr = ticket.qrData.trim();
      final payload = (qr.startsWith('http://') || qr.startsWith('https://'))
          ? qr
          : _shareTextFor(ticket);
      if (payload.isEmpty) return false;
      await Clipboard.setData(ClipboardData(text: payload));
      return true;
    } catch (e, st) {
      debugPrint('Clipboard share fallback failed: $e\n$st');
      return false;
    }
  }

  /// Web: attempt share_plus file share; fall back to blob download.
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
      // Web Share API when supported; may throw LateInitializationError.
      // Equivalent to legacy Share.shareXFiles with downloadFallbackEnabled.
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          fileNameOverrides: const [_webFileName],
          text: _shareTextFor(ticket),
          subject: _subject,
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
      shared = result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.unavailable;
    } catch (e, st) {
      debugPrint('Web SharePlus.share failed, downloading: $e\n$st');
      shared = false;
    }

    if (!context.mounted) return;

    if (!shared) {
      try {
        downloadBytesAsFile(jpegBytes, _webFileName);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Ticket image downloaded')),
          );
      } catch (e, st) {
        debugPrint('Blob download failed: $e\n$st');
        final copied = await _copyShareableFallback(ticket);
        if (!context.mounted) return;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                copied
                    ? 'Ticket link copied to clipboard'
                    : _prepareFailedMessage,
              ),
            ),
          );
      }
      return;
    }

    messenger?.hideCurrentSnackBar();
  }

  /// Builds JPEG bytes for share.
  ///
  /// Order: on-screen [boundaryKey] (when context is mounted) → session
  /// [imageBytes] → optional offscreen [SavedTicketView] → network path.
  ///
  /// When [allowOffscreenCapture] is false (My Tickets list cards), skips
  /// offscreen `toImage` entirely — list rows have no ticket RepaintBoundary.
  static Future<Uint8List?> _prepareTicketJpeg(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Uint8List? imageBytes,
    bool allowOffscreenCapture = true,
  }) async {
    try {
      if (boundaryKey != null && boundaryKey.currentContext != null) {
        final captured = await captureJpegBytes(boundaryKey);
        if (captured != null && captured.isNotEmpty) return captured;
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fromCache = await compressImageToJpeg(imageBytes);
        if (fromCache.isNotEmpty) return fromCache;
      }

      // List summary cards: do not invent an offscreen RepaintBoundary.
      if (!allowOffscreenCapture) {
        return null;
      }

      // Offscreen capture is unreliable on Flutter Web (LateInitializationError).
      if (kIsWeb) {
        return null;
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
      // Nullable — never use `late` here (sync callbacks can race assignment).
      ImageStreamListener? listener;
      listener = ImageStreamListener(
        (info, _) {
          final active = listener;
          if (active != null) stream.removeListener(active);
          if (!completer.isCompleted) completer.complete(info.image);
        },
        onError: (Object e, StackTrace? st) {
          final active = listener;
          if (active != null) stream.removeListener(active);
          if (!completer.isCompleted) {
            completer.completeError(e, st);
          }
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

    OverlayEntry? entry;
    entry = OverlayEntry(
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
