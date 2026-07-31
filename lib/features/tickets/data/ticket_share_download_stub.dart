import 'dart:typed_data';

/// Stub for non-web platforms — download is only used on Flutter Web.
void downloadBytesAsFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'image/png',
}) {
  throw UnsupportedError('Blob download is only available on web');
}
