import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies ticket images into a durable app-documents folder.
class TicketImageStore {
  TicketImageStore({this._overrideImagesDirectory});

  static const String folderName = 'ticket_images';

  final Directory? _overrideImagesDirectory;

  Future<Directory> _imagesDirectory() async {
    final override = _overrideImagesDirectory;
    if (override != null) {
      if (!override.existsSync()) {
        await override.create(recursive: true);
      }
      return override;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folderName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _extensionFor(String sourcePath) {
    final name = sourcePath.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.jpg';
    return name.substring(dot);
  }

  bool _isUnderImagesDir(String path, Directory imagesDir) {
    final normalized = File(path).absolute.path;
    final root = imagesDir.absolute.path;
    return normalized == root ||
        normalized.startsWith('$root${Platform.pathSeparator}');
  }

  /// Copies [sourcePath] into durable storage with a unique name.
  /// Returns the durable path, or `''` if the copy fails / source missing.
  Future<String> import(String sourcePath) async {
    if (sourcePath.isEmpty) return '';
    final source = File(sourcePath);
    if (!source.existsSync()) return '';

    try {
      final imagesDir = await _imagesDirectory();
      if (_isUnderImagesDir(sourcePath, imagesDir)) {
        return source.absolute.path;
      }
      final ext = _extensionFor(sourcePath);
      final dest = File(
        '${imagesDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await source.copy(dest.path);
      return dest.path;
    } on FileSystemException {
      return '';
    }
  }

  /// Copies [sourcePath] to a stable `ticketId` filename under durable storage.
  /// Returns the durable path, or `''` if the copy fails / source missing.
  Future<String> persistForTicket({
    required String sourcePath,
    required String ticketId,
  }) async {
    if (sourcePath.isEmpty || ticketId.isEmpty) return '';
    final source = File(sourcePath);
    if (!source.existsSync()) return '';

    try {
      final imagesDir = await _imagesDirectory();
      final ext = _extensionFor(sourcePath);
      final dest = File('${imagesDir.path}/$ticketId$ext');

      if (_isUnderImagesDir(sourcePath, imagesDir) &&
          source.absolute.path == dest.absolute.path) {
        return dest.path;
      }

      await source.copy(dest.path);
      return dest.path;
    } on FileSystemException {
      return '';
    }
  }
}
