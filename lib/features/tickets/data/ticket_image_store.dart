import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copies ticket images into durable storage.
///
/// - **Native:** files under app-documents `/ticket_images`.
/// - **Web:** JPEG/PNG bytes in SharedPreferences (base64), referenced by
///   synthetic paths `web-bytes:<ticketId>` so tickets survive reloads without
///   relying on ephemeral `blob:` picker URLs.
class TicketImageStore {
  TicketImageStore({
    Directory? overrideImagesDirectory,
    SharedPreferences? preferences,
  }) : _overrideImagesDirectory = overrideImagesDirectory,
       _preferences = preferences;

  static const String folderName = 'ticket_images';
  static const String webBytesPrefix = 'web-bytes:';
  static const String _webPrefsPrefix = 'ticket_image_bytes_';

  final Directory? _overrideImagesDirectory;
  SharedPreferences? _preferences;

  /// True when [path] is a durable web-bytes preference marker.
  static bool isWebBytesPath(String path) =>
      path.trim().startsWith(webBytesPrefix);

  /// Ticket id embedded in a `web-bytes:<id>` path, or null.
  static String? ticketIdFromWebBytesPath(String path) {
    final trimmed = path.trim();
    if (!trimmed.startsWith(webBytesPrefix)) return null;
    final id = trimmed.substring(webBytesPrefix.length).trim();
    return id.isEmpty ? null : id;
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

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
    if (sourcePath.isEmpty || kIsWeb) return null;
    final source = File(sourcePath);
    if (!source.existsSync()) return null;
    try {
      return await source.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  Future<String> _persistWebBytes({
    required String ticketId,
    required Uint8List bytes,
  }) async {
    final prefs = await _prefs();
    await prefs.setString('$_webPrefsPrefix$ticketId', base64Encode(bytes));
    return '$webBytesPrefix$ticketId';
  }

  /// Loads bytes previously stored for [ticketId] (web prefs or native file).
  Future<Uint8List?> loadBytesForTicket(String ticketId) async {
    if (ticketId.isEmpty) return null;
    if (kIsWeb) {
      final prefs = await _prefs();
      final encoded = prefs.getString('$_webPrefsPrefix$ticketId');
      if (encoded == null || encoded.isEmpty) return null;
      try {
        final decoded = base64Decode(encoded);
        return decoded.isEmpty ? null : Uint8List.fromList(decoded);
      } catch (_) {
        return null;
      }
    }
    final found = await findExistingForTicket(ticketId);
    if (found == null) return null;
    return _readBytes(found);
  }

  /// Writes [bytes] (or reads from [sourcePath]) into durable storage with a
  /// unique name. Returns the durable path, or `''` on failure.
  Future<String> import({
    String sourcePath = '',
    Uint8List? bytes,
  }) async {
    if (kIsWeb) return '';
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

  /// Writes bytes under a stable `ticketId` filename (or web prefs key).
  /// Returns the durable path / `web-bytes:` marker, or `''` on failure.
  Future<String> persistForTicket({
    required String ticketId,
    String sourcePath = '',
    Uint8List? bytes,
  }) async {
    if (ticketId.isEmpty) return '';
    final payload = bytes ?? await _readBytes(sourcePath);
    if (payload == null || payload.isEmpty) return '';

    if (kIsWeb) {
      return _persistWebBytes(ticketId: ticketId, bytes: payload);
    }

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

  /// Deletes durable image files / web prefs for the given [imagePaths].
  /// Also accepts raw ticket ids to clear web-bytes entries.
  Future<void> deleteStoredImages(Iterable<String> imagePaths) async {
    final paths = imagePaths.where((p) => p.isNotEmpty).toList(growable: false);
    if (paths.isEmpty) return;

    if (kIsWeb) {
      final prefs = await _prefs();
      for (final path in paths) {
        final id = ticketIdFromWebBytesPath(path) ??
            (path.startsWith('ticket-') && !path.contains('/') ? path : null);
        if (id != null) {
          await prefs.remove('$_webPrefsPrefix$id');
        }
      }
      return;
    }

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
    if (kIsWeb) {
      final prefs = await _prefs();
      if (prefs.containsKey('$_webPrefsPrefix$ticketId')) {
        return '$webBytesPrefix$ticketId';
      }
      return null;
    }
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

/// Returns true when [path] can be used as a durable ticket photo reference.
bool isDurableTicketImagePath(String path) {
  final p = path.trim();
  if (p.isEmpty) return false;
  if (p.startsWith('blob:')) return false;
  // Spark plan: never persist Firebase Storage URLs / gs:// refs.
  if (p.startsWith('gs://')) return false;
  if (p.contains('firebasestorage.googleapis.com') ||
      p.contains('firebasestorage.app')) {
    return false;
  }
  if (TicketImageStore.isWebBytesPath(p)) return true;
  if (p.startsWith('data:')) return true;
  if (p.startsWith('http://') || p.startsWith('https://')) return true;
  if (kIsWeb) return false;
  return true;
}

/// Strips ephemeral picker paths and Storage URLs before persisting tickets.
String sanitizeTicketImagePath(String path) {
  final trimmed = path.trim();
  return isDurableTicketImagePath(trimmed) ? trimmed : '';
}
