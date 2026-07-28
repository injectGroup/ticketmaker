import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_cloud_sync.dart';
import '../../data/ticket_image_codec.dart';
import '../../data/ticket_image_store.dart';
import '../../data/ticket_local_repository.dart';
import '../../data/ticket_network_image.dart';

part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(
    this._repository, {
    TicketImageStore? imageStore,
    TicketCloudSync? cloudSync,
  }) : _imageStore = imageStore ?? TicketImageStore(),
       _cloudSync = cloudSync ?? TicketCloudSync(),
       super(const TicketsState());

  final TicketLocalRepository _repository;
  final TicketImageStore _imageStore;
  final TicketCloudSync _cloudSync;

  Future<void> loadTickets() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final loaded = await _repository.loadTickets();
      final repaired = await _repairMissingImagePaths(loaded);
      final changed = repaired.length == loaded.length &&
          !_sameImagePaths(loaded, repaired);
      if (changed) {
        await _repository.saveTickets(repaired);
      }
      emit(state.copyWith(tickets: repaired, isLoading: false));
      // Warm MemoryImage cache for http(s) event photos (CORS-safe capture).
      unawaited(_prefetchNetworkEventPhotos(repaired));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Could not load saved tickets',
        ),
      );
    }
  }

  /// Fetches remote event photos into [TicketsState.imageBytesById] so ticket
  /// widgets paint [Image.memory] instead of CORS-tainted [Image.network].
  Future<void> _prefetchNetworkEventPhotos(List<Ticket> tickets) async {
    final next = Map<String, Uint8List>.from(state.imageBytesById);
    var changed = false;
    for (final ticket in tickets) {
      if (next[ticket.id]?.isNotEmpty == true) continue;
      final path = ticket.imagePath.trim();
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        continue;
      }
      final bytes = await fetchImageBytesCorsSafe(path);
      if (bytes == null || bytes.isEmpty) continue;
      next[ticket.id] = bytes;
      changed = true;
    }
    if (!changed || isClosed) return;
    emit(state.copyWith(imageBytesById: next));
  }

  /// Saves ticket metadata immediately, then compresses/uploads the **event
  /// photo** in the background so the UI is not blocked.
  ///
  /// [imageBytes] is the event gallery image for [SavedTicketView]'s photo
  /// slot (and durable `imagePath`). Full-ticket share JPEGs are composed at
  /// share time — do not pass a full-ticket snapshot here.
  Future<void> saveTicket(
    Ticket ticket, {
    Uint8List? imageBytes,
  }) async {
    final id = 'ticket-${DateTime.now().millisecondsSinceEpoch}';
    final saved = ticket.copyWith(id: id);
    final updated = [saved, ...state.tickets];

    final nextBytes = Map<String, Uint8List>.from(state.imageBytesById);
    if (imageBytes != null && imageBytes.isNotEmpty) {
      nextBytes[id] = imageBytes;
    }

    try {
      await _repository.saveTickets(updated);
      emit(
        state.copyWith(
          tickets: updated,
          imageBytesById: nextBytes,
          message: 'Ticket saved successfully!',
        ),
      );
    } catch (e, st) {
      debugPrint('Ticket save failed: $e\n$st');
      emit(state.copyWith(message: 'Could not save ticket'));
      rethrow;
    }

    // Firestore doc + JPEG compress + Storage upload (non-blocking).
    // Guests / web: failures here must never fail the local save above.
    unawaited(_persistImageAndCloudInBackground(saved, imageBytes));
  }

  /// Compresses/uploads the event photo (not a full-ticket composite).
  /// Falls back to reading a local [Ticket.imagePath] file when bytes are
  /// missing. Share/download always re-renders [SavedTicketView] instead of
  /// using these bytes as the ticket file.
  Future<void> _persistImageAndCloudInBackground(
    Ticket ticket,
    Uint8List? imageBytes,
  ) async {
    try {
      await _cloudSync.upsertTicketDocument(ticket);
    } catch (e, st) {
      debugPrint('Ticket Firestore upsert failed: $e\n$st');
    }

    Uint8List? payload = imageBytes ?? state.imageBytesById[ticket.id];
    if ((payload == null || payload.isEmpty) &&
        ticket.imagePath.isNotEmpty &&
        !kIsWeb &&
        !ticket.imagePath.startsWith('http')) {
      try {
        final file = File(ticket.imagePath);
        if (file.existsSync()) {
          payload = await file.readAsBytes();
        }
      } catch (e, st) {
        debugPrint('Could not read ticket image for upload: $e\n$st');
      }
    }

    if (payload == null || payload.isEmpty) {
      debugPrint('No ticket image bytes to upload for ${ticket.id}');
      return;
    }

    try {
      final jpeg = await compressImageToJpeg(payload);
      if (!kIsWeb) {
        final durable = await _imageStore.persistForTicket(
          ticketId: ticket.id,
          sourcePath: 'ticket.jpg',
          bytes: jpeg,
        );
        if (durable.isNotEmpty) {
          await _patchLocalImagePath(ticket.id, durable);
        }
      }

      final url = await _cloudSync.uploadTicketImageJpeg(
        ticketId: ticket.id,
        jpegBytes: jpeg,
      );
      if (url != null && url.isNotEmpty) {
        await _patchLocalImagePath(ticket.id, url);
      }
    } catch (e, st) {
      debugPrint('Ticket image compress/upload failed: $e\n$st');
    }
  }

  Future<void> _patchLocalImagePath(String ticketId, String imagePath) async {
    final index = state.tickets.indexWhere((t) => t.id == ticketId);
    if (index < 0) return;
    final patched = state.tickets[index].copyWith(imagePath: imagePath);
    final next = [...state.tickets];
    next[index] = patched;
    try {
      await _repository.saveTickets(next);
      emit(state.copyWith(tickets: next));
    } catch (e, st) {
      debugPrint('Could not patch local imagePath: $e\n$st');
    }
  }

  /// Wipes persisted tickets and their durable images; emits an empty list.
  /// Prefs/list clear always runs even if image cleanup fails.
  Future<void> clearAllTickets() async {
    if (state.tickets.isEmpty) {
      emit(state.copyWith(tickets: const [], message: 'All tickets cleared'));
      return;
    }
    final imagePaths = state.tickets
        .map((t) => t.imagePath)
        .where((p) => p.isNotEmpty);
    try {
      await _imageStore.deleteStoredImages(imagePaths);
    } catch (_) {
      // Best-effort image cleanup; still clear persisted tickets below.
    }
    try {
      await _repository.clearTickets();
      emit(
        state.copyWith(tickets: const [], message: 'All tickets cleared'),
      );
    } catch (_) {
      emit(state.copyWith(message: 'Could not clear tickets'));
    }
  }

  /// Removes tickets by [ids]. Returns the removed tickets (for undo).
  /// When [deleteImages] is false, durable photos are left on disk.
  Future<List<Ticket>> deleteTickets(
    Iterable<String> ids, {
    bool deleteImages = true,
    String? message,
  }) async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return const [];

    final removed = state.tickets
        .where((ticket) => idSet.contains(ticket.id))
        .toList(growable: false);
    if (removed.isEmpty) return const [];

    final updated = state.tickets
        .where((ticket) => !idSet.contains(ticket.id))
        .toList(growable: false);

    if (deleteImages) {
      final imagePaths = removed
          .map((t) => t.imagePath)
          .where((p) => p.isNotEmpty);
      try {
        await _imageStore.deleteStoredImages(imagePaths);
      } catch (_) {
        // Best-effort image cleanup; still update persisted list below.
      }
    }

    try {
      await _repository.saveTickets(updated);
      emit(
        state.copyWith(
          tickets: updated,
          message: message,
          clearMessage: message == null,
        ),
      );
      return removed;
    } catch (_) {
      emit(state.copyWith(message: 'Could not delete tickets'));
      return const [];
    }
  }

  /// Re-inserts [tickets] into the list (e.g. snackbar undo after swipe delete).
  Future<void> restoreTickets(
    List<Ticket> tickets, {
    int? atIndex,
  }) async {
    if (tickets.isEmpty) return;
    final existingIds = state.tickets.map((t) => t.id).toSet();
    final toRestore =
        tickets.where((t) => !existingIds.contains(t.id)).toList();
    if (toRestore.isEmpty) return;

    final updated = [...state.tickets];
    final index = (atIndex == null)
        ? 0
        : atIndex.clamp(0, updated.length);
    updated.insertAll(index, toRestore);

    try {
      await _repository.saveTickets(updated);
      emit(
        state.copyWith(
          tickets: updated,
          message: toRestore.length == 1 ? 'Ticket restored' : 'Tickets restored',
        ),
      );
    } catch (_) {
      emit(state.copyWith(message: 'Could not restore tickets'));
    }
  }

  /// Deletes durable images for tickets previously soft-removed (after undo window).
  Future<void> discardTicketImages(Iterable<Ticket> tickets) async {
    final imagePaths = tickets
        .map((t) => t.imagePath)
        .where((p) => p.isNotEmpty);
    if (imagePaths.isEmpty) return;
    try {
      await _imageStore.deleteStoredImages(imagePaths);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }

  Future<List<Ticket>> _repairMissingImagePaths(List<Ticket> tickets) async {
    if (kIsWeb) return tickets;
    final result = <Ticket>[];
    for (final ticket in tickets) {
      final path = ticket.imagePath;
      if (path.isEmpty || path.startsWith('http')) {
        result.add(ticket);
        continue;
      }
      if (File(path).existsSync()) {
        result.add(ticket);
        continue;
      }
      final found = await _imageStore.findExistingForTicket(ticket.id);
      if (found != null && found.isNotEmpty) {
        result.add(ticket.copyWith(imagePath: found));
      } else {
        result.add(ticket);
      }
    }
    return result;
  }

  bool _sameImagePaths(List<Ticket> a, List<Ticket> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].imagePath != b[i].imagePath) return false;
    }
    return true;
  }
}
