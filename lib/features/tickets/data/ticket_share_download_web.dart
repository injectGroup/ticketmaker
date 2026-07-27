import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Triggers a browser Downloads-folder save via blob URL + anchor click.
///
/// Equivalent to:
/// ```dart
/// final blob = html.Blob([imageBytes]);
/// final url = html.Url.createObjectUrlFromBlob(blob);
/// final anchor = html.AnchorElement(href: url)
///   ..setAttribute('download', filename)
///   ..click();
/// html.Url.revokeObjectUrl(url);
/// ```
void downloadBytesAsFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'image/png',
}) {
  if (bytes.isEmpty) {
    throw ArgumentError.value(bytes, 'bytes', 'Image bytes must not be empty');
  }

  final blob = Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    BlobPropertyBag(type: mimeType),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none'
    ..rel = 'noopener';
  anchor.setAttribute('download', filename);
  document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
