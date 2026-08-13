import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Web fallback: browsers have no temp directory, so share in-memory bytes.
Future<XFile> ticketShareImageXFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? temporaryDirectoryPath,
}) async {
  assert(temporaryDirectoryPath == null || temporaryDirectoryPath.isNotEmpty);
  return XFile.fromData(bytes, mimeType: mimeType, name: fileName);
}
