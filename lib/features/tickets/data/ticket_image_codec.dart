import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Compresses image [bytes] to JPEG for faster uploads / storage.
Future<Uint8List> compressImageToJpeg(
  Uint8List bytes, {
  int quality = 72,
  int maxWidth = 1280,
}) async {
  if (bytes.isEmpty) return bytes;
  final args = _JpegCompressArgs(
    bytes: bytes,
    quality: quality,
    maxWidth: maxWidth,
  );
  try {
    // `compute` / isolates are unreliable on Flutter Web (LateInitializationError).
    if (kIsWeb) {
      return _compressJpegIsolate(args);
    }
    return await compute(_compressJpegIsolate, args);
  } catch (e, st) {
    debugPrint('JPEG compress failed, using original bytes: $e\n$st');
    return bytes;
  }
}

class _JpegCompressArgs {
  const _JpegCompressArgs({
    required this.bytes,
    required this.quality,
    required this.maxWidth,
  });

  final Uint8List bytes;
  final int quality;
  final int maxWidth;
}

Uint8List _compressJpegIsolate(_JpegCompressArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;

  var image = decoded;
  if (image.width > args.maxWidth) {
    image = img.copyResize(
      image,
      width: args.maxWidth,
      interpolation: img.Interpolation.linear,
    );
  }

  final encoded = img.encodeJpg(image, quality: args.quality);
  return Uint8List.fromList(encoded);
}

/// Captures a [ui.Image] to JPEG via raw RGBA → decode → encode.
Future<Uint8List?> uiImageToJpeg(
  ui.Image image, {
  int quality = 72,
}) async {
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;
    final converted = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: byteData.buffer,
      bytesOffset: byteData.offsetInBytes,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(converted, quality: quality));
  } catch (e, st) {
    debugPrint('uiImageToJpeg failed: $e\n$st');
    return null;
  }
}
