import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../generate/domain/entities/ticket.dart';
import '../presentation/widgets/saved_ticket_view.dart';
import '../presentation/widgets/share_format_dialog.dart';
import '../presentation/widgets/web_share_options_dialog.dart';
import 'ticket_image_codec.dart';
import 'ticket_image_store.dart';
import 'ticket_network_image.dart';
import 'ticket_pdf_export.dart';
import 'ticket_raster_export.dart';
import 'ticket_share_download_stub.dart'
    if (dart.library.js_interop) 'ticket_share_download_web.dart';
import 'ticket_share_transport.dart';

/// Captures a ticket image and opens the native share sheet (or downloads on web).
class TicketShareHelper {
  TicketShareHelper._();

  static const String _subject = 'Your personal event ticket';
  static const String _jpegFileName = 'ticket.jpg';
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
  static const String _downloadRetryMessage =
      'Preparing ticket image... please try again.';
  static const String _copyFailedMessage =
      'Could not copy share link. Try again.';
  static const String _pdfFailedMessage =
      'Could not prepare ticket PDF. Try sharing as an image.';

  static TicketShareTransport _transport = const PlatformTicketShareTransport();

  /// Where finished bytes go: native share sheet, or Web Share API with a
  /// browser download fallback.
  static TicketShareTransport get transport => _transport;

  @visibleForTesting
  static set transport(TicketShareTransport value) => _transport = value;

  @visibleForTesting
  static void resetTransport() =>
      _transport = const PlatformTicketShareTransport();

  /// Sanitized share name: `Ticket_<ticket.id>.png`.
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

