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

  static const String _subject = 'Your personal event ticket';
  static const String _webFileName = 'ticket.jpg';
  static const String _fallbackShareText =
      "You're invited — open your personal guest ticket!";
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
  /// Returns null on any failure (including Flutter Web LateInitializationError).
  static Future<Uint8List?> captureJpegBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 1.5,
    int quality = 72,
  }) async {
    try {
      final boundary = _mountedRepaintBoundary(boundaryKey);
      if (boundary == null) return null;

      RenderRepaintBoundary? ready = boundary;
      if (ready.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        ready = _mountedRepaintBoundary(boundaryKey);
        if (ready == null) return null;
      }

      final image = await ready.toImage(pixelRatio: pixelRatio);
      final jpeg = await uiImageToJpeg(image, quality: quality);
      image.dispose();
      if (jpeg == null || jpeg.isEmpty) return null;
      return jpeg;
    } catch (e, st) {
      // Catch Exception and Error (e.g. LateInitializationError from toImage).
      final message = e.toString();
      if (!message.contains('LateInitializationError') &&
          !message.contains('LateInitialization')) {
        debugPrint('captureJpegBytes failed: $e\n$st');
      }
      return null;
    }
  }

  /// Encodes [boundaryKey]'s [RepaintBoundary] to PNG bytes in memory.
  ///
  /// Returns `null` when the key is not attached, the boundary is missing /
  /// still painting, or capture fails — never throws.
  ///
  /// No `late` locals — every render/image/byte reference is nullable and
  /// checked before use.
  static Future<Uint8List?> capturePngBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 2,
  }) async {
    try {
      if (boundaryKey.currentContext == null) return null;

      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return null;
      if (!boundary.hasSize ||
          boundary.size.width <= 0 ||
          boundary.size.height <= 0) {
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      final Uint8List? bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } catch (e, st) {
      // Expected on Flutter Web / missing paint — return null quietly.
      // Avoid logging LateInitializationError noise for list-item share.
      final message = e.toString();
      if (!message.contains('LateInitializationError') &&
          !message.contains('LateInitialization')) {
        debugPrint('capturePngBytes failed: $e\n$st');
      }
      return null;
    }
  }

  /// Resolves a laid-out [RenderRepaintBoundary] for [boundaryKey], or null.
  static RenderRepaintBoundary? _mountedRepaintBoundary(GlobalKey boundaryKey) {
    final context = boundaryKey.currentContext;
    if (context == null || !context.mounted) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    if (!renderObject.hasSize ||
        renderObject.size.width <= 0 ||
        renderObject.size.height <= 0) {
      return null;
    }
    return renderObject;
  }

  /// Shares [ticket] as a JPEG of the **full ticket** when image capture is
  /// available; otherwise shares/copies ticket link/details only.
  ///
  /// [eventImageBytes] is only used as the photo slot inside [SavedTicketView].
  /// Prefer an on-screen [boundaryKey] (detail page); otherwise compose via a
  /// opaque modal when [attachTicketImage] is true.
  ///
  /// Set [attachTicketImage] to `false` for My Tickets **list** rows (no full
  /// ticket [RepaintBoundary] is painted there) — skips image capture and
  /// shares link/details only, without throwing.
  ///
  /// **Web:** tries Web Share via [SharePlus]; on failure / unsupported,
  /// falls back to an HTML blob download of `ticket.jpg`, then copying a
  /// shareable URL if composite capture fails.
  static Future<void> share(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Rect? sharePositionOrigin,
    Uint8List? eventImageBytes,
    @Deprecated('Use eventImageBytes — never shared as the ticket file')
    Uint8List? imageBytes,
    bool attachTicketImage = true,
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
    final photoBytes = eventImageBytes ?? imageBytes;

    try {
      if (attachTicketImage) {
        jpegBytes = await _prepareTicketJpeg(
          context,
          ticket,
          boundaryKey: boundaryKey,
          eventImageBytes: photoBytes,
        );
      }
      if (!context.mounted) return;

      if (jpegBytes == null || jpegBytes.isEmpty) {
        await _shareTextOrCopyLink(
          context,
          ticket,
          origin: origin,
          messenger: messenger,
          imageCaptureSkipped: !attachTicketImage,
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

      final shareText = _linkOrShareText(ticket);
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
  ///
  /// [imageCaptureSkipped] is true when the caller intentionally did not try
  /// to build a ticket JPEG (e.g. My Tickets list has no full ticket widget).
  static Future<void> _shareTextOrCopyLink(
    BuildContext context,
    Ticket ticket, {
    required Rect origin,
    ScaffoldMessengerState? messenger,
    bool imageCaptureSkipped = false,
  }) async {
    final text = _linkOrShareText(ticket);

    if (kIsWeb) {
      final copied = await _copyShareableFallback(ticket);
      if (!context.mounted) return;
      final successMessage = imageCaptureSkipped
          ? 'Ticket link copied to clipboard'
          : 'Could not create ticket image — link copied instead';
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              copied ? successMessage : _prepareFailedMessage,
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
    // toShareText already appends the http(s) payload URL when present.
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
          text: _linkOrShareText(ticket),
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
                    ? 'Could not download ticket image — link copied instead'
                    : _prepareFailedMessage,
              ),
            ),
          );
      }
      return;
    }

    messenger?.hideCurrentSnackBar();
  }

  /// Builds JPEG bytes for share: always a **full ticket** composite.
  ///
  /// Order: on-screen [boundaryKey] → opaque modal [SavedTicketView].
  /// [eventImageBytes] / [ticket.imagePath] feed the photo slot only — they
  /// are never returned as the share file by themselves.
  ///
  /// Never throws: capture/LateInitializationError failures return null so
  /// callers can fall back to text/link share.
  static Future<Uint8List?> _prepareTicketJpeg(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Uint8List? eventImageBytes,
  }) async {
    try {
      if (boundaryKey != null && boundaryKey.currentContext != null) {
        final captured = await captureJpegBytes(boundaryKey);
        if (captured != null && captured.isNotEmpty) return captured;
      }

      if (!context.mounted) return null;

      // Opaque full-screen modal paints a real ticket (reliable on Flutter Web).
      final jpeg = await _captureViaOpaqueModal(
        context,
        ticket,
        eventImageBytes: eventImageBytes,
      );
      if (jpeg != null && jpeg.isNotEmpty) return jpeg;
      return null;
    } catch (e, st) {
      // Catch Exception and Error (e.g. LateInitializationError).
      debugPrint('Ticket JPEG prepare failed: $e\n$st');
      return null;
    }
  }

  /// Full-opacity modal with [SavedTicketView] + [RepaintBoundary], then capture.
  /// Prefer this over low-opacity overlays on Flutter Web (`toImage` is flaky).
  static Future<Uint8List?> _captureViaOpaqueModal(
    BuildContext context,
    Ticket ticket, {
    Uint8List? eventImageBytes,
  }) async {
    if (!context.mounted) return null;

    final boundaryKey = GlobalKey();
    Uint8List? captured;
    var captureStarted = false;

    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          fullscreenDialog: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (routeContext, animation, secondaryAnimation) {
            if (!captureStarted) {
              captureStarted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  await WidgetsBinding.instance.endOfFrame;
                  await WidgetsBinding.instance.endOfFrame;

                  final captureContext = boundaryKey.currentContext;
                  if (captureContext != null && captureContext.mounted) {
                    await _precacheTicketImages(
                      captureContext,
                      ticket,
                      eventImageBytes: eventImageBytes,
                    );
                  }

                  await WidgetsBinding.instance.endOfFrame;
                  await Future<void>.delayed(const Duration(milliseconds: 200));

                  // Prefer JPEG; fall back to PNG→JPEG.
                  Uint8List? bytes = await captureJpegBytes(boundaryKey);
                  if (bytes == null || bytes.isEmpty) {
                    final png = await capturePngBytes(boundaryKey);
                    if (png != null && png.isNotEmpty) {
                      bytes = await compressImageToJpeg(png);
                    }
                  }
                  if (bytes != null && bytes.isNotEmpty) {
                    captured = bytes;
                  }
                } catch (e, st) {
                  debugPrint('Opaque modal ticket capture failed: $e\n$st');
                } finally {
                  if (routeContext.mounted) {
                    Navigator.of(routeContext).pop();
                  }
                }
              });
            }

            final width =
                MediaQuery.sizeOf(routeContext).width.clamp(280.0, 420.0);
            return Material(
              color: Colors.white,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: width,
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: SavedTicketView(
                          ticket: ticket,
                          imageBytes: eventImageBytes,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Opaque modal navigation failed: $e\n$st');
      return null;
    }

    return captured;
  }

  static Future<void> _precacheTicketImages(
    BuildContext context,
    Ticket ticket, {
    Uint8List? eventImageBytes,
  }) async {
    if (!context.mounted) return;

    if (eventImageBytes != null && eventImageBytes.isNotEmpty) {
      try {
        await precacheImage(MemoryImage(eventImageBytes), context);
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
