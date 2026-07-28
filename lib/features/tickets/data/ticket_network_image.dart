import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/ticket_photo_placeholder.dart';

/// In-memory cache so ticket photos are not re-fetched every rebuild.
final Map<String, Uint8List> _networkImageBytesCache = {};

/// Fetches image bytes so tickets can paint with [MemoryImage] on web.
///
/// Avoids CORS-tainted canvases from [Image.network]/[NetworkImage] during
/// [RepaintBoundary.toImage] on Flutter Web / CanvasKit.
///
/// Order: cache → `http.get` → Firebase Storage [Reference.getData] for
/// `firebasestorage.googleapis.com` / `gs://` URLs.
Future<Uint8List?> fetchImageBytesCorsSafe(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.startsWith('http://') &&
      !trimmed.startsWith('https://') &&
      !trimmed.startsWith('gs://')) {
    return null;
  }

  final cached = _networkImageBytesCache[trimmed];
  if (cached != null && cached.isNotEmpty) return cached;

  Uint8List? bytes = await _fetchViaHttp(trimmed);
  bytes ??= await _fetchViaFirebaseStorage(trimmed);

  if (bytes != null && bytes.isNotEmpty) {
    _networkImageBytesCache[trimmed] = bytes;
  }
  return bytes;
}

Future<Uint8List?> _fetchViaHttp(String url) async {
  if (url.startsWith('gs://')) return null;
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'fetchImageBytesCorsSafe HTTP ${response.statusCode} for $url',
      );
      return null;
    }
    if (response.bodyBytes.isEmpty) return null;
    return response.bodyBytes;
  } catch (e, st) {
    debugPrint('fetchImageBytesCorsSafe HTTP failed: $e\n$st');
    return null;
  }
}

Future<Uint8List?> _fetchViaFirebaseStorage(String url) async {
  final isFirebaseUrl = url.startsWith('gs://') ||
      url.contains('firebasestorage.googleapis.com') ||
      url.contains('firebasestorage.app');
  if (!isFirebaseUrl) return null;

  try {
    final data = await FirebaseStorage.instance
        .refFromURL(url)
        .getData(15 * 1024 * 1024)
        .timeout(const Duration(seconds: 20));
    if (data == null || data.isEmpty) return null;
    return data;
  } catch (e, st) {
    debugPrint('fetchImageBytesCorsSafe Storage getData failed: $e\n$st');
    return null;
  }
}

/// Loads a remote ticket photo as bytes, then paints [Image.memory].
///
/// On Flutter Web this is required so [RepaintBoundary.toImage] is not
/// blocked by a CORS-tainted canvas from [Image.network].
class TicketCorsSafeNetworkImage extends StatefulWidget {
  const TicketCorsSafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<TicketCorsSafeNetworkImage> createState() =>
      _TicketCorsSafeNetworkImageState();
}

class _TicketCorsSafeNetworkImageState extends State<TicketCorsSafeNetworkImage> {
  Future<Uint8List?>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = fetchImageBytesCorsSafe(widget.url);
  }

  @override
  void didUpdateWidget(covariant TicketCorsSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytesFuture = fetchImageBytesCorsSafe(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return TicketPhotoPlaceholder(
            width: width ?? 300,
            height: height ?? 200,
            broken: true,
          );
        }

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => TicketPhotoPlaceholder(
            width: width ?? 300,
            height: height ?? 200,
            broken: true,
          ),
        );
      },
    );
  }
}
