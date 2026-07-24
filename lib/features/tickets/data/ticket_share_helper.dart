import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../generate/domain/entities/ticket.dart';
import '../presentation/widgets/saved_ticket_view.dart';
import 'ticket_image_codec.dart';

/// Captures a ticket as PNG and opens the native share sheet with image + caption.
class TicketShareHelper {
  TicketShareHelper._();

  static const String _subject = 'My Custom Ticket Design';

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

  /// Encodes [boundaryKey]'s [RepaintBoundary] to JPEG bytes (faster / smaller
  /// than PNG for share + upload).
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

  /// Shares [ticket] as a PNG (plus caption). Falls back to text-only on failure.
  static Future<void> share(
    BuildContext context,
    Ticket ticket, {
    GlobalKey? boundaryKey,
    Rect? sharePositionOrigin,
  }) async {
    final origin = sharePositionOrigin ?? shareOriginFrom(context);
    List<int>? imageBytes;

    if (boundaryKey != null) {
      imageBytes = await captureJpegBytes(boundaryKey);
    }
    if (!context.mounted) return;
    if (imageBytes == null || imageBytes.isEmpty) {
      final png = await _captureViaOverlay(context, ticket);
      if (png != null && png.isNotEmpty) {
        imageBytes = await compressImageToJpeg(Uint8List.fromList(png));
      }
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/share_ticket_${ticket.id}.jpg');
        await file.writeAsBytes(imageBytes, flush: true);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          text: ticket.toShareText(),
          subject: _subject,
          sharePositionOrigin: origin,
        );
        return;
      } catch (_) {
        // Fall through to text-only share.
      }
    }

    // ignore: deprecated_member_use
    await Share.share(
      ticket.toShareText(),
      subject: _subject,
      sharePositionOrigin: origin,
    );
  }

  static Future<List<int>?> _captureViaOverlay(
    BuildContext context,
    Ticket ticket,
  ) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    final width = MediaQuery.sizeOf(context).width.clamp(280.0, 420.0);
    late OverlayEntry entry;

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
                    child: SavedTicketView(ticket: ticket),
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
        await _precacheTicketImages(captureContext, ticket);
      }
      await WidgetsBinding.instance.endOfFrame;
      // Allow QR / network-free paints to settle.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return await capturePngBytes(boundaryKey);
    } finally {
      entry.remove();
    }
  }

  static Future<void> _precacheTicketImages(
    BuildContext context,
    Ticket ticket,
  ) async {
    if (!context.mounted) return;

    final path = ticket.imagePath;
    if (path.isNotEmpty && File(path).existsSync()) {
      try {
        await precacheImage(FileImage(File(path)), context);
      } catch (_) {}
    }
  }
}
