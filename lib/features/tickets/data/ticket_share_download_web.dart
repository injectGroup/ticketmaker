import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Triggers a browser file download for [bytes] (web Share fallback).
void downloadBytesAsFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'image/jpeg',
}) {
  final blob = Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    BlobPropertyBag(type: mimeType),
  );
  final url = URL.createObjectURL(blob);
  final anchor = document.createElement('a') as HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
