import 'dart:io';
import 'dart:typed_data';

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
    return name.substring(dot).toLowerCase();
  }

  bool _isUnderImagesDir(String path, Directory imagesDir) {
    final normalized = File(path).absolute.path;
    final root = imagesDir.absolute.path;
    return normalized == root ||
        normalized.startsWith('$root${Platform.pathSeparator}');
  }

  Future<String> _writeBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) return '';
    final imagesDir = await _imagesDirectory();
    final dest = File('${imagesDir.path}/$fileName');
    await dest.writeAsBytes(bytes, flush: true);
    if (!dest.existsSync() || dest.lengthSync() == 0) return '';
    return dest.path;
  }

  Future<Uint8List?> _readBytes(String sourcePath) async {
    if (sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!source.existsSync()) return null;
    try {
      return await source.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Writes [bytes] (or reads from [sourcePath]) into durable storage with a
  /// unique name. Returns the durable path, or `''` on failure.
  Future<String> import({
    String sourcePath = '',
    Uint8List? bytes,
  }) async {
    final payload = bytes ?? await _readBytes(sourcePath);
    if (payload == null || payload.isEmpty) return '';

    if (sourcePath.isNotEmpty) {
      final imagesDir = await _imagesDirectory();
      if (_isUnderImagesDir(sourcePath, imagesDir) &&
          File(sourcePath).existsSync()) {
        return File(sourcePath).absolute.path;
      }
    }

    final ext = sourcePath.isEmpty ? '.jpg' : _extensionFor(sourcePath);
    final name = '${DateTime.now().millisecondsSinceEpoch}$ext';
    return _writeBytes(bytes: payload, fileName: name);
  }

  /// Writes bytes under a stable `ticketId` filename.
  /// Returns the durable path, or `''` on failure (never clears an existing file
  /// unless a successful write replaces it).
  Future<String> persistForTicket({
    required String ticketId,
    String sourcePath = '',
    Uint8List? bytes,
  }) async {
    if (ticketId.isEmpty) return '';
    final payload = bytes ?? await _readBytes(sourcePath);
    if (payload == null || payload.isEmpty) return '';

    final imagesDir = await _imagesDirectory();
    final ext = sourcePath.isEmpty ? '.jpg' : _extensionFor(sourcePath);
    final dest = File('${imagesDir.path}/$ticketId$ext');

    if (sourcePath.isNotEmpty &&
        _isUnderImagesDir(sourcePath, imagesDir) &&
        File(sourcePath).absolute.path == dest.absolute.path &&
        dest.existsSync()) {
      return dest.path;
    }

    return _writeBytes(bytes: payload, fileName: '$ticketId$ext');
  }

  /// Deletes durable image files for the given [imagePaths] when they live
  /// under the ticket images directory.
  Future<void> deleteStoredImages(Iterable<String> imagePaths) async {
    final paths = imagePaths.where((p) => p.isNotEmpty).toList(growable: false);
    if (paths.isEmpty) return;

    final imagesDir = await _imagesDirectory();
    for (final path in paths) {
      if (!_isUnderImagesDir(path, imagesDir)) continue;
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        await file.delete();
      } on FileSystemException {
        // Best-effort cleanup.
      }
    }
  }

  /// Finds an existing durable file for [ticketId] (any extension).
  Future<String?> findExistingForTicket(String ticketId) async {
    if (ticketId.isEmpty) return null;
    final imagesDir = await _imagesDirectory();
    if (!imagesDir.existsSync()) return null;

    try {
      await for (final entity in imagesDir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final dot = name.lastIndexOf('.');
        final base = dot > 0 ? name.substring(0, dot) : name;
        if (base == ticketId && entity.existsSync()) {
          return entity.path;
        }
      }
    } on FileSystemException {
      return null;
    }
    return null;
  }
}