  /// Resolves a [RenderRepaintBoundary] from [key] without `late` or unsafe casts.
  ///
  /// Returns `null` when the key is unmounted or the render object is not a
  /// [RenderRepaintBoundary] — never throws [LateInitializationError].
  static RenderRepaintBoundary? _boundaryFromKey(GlobalKey key) {
    RenderRepaintBoundary? boundary;
    final context = key.currentContext;
    if (context != null) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        boundary = renderObject;
      }
    }
    return boundary;
  }

  /// Encodes [boundaryKey]'s [RepaintBoundary] to JPEG bytes in memory.
  /// Returns null on any failure (including Flutter Web LateInitializationError).
  static Future<Uint8List?> captureJpegBytes(
    GlobalKey boundaryKey, {
    double? pixelRatio,
    int quality = 72,
  }) async {
    final ratio = pixelRatio ?? (kIsWeb ? 1.0 : 1.5);
    try {
      RenderRepaintBoundary? boundary = _boundaryFromKey(boundaryKey);
      if (boundary == null) return null;
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        boundary = _boundaryFromKey(boundaryKey);
        if (boundary == null || boundary.debugNeedsPaint) return null;
      }
      if (!boundary.hasSize ||
          boundary.size.width <= 0 ||
          boundary.size.height <= 0) {
        return null;
      }

      ui.Image? image;
      try {
        image = await boundary.toImage(pixelRatio: ratio);
      } catch (e, st) {
        final message = e.toString();
        if (!_isEngineLateInit(message)) {
          debugPrint('captureJpegBytes toImage failed: $e\n$st');
        }
        return null;
      }

      final Uint8List? jpegBytes = await uiImageToJpeg(image, quality: quality);
      image.dispose();
      if (jpegBytes == null || jpegBytes.isEmpty) return null;
      return jpegBytes;
    } catch (e, st) {
      final message = e.toString();
      if (!_isEngineLateInit(message)) {
        debugPrint('captureJpegBytes failed: $e\n$st');
      }
      return null;
    }
  }

  /// Encodes [repaintKey]'s [RepaintBoundary] to PNG bytes in memory.
  ///
  /// Returns `null` when the key is not attached, the boundary is missing /
  /// never paints, or capture fails — never throws [LateInitializationError].
  ///
  /// No `late` locals — every render/image/byte reference is nullable and
  /// checked before use. On web, default [pixelRatio] is 1.0 to reduce
  /// CanvasKit OffscreenCanvas pressure.
  ///
  /// When CanvasKit throws LateInitializationError, [lastCaptureHitEngineLateInit]
  /// is set so callers can fail-fast instead of retrying.
  static bool lastCaptureHitEngineLateInit = false;

  static Future<Uint8List?> capturePngBytes(
    GlobalKey repaintKey, {
    double? pixelRatio,
  }) async {
    lastCaptureHitEngineLateInit = false;
    final effectiveRatio = pixelRatio ?? (kIsWeb ? 1.0 : 3.0);

    RenderRepaintBoundary? boundary;
    Uint8List? pngBytes;
    ui.Image? image;
    ByteData? byteData;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _awaitFrameOrTimeout();

      final BuildContext? keyContext = repaintKey.currentContext;
      if (keyContext == null) return null;

      final Element? element =
          keyContext is Element ? keyContext : null;
      if (element != null) {
        WidgetsBinding.instance.buildOwner?.buildScope(element);
      }
      await _awaitFrameOrTimeout();

      boundary = _boundaryFromKey(repaintKey);
      if (boundary == null || boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _awaitFrameOrTimeout();
        boundary = _boundaryFromKey(repaintKey);
      }

      if (boundary == null ||
          boundary.debugNeedsPaint ||
          !boundary.hasSize ||
          boundary.size.width <= 0 ||
          boundary.size.height <= 0) {
        return null;
      }

      try {
        image = await boundary.toImage(pixelRatio: effectiveRatio);
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        image = null;
        pngBytes = byteData?.buffer.asUint8List();
        byteData = null;
        if (pngBytes == null || pngBytes.isEmpty) return null;
        return pngBytes;
      } catch (e, st) {
        final message = e.toString();
        if (_isEngineLateInit(message)) {
          lastCaptureHitEngineLateInit = true;
          debugPrint(
            'capturePngBytes: CanvasKit toImage LateInitializationError '
            '(pixelRatio=$effectiveRatio) — skip retries / use raster fallback',
          );
        } else {
          debugPrint('Failed to capture ticket image: $e\n$st');
        }
        image?.dispose();
        return null;
      }
    } catch (e, st) {
      final message = e.toString();
      if (_isEngineLateInit(message)) {
        lastCaptureHitEngineLateInit = true;
      } else {
        debugPrint('capturePngBytes failed: $e\n$st');
      }
      image?.dispose();
      return null;
    }
  }

  static bool _isEngineLateInit(String message) =>
      message.contains('LateInitializationError') ||
      message.contains('LateInitialization');

  /// [endOfFrame] can hang in widget tests; bound the wait.
  static Future<void> _awaitFrameOrTimeout() async {
    try {
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 500),
      );
    } catch (_) {}
  }

  /// Shares [ticket] in the format the guest picks: a PNG of the **full
  /// ticket**, or a printable PDF. Falls back to sharing the link and details
  /// when neither can be produced.
  ///
  /// [eventImageBytes] is only used as the photo slot inside [SavedTicketView].
  /// Prefer an on-screen [boundaryKey] (detail page); otherwise compose via a
  /// opaque modal when [attachTicketImage] is true.
  ///
  /// Set [attachTicketImage] to `false` for My Tickets **list** rows (no full
  /// ticket [RepaintBoundary] is painted there) — skips the format question and
  /// shares link/details only, without throwing.
  ///
  /// **Web:** shows a dialog with **Download Ticket Image**, **Share as PDF**
  /// and **Copy Share Link**, then SnackBars that name the completed action.
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

    if (!attachTicketImage) {
      await _shareTextOrCopyLink(
        context,
        ticket,
        origin: origin,
        messenger: messenger,
      );
      return;
    }

    final format = await showShareFormatDialog(context);
    if (!context.mounted || format == null) return;

    switch (format) {
      case TicketShareFormat.image:
        await shareAsImage(
          context,
          ticket,
          boundaryKey: boundaryKey,
          sharePositionOrigin: origin,
          eventImageBytes: photoBytes,
        );
      case TicketShareFormat.pdf:
        await shareAsPdf(
          context,
          ticket,
          sharePositionOrigin: origin,
          eventImageBytes: photoBytes,
        );
    }
  }

  /// Shares a PNG of the whole ticket straight from memory.
  ///
  /// Degrades in order: PNG capture, then JPEG capture, then link and details —
  /// so the Share button always completes with something useful.
  static Future<void> shareAsImage(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Rect? sharePositionOrigin,
    Uint8List? eventImageBytes,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final origin = sharePositionOrigin ?? shareOriginFrom(context);

    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Preparing share…'),
          duration: Duration(seconds: 2),
        ),
      );

    try {
      var fileName = downloadFileNameFor(ticket);
      var mimeType = 'image/png';
      Uint8List? bytes = await composeTicketPngBytes(
        context,
        ticket,
        boundaryKey: boundaryKey,
        eventImageBytes: eventImageBytes,
      );
      if (!context.mounted) return;

      if (bytes == null || bytes.isEmpty) {
        bytes = await _prepareTicketJpeg(
          context,
          ticket,
          boundaryKey: boundaryKey,
          eventImageBytes: eventImageBytes,
        );
        fileName = _jpegFileName;
        mimeType = 'image/jpeg';
        if (!context.mounted) return;
      }

      if (bytes == null || bytes.isEmpty) {
        await _shareTextOrCopyLink(
          context,
          ticket,
          origin: origin,
          messenger: messenger,
        );
        return;
      }

      await transport.shareImage(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        text: _linkOrShareText(ticket),
        subject: _subject,
        sharePositionOrigin: origin,
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

  /// Builds the ticket PDF in memory and shares it.
  ///
  /// The document is drawn from the ticket model, so this path needs no painted
  /// [RepaintBoundary] and works from the list as well as the detail page.
  static Future<void> shareAsPdf(
    BuildContext context,
    Ticket ticket, {
    Rect? sharePositionOrigin,
    Uint8List? eventImageBytes,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final origin = sharePositionOrigin ?? shareOriginFrom(context);

    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Preparing PDF…'),
          duration: Duration(seconds: 2),
        ),
      );

    try {
      final photoBytes = await _resolveEventPhotoBytes(
        ticket,
        eventImageBytes: eventImageBytes,
      );
      final pdfBytes = await TicketPdfExport.buildDocumentBytes(
        ticket,
        eventImageBytes: photoBytes,
      );
      if (!context.mounted) return;

      if (pdfBytes == null || pdfBytes.isEmpty) {
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(_pdfFailedMessage)),
          );
        return;
      }

      await transport.sharePdf(
        bytes: pdfBytes,
        fileName: TicketPdfExport.fileNameFor(ticket),
        text: _linkOrShareText(ticket),
        subject: _subject,
        sharePositionOrigin: origin,
      );
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
    } catch (e, st) {
      debugPrint('Ticket PDF share failed: $e\n$st');
      if (!context.mounted) return;

      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(_pdfFailedMessage)),
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
              const SnackBar(content: Text(_downloadRetryMessage)),
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
      case WebShareOption.sharePdf:
        // shareAsPdf shows its own progress SnackBar; the transport then tries
        // the Web Share API and downloads the file if the browser cannot share.
        await _awaitFrameOrTimeout();
        if (!context.mounted) return;
        await shareAsPdf(context, ticket, eventImageBytes: eventImageBytes);
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
  /// **Web:** one low-ratio widget capture attempt, then [TicketRasterExport]
  /// (no CanvasKit `toImage`). **Native:** on-screen → overlay → modal.
  /// Network photos are fetched to memory first (CORS-safe).
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

      if (kIsWeb) {
        if (boundaryKey != null && boundaryKey.currentContext != null) {
          final onScreen = await capturePngBytes(
            boundaryKey,
            pixelRatio: 1.0,
          );
          if (onScreen != null && onScreen.isNotEmpty) return onScreen;
        }

        if (context.mounted && !lastCaptureHitEngineLateInit) {
          final viaOverlay = await _captureViaPaintedOverlay(
            context,
            ticket,
            eventImageBytes: photoBytes,
          );
          if (viaOverlay != null && viaOverlay.isNotEmpty) return viaOverlay;
        }

        final raster = await TicketRasterExport.toPngBytes(
          ticket,
          eventImageBytes: photoBytes,
        );
        if (raster != null && raster.isNotEmpty) return raster;
        return null;
      }

      if (boundaryKey != null && boundaryKey.currentContext != null) {
        final onScreen = await _capturePngWithRetries(boundaryKey);
        if (onScreen != null && onScreen.isNotEmpty) return onScreen;
      }

      if (!context.mounted) return null;

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
    final path = ticket.photoUrl.trim();
    if (path.isEmpty ||
        path.startsWith('blob:') ||
        TicketImageStore.isWebBytesPath(path)) {
      return null;
    }
    if (path.startsWith('data:')) {
      return decodeDataUrlBytes(path);
    }
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
    double? pixelRatio,
  }) async {
    final maxAttempts = kIsWeb ? 1 : attempts;
    for (var i = 0; i < maxAttempts; i++) {
      final png = await capturePngBytes(
        boundaryKey,
        pixelRatio: pixelRatio ?? (kIsWeb ? 1.0 : null),
      );
      if (png != null && png.isNotEmpty) return png;
      // CanvasKit OffscreenCanvas LateInit will not recover on retry.
      if (lastCaptureHitEngineLateInit) return null;
      if (i + 1 < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 80 + (i * 40)));
      }
    }
    return null;
  }

  /// Clears remote photo URLs when bytes were not prefetched so capture
  /// boundaries never mount a live network FutureBuilder.
  static Ticket _ticketForCapture(Ticket ticket, Uint8List? eventImageBytes) {
    if (eventImageBytes != null && eventImageBytes.isNotEmpty) return ticket;
    final path = ticket.photoUrl.trim();
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('gs://') ||
        path.startsWith('data:')) {
      return ticket.copyWith(imagePath: '');
    }
    return ticket;
  }

  /// Paints [SavedTicketView] in a Stateful overlay host, then captures PNG.
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

    final GlobalKey boundaryKey = GlobalKey();
    final mountedCompleter = Completer<void>();
    OverlayEntry? entry;
    try {
      entry = OverlayEntry(
        builder: (overlayContext) {
          return _TicketCaptureOverlayHost(
            boundaryKey: boundaryKey,
            ticket: ticket,
            eventImageBytes: eventImageBytes,
            onMounted: () {
              if (!mountedCompleter.isCompleted) {
                mountedCompleter.complete();
              }
            },
          );
        },
      );
      overlay.insert(entry);

      // Wait until the Stateful host reports first frame, then settle paint.
      await mountedCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _awaitFrameOrTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 300));
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
      await Future<void>.delayed(const Duration(milliseconds: 100));

      return await _capturePngWithRetries(
        boundaryKey,
        attempts: kIsWeb ? 1 : 8,
        pixelRatio: kIsWeb ? 1.0 : null,
      );
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
                      attempts: kIsWeb ? 1 : 8,
                      pixelRatio: kIsWeb ? 1.0 : null,
                    );
                    if (bytes == null || bytes.isEmpty) {
                      if (!lastCaptureHitEngineLateInit) {
                        bytes = await captureJpegBytes(
                          boundaryKey,
                          pixelRatio: kIsWeb ? 1.0 : null,
                        );
                      }
                    }
                  } else {
                    bytes = await captureJpegBytes(
                      boundaryKey,
                      pixelRatio: kIsWeb ? 1.0 : null,
                    );
                    if (bytes == null || bytes.isEmpty) {
                      final png = await _capturePngWithRetries(
                        boundaryKey,
                        attempts: kIsWeb ? 1 : 5,
                        pixelRatio: kIsWeb ? 1.0 : null,
                      );
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
            final hasPhoto =
                eventImageBytes != null && eventImageBytes.isNotEmpty;
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
                          ticket: _ticketForCapture(ticket, eventImageBytes),
                          imageBytes: hasPhoto ? eventImageBytes : null,
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
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:')) {
      // Prefer bytes → MemoryImage to avoid CORS-tainted NetworkImage on web.
      final fetched = await fetchImageBytesCorsSafe(path);
      if (!context.mounted) return;
      if (fetched != null && fetched.isNotEmpty) {
        try {
          await precacheImage(MemoryImage(fetched), context);
        } catch (_) {}
      }
      // Never precache NetworkImage — it can CORS-taint Flutter Web canvases.
    }
  }
}

