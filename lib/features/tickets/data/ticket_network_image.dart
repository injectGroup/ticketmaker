import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/ticket_photo_placeholder.dart';
import 'ticket_cloud_sync.dart';
import 'ticket_image_store.dart';

/// In-memory cache so ticket photos are not re-fetched every rebuild.
final Map<String, Uint8List> _networkImageBytesCache = {};

/// True when [url] is a fetchable http(s) / data URL (not Storage / blob / empty).
bool isFetchableTicketPhotoUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('blob:')) return false;
  if (TicketImageStore.isWebBytesPath(trimmed)) return false;
  if (TicketCloudSync.isFirebaseStorageUrl(trimmed)) return false;
  if (trimmed.startsWith('data:')) return true;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return true;
  }
  return false;
}

/// Decodes a `data:image/...;base64,...` URL into bytes.
Uint8List? decodeDataUrlBytes(String dataUrl) {
  final trimmed = dataUrl.trim();
  if (!trimmed.startsWith('data:')) return null;
  final comma = trimmed.indexOf(',');
  if (comma < 0) return null;
  final meta = trimmed.substring(0, comma);
  if (!meta.contains(';base64')) return null;
  try {
    final decoded = base64Decode(trimmed.substring(comma + 1));
    return decoded.isEmpty ? null : Uint8List.fromList(decoded);
  } catch (_) {
    return null;
  }
}

/// Fetches image bytes so tickets can paint with [MemoryImage].
///
/// Never calls Firebase Storage (Spark plan / no bucket). Order:
/// cache → data URL → optional non-Storage `http.get`.
Future<Uint8List?> fetchImageBytesCorsSafe(String url) async {
  final trimmed = url.trim();
  if (!isFetchableTicketPhotoUrl(trimmed)) return null;

  final cached = _networkImageBytesCache[trimmed];
  if (cached != null && cached.isNotEmpty) return cached;

  if (trimmed.startsWith('data:')) {
    final decoded = decodeDataUrlBytes(trimmed);
    if (decoded != null && decoded.isNotEmpty) {
      _networkImageBytesCache[trimmed] = decoded;
    }
    return decoded;
  }

  final bytes = await _fetchViaHttp(trimmed);
  if (bytes != null && bytes.isNotEmpty) {
    _networkImageBytesCache[trimmed] = bytes;
  }
  return bytes;
}

Future<Uint8List?> _fetchViaHttp(String url) async {
  if (TicketCloudSync.isFirebaseStorageUrl(url)) return null;
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

/// Loads a remote / data-URL ticket photo as bytes, then paints [Image.memory].
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
    _bytesFuture = _load();
  }

  @override
  void didUpdateWidget(covariant TicketCorsSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytesFuture = _load();
    }
  }

  Future<Uint8List?> _load() {
    if (!isFetchableTicketPhotoUrl(widget.url)) {
      return Future<Uint8List?>.value(null);
    }
    return fetchImageBytesCorsSafe(widget.url).catchError((Object e, StackTrace st) {
      debugPrint('TicketCorsSafeNetworkImage catchError: $e\n$st');
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    if (!isFetchableTicketPhotoUrl(widget.url)) {
      return TicketPhotoPlaceholder(
        width: width ?? 300,
        height: height ?? 200,
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'TicketCorsSafeNetworkImage load error: ${snapshot.error}',
          );
          return TicketPhotoPlaceholder(
            width: width ?? 300,
            height: height ?? 200,
            broken: true,
          );
        }

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
          alignment: Alignment.center,
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
