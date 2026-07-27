import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../generate/domain/entities/ticket.dart';
import '../presentation/widgets/saved_ticket_view.dart';
import '../presentation/widgets/web_share_options_dialog.dart';
import 'ticket_image_codec.dart';
import 'ticket_network_image.dart';
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
  static const String _downloadedMessage = 'Ticket downloaded successfully!';
  static const String _linkCopiedMessage = 'Share link copied to clipboard';
  static const String _downloadFailedMessage =
      'Could not prepare ticket image to download.';
  static const String _copyFailedMessage =
      'Could not copy share link. Try again.';

  /// Sanitized web download name: `Ticket_<ticket.id>.png`.
  static String downloadFileNameFor(Ticket ticket) {
    final raw = ticket.id.trim();
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'Ticket_${safe.isEmpty ? 'ticket' : safe}.png';
  }

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
      if (boundaryKey.currentContext == null) return null;

      RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (boundaryKey.currentContext == null) return null;
        boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null || boundary.debugNeedsPaint) return null;
      }
      if (!boundary.hasSize ||
          boundary.size.width <= 0 ||
          boundary.size.height <= 0) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
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

  /// Encodes [repaintKey]'s [RepaintBoundary] to PNG bytes in memory.
  ///
  /// Returns `null` when the key is not attached, the boundary is missing /
  /// never paints, or capture fails — never throws.
  ///
  /// No `late` locals — every render/image/byte reference is nullable and
  /// checked before use. Waits for [endOfFrame] + paint delay before [toImage].
  static Future<Uint8List?> capturePngBytes(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      if (repaintKey.currentContext == null) return null;

      RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Allow network image / QR / layout to paint before snapshot.
      await _awaitFrameOrTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      for (var i = 0; i < 6; i++) {
        final current = boundary;
        if (current == null) return null;
        if (!current.debugNeedsPaint &&
            current.hasSize &&
            current.size.width > 0 &&
            current.size.height > 0) {
          break;
        }
        await _awaitFrameOrTimeout();
        await Future<void>.delayed(Duration(milliseconds: 50 + (i * 25)));
        if (repaintKey.currentContext == null) return null;
        boundary = repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
      }

      final ready = boundary;
      if (ready == null ||
          ready.debugNeedsPaint ||
          !ready.hasSize ||
          ready.size.width <= 0 ||
          ready.size.height <= 0) {
        return null;
      }

      ui.Image? image;
      try {
        image = await ready.toImage(pixelRatio: pixelRatio);
      } catch (e, st) {
        // Canvas/SecurityError often means a CORS-tainted network image.
        debugPrint(
          'capturePngBytes toImage failed (possible CORS/SecurityError): $e\n$st',
        );
        return null;
      }

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      final Uint8List? bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } catch (e, st) {
      debugPrint('capturePngBytes failed: $e\n$st');
      return null;
    }
  }

  /// [endOfFrame] can hang in widget tests; bound the wait.
  static Future<void> _awaitFrameOrTimeout() async {
    try {
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 500),
      );
    } catch (_) {}
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
  /// **Web:** shows a dialog with **Download Ticket Image** and
  /// **Copy Share Link**, then SnackBars that name the completed action.
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
    final origin = sharePositionOrigin ?? shareOriginFrom(context);
    final photoBytes = eventImageBytes ?? imageBytes;

    // Web: let the user choose download vs copy before any capture work.
    if (kIsWeb) {
      await _shareOnWeb(
        context,
        ticket,
        boundaryKey: boundaryKey,
        eventImageBytes: photoBytes,
        messenger: messenger,
      );
      return;
    }

    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Preparing share…'),
          duration: Duration(seconds: 2),
        ),
      );

    Uint8List? jpegBytes;

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

      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_friendlyErrorMessage(e))),
        );
    }
  }

  /// Web share entry: dialog with download image or copy link.
  static Future<void> _shareOnWeb(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Uint8List? eventImageBytes,
    ScaffoldMessengerState? messenger,
  }) async {
    final choice = await showWebShareOptionsDialog(context);
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case WebShareOption.downloadImage:
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Preparing ticket image…'),
              duration: Duration(seconds: 2),
            ),
          );
        // Let the share dialog finish dismissing before painting capture UI.
        await _awaitFrameOrTimeout();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!context.mounted) return;

        Uint8List? pngBytes;
        try {
          // List rows have no mounted ticket RepaintBoundary — compose from
          // ticket model via on-screen Overlay / modal SavedTicketView.
          final mountedKey = boundaryKey != null &&
                  boundaryKey.currentContext != null
              ? boundaryKey
              : null;
          pngBytes = await composeTicketPngBytes(
            context,
            ticket,
            boundaryKey: mountedKey,
            eventImageBytes: eventImageBytes,
          );
        } catch (e, st) {
          debugPrint('Web ticket image prepare failed: $e\n$st');
        }
        if (!context.mounted) return;
        if (pngBytes == null || pngBytes.isEmpty) {
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(_downloadFailedMessage)),
            );
          return;
        }
        try {
          assert(kIsWeb, 'Download Ticket Image is web-only');
          downloadBytesAsFile(
            pngBytes,
            downloadFileNameFor(ticket),
            mimeType: 'image/png',
          );
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(_downloadedMessage)),
            );
        } catch (e, st) {
          debugPrint('Web ticket download failed: $e\n$st');
          if (!context.mounted) return;
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(_downloadFailedMessage)),
            );
        }
      case WebShareOption.copyLink:
        final copied = await _copyShareableFallback(ticket);
        if (!context.mounted) return;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                copied ? _linkCopiedMessage : _copyFailedMessage,
              ),
            ),
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
              copied ? _linkCopiedMessage : _copyFailedMessage,
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

  /// Builds PNG bytes for a full ticket composite from [ticket] model data.
  ///
  /// Order: on-screen [boundaryKey] → painted Overlay → opaque modal.
  /// Network photos are fetched to [MemoryImage] bytes first (CORS-safe).
  /// Never throws — returns null so callers can show a failure SnackBar.
  static Future<Uint8List?> composeTicketPngBytes(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Uint8List? eventImageBytes,
  }) async {
    try {
      final photoBytes = await _resolveEventPhotoBytes(
        ticket,
        eventImageBytes: eventImageBytes,
      );

      if (boundaryKey != null && boundaryKey.currentContext != null) {
        final onScreen = await _capturePngWithRetries(boundaryKey);
        if (onScreen != null && onScreen.isNotEmpty) return onScreen;
      }

      if (!context.mounted) return null;

      // Prefer a painted Overlay (visible layout) — off-screen widgets are
      // often culled on Flutter Web and yield null captures.
      final viaOverlay = await _captureViaPaintedOverlay(
        context,
        ticket,
        eventImageBytes: photoBytes,
      );
      if (viaOverlay != null && viaOverlay.isNotEmpty) return viaOverlay;

      if (!context.mounted) return null;

      final viaModal = await _captureViaOpaqueModal(
        context,
        ticket,
        eventImageBytes: photoBytes,
        preferPng: true,
      );
      if (viaModal != null && viaModal.isNotEmpty) return viaModal;
      return null;
    } catch (e, st) {
      debugPrint('Ticket PNG compose failed: $e\n$st');
      return null;
    }
  }

  /// Prefer in-memory event photo bytes; otherwise HTTP-fetch network paths.
  static Future<Uint8List?> _resolveEventPhotoBytes(
    Ticket ticket, {
    Uint8List? eventImageBytes,
  }) async {
    if (eventImageBytes != null && eventImageBytes.isNotEmpty) {
      return eventImageBytes;
    }
    final path = ticket.imagePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return fetchImageBytesCorsSafe(path);
    }
    return null;
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
      final png = await composeTicketPngBytes(
        context,
        ticket,
        boundaryKey: boundaryKey,
        eventImageBytes: eventImageBytes,
      );
      if (png != null && png.isNotEmpty) {
        final jpeg = await compressImageToJpeg(png);
        if (jpeg.isNotEmpty) return jpeg;
      }

      if (boundaryKey != null && boundaryKey.currentContext != null) {
        final captured = await captureJpegBytes(boundaryKey);
        if (captured != null && captured.isNotEmpty) return captured;
      }

      if (!context.mounted) return null;

      final jpeg = await _captureViaOpaqueModal(
        context,
        ticket,
        eventImageBytes: eventImageBytes,
        preferPng: false,
      );
      if (jpeg != null && jpeg.isNotEmpty) return jpeg;
      return null;
    } catch (e, st) {
      // Catch Exception and Error (e.g. LateInitializationError).
      debugPrint('Ticket JPEG prepare failed: $e\n$st');
      return null;
    }
  }

  static Future<Uint8List?> _capturePngWithRetries(
    GlobalKey boundaryKey, {
    int attempts = 5,
  }) async {
    for (var i = 0; i < attempts; i++) {
      final png = await capturePngBytes(boundaryKey);
      if (png != null && png.isNotEmpty) return png;
      await Future<void>.delayed(Duration(milliseconds: 80 + (i * 40)));
    }
    return null;
  }

  /// Paints [SavedTicketView] in a full-screen [Overlay] (briefly), then PNG.
  ///
  /// On-screen layout is required on Flutter Web — off-screen / culled
  /// widgets often fail [RenderRepaintBoundary.toImage].
  static Future<Uint8List?> _captureViaPaintedOverlay(
    BuildContext context,
    Ticket ticket, {
    Uint8List? eventImageBytes,
  }) async {
    if (!context.mounted) return null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    OverlayEntry? entry;
    try {
      entry = OverlayEntry(
        builder: (overlayContext) {
          final width =
              MediaQuery.sizeOf(overlayContext).width.clamp(280.0, 420.0);
          return Positioned.fill(
            child: IgnorePointer(
              child: Material(
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
              ),
            ),
          );
        },
      );
      overlay.insert(entry);
      // Force a rebuild so the OverlayEntry lays out before we wait on frames.
      entry.markNeedsBuild();

      await _awaitFrameOrTimeout();
      await _awaitFrameOrTimeout();
      if (boundaryKey.currentContext != null &&
          boundaryKey.currentContext!.mounted) {
        await _precacheTicketImages(
          boundaryKey.currentContext!,
          ticket,
          eventImageBytes: eventImageBytes,
        );
      }
      await _awaitFrameOrTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 350));

      return await _capturePngWithRetries(boundaryKey, attempts: 8);
    } catch (e, st) {
      debugPrint('Painted overlay ticket capture failed: $e\n$st');
      return null;
    } finally {
      entry?.remove();
    }
  }

  /// Full-opacity modal with [SavedTicketView] + [RepaintBoundary], then capture.
  /// Prefer this over low-opacity overlays on Flutter Web (`toImage` is flaky).
  static Future<Uint8List?> _captureViaOpaqueModal(
    BuildContext context,
    Ticket ticket, {
    Uint8List? eventImageBytes,
    bool preferPng = true,
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
                  await _awaitFrameOrTimeout();
                  await _awaitFrameOrTimeout();

                  final captureContext = boundaryKey.currentContext;
                  if (captureContext != null && captureContext.mounted) {
                    await _precacheTicketImages(
                      captureContext,
                      ticket,
                      eventImageBytes: eventImageBytes,
                    );
                  }

                  await _awaitFrameOrTimeout();
                  await Future<void>.delayed(const Duration(milliseconds: 400));

                  Uint8List? bytes;
                  if (preferPng) {
                    bytes = await _capturePngWithRetries(
                      boundaryKey,
                      attempts: 8,
                    );
                    if (bytes == null || bytes.isEmpty) {
                      bytes = await captureJpegBytes(boundaryKey);
                    }
                  } else {
                    bytes = await captureJpegBytes(boundaryKey);
                    if (bytes == null || bytes.isEmpty) {
                      final png = await _capturePngWithRetries(boundaryKey);
                      if (png != null && png.isNotEmpty) {
                        bytes = await compressImageToJpeg(png);
                      }
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
      // Prefer bytes → MemoryImage to avoid CORS-tainted NetworkImage on web.
      final fetched = await fetchImageBytesCorsSafe(path);
      if (!context.mounted) return;
      if (fetched != null && fetched.isNotEmpty) {
        try {
          await precacheImage(MemoryImage(fetched), context);
        } catch (_) {}
        return;
      }
      try {
        await precacheImage(NetworkImage(path), context);
      } catch (_) {}
    }
  }
}
