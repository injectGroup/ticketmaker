import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../generate/domain/entities/ticket.dart';
import '../presentation/widgets/saved_ticket_view.dart';
import 'ticket_image_codec.dart';

/// Captures a ticket image and opens the native / web share sheet.
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

  /// Shares [ticket] as a JPEG (plus caption). Uses in-memory [XFile.fromData]
  /// so Flutter Web does not depend on dart:io temp files.
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
    List<int>? bytes;

    try {
      if (boundaryKey != null) {
        bytes = await captureJpegBytes(boundaryKey);
      }
      if (!context.mounted) return;
      if (bytes == null || bytes.isEmpty) {
        final png = await _captureViaOverlay(
          context,
          ticket,
          imageBytes: imageBytes,
        );
        if (png != null && png.isNotEmpty) {
          bytes = await compressImageToJpeg(Uint8List.fromList(png));
        }
      }

      if (!context.mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        final file = XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'image/jpeg',
          name: 'ticket_${ticket.id}.jpg',
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [file],
          text: ticket.toShareText(),
          subject: _subject,
          sharePositionOrigin: origin,
        );
        messenger?.hideCurrentSnackBar();
        return;
      }

      // ignore: deprecated_member_use
      await Share.share(
        ticket.toShareText(),
        subject: _subject,
        sharePositionOrigin: origin,
      );
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

  static Future<List<int>?> _captureViaOverlay(
    BuildContext context,
    Ticket ticket, {
    Uint8List? imageBytes,
  }) async {
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
