import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches image bytes over HTTP so tickets can use [MemoryImage] on web.
///
/// Avoids CORS-tainted canvases from [Image.network]/[NetworkImage] during
/// [RepaintBoundary.toImage] on Flutter Web / CanvasKit.
Future<Uint8List?> fetchImageBytesCorsSafe(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return null;
  }

  try {
    final response = await http
        .get(Uri.parse(trimmed))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'fetchImageBytesCorsSafe HTTP ${response.statusCode} for $trimmed',
      );
      return null;
    }
    if (response.bodyBytes.isEmpty) return null;
    return response.bodyBytes;
  } catch (e, st) {
    debugPrint('fetchImageBytesCorsSafe failed: $e\n$st');
    return null;
  }
}