/// Stateful overlay host that mounts [SavedTicketView] under a [RepaintBoundary]
/// and signals [onMounted] after the first frame — used for web PNG capture.
class _TicketCaptureOverlayHost extends StatefulWidget {
  const _TicketCaptureOverlayHost({
    required this.boundaryKey,
    required this.ticket,
    required this.eventImageBytes,
    required this.onMounted,
  });

  final GlobalKey boundaryKey;
  final Ticket ticket;
  final Uint8List? eventImageBytes;
  final VoidCallback onMounted;

  @override
  State<_TicketCaptureOverlayHost> createState() =>
      _TicketCaptureOverlayHostState();
}

class _TicketCaptureOverlayHostState extends State<_TicketCaptureOverlayHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onMounted();
    });
  }

  /// Ticket used inside the capture boundary. Clears remote photo URLs when
  /// bytes were not prefetched so the boundary never mounts a live network
  /// FutureBuilder (avoids mid-capture loads / CORS taint races).
  Ticket get _captureTicket =>
      TicketShareHelper._ticketForCapture(widget.ticket, widget.eventImageBytes);

  @override
  Widget build(BuildContext context) {
    try {
      final width = MediaQuery.sizeOf(context).width.clamp(280.0, 420.0);
      final photoBytes = widget.eventImageBytes;
      final hasPhoto = photoBytes != null && photoBytes.isNotEmpty;

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
                      key: widget.boundaryKey,
                      child: SavedTicketView(
                        ticket: _captureTicket,
                        // Explicit null when empty → placeholder, no network.
                        imageBytes: hasPhoto ? photoBytes : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Ticket capture overlay build failed: $e\n$st');
      return const SizedBox.shrink();
    }
  }
}
