import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes ticket image bytes to a temp file and returns a path-based [XFile].
///
/// WhatsApp and other apps on iOS/Android show a photo preview when the
/// attachment is a real file path. In-memory bytes often become a text share.
Future<XFile> ticketShareImageXFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? temporaryDirectoryPath,
}) async {
  final dir = temporaryDirectoryPath != null
      ? Directory(temporaryDirectoryPath)
      : await getTemporaryDirectory();
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final safeName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: mimeType, name: safeName);
}
