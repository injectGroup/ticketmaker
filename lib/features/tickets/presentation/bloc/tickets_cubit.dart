import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_cloud_sync.dart';
import '../../data/ticket_image_codec.dart';
import '../../data/ticket_image_store.dart';
import '../../data/ticket_local_repository.dart';
import '../../data/ticket_network_image.dart';
import '../../data/ticket_payload.dart';

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
      final withVerifyUrls = repaired
          .map(_withCanonicalVerifyUrl)
          .map(_withoutStorageUrls)
          .toList(growable: false);
      final changed = withVerifyUrls.length == loaded.length &&
          (!_sameImagePaths(loaded, withVerifyUrls) ||
              !_sameQrData(loaded, withVerifyUrls));
      if (changed) {
        await _repository.saveTickets(withVerifyUrls);
      }
      final restoredBytes = await _restorePersistedEventPhotos(withVerifyUrls);
      emit(
        state.copyWith(
          tickets: withVerifyUrls,
          isLoading: false,
          imageBytesById: restoredBytes,
        ),
      );
      // Warm MemoryImage cache for http(s) event photos (CORS-safe capture).
      unawaited(_prefetchNetworkEventPhotos(withVerifyUrls));
      // Ensure older local tickets exist in tickets/{code} for /verify.
      unawaited(_backfillPublicTickets(withVerifyUrls));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Could not load saved tickets',
        ),
      );
    }
  }

  Future<void> _backfillPublicTickets(List<Ticket> tickets) async {
    for (final ticket in tickets) {
      try {
        await _cloudSync.publishPublicTicket(ticket);
      } catch (e, st) {
        debugPrint('Public ticket backfill failed for ${ticket.code}: $e\n$st');
      }
    }
  }

  /// Reloads durable event photos (web SharedPreferences / native files) into
  /// [TicketsState.imageBytesById] so widgets paint [Image.memory].
  Future<Map<String, Uint8List>> _restorePersistedEventPhotos(
    List<Ticket> tickets,
  ) async {
    final next = Map<String, Uint8List>.from(state.imageBytesById);
    for (final ticket in tickets) {
      if (next[ticket.id]?.isNotEmpty == true) continue;
      final fromStore = await _imageStore.loadBytesForTicket(ticket.id);
      if (fromStore != null && fromStore.isNotEmpty) {
        next[ticket.id] = fromStore;
        continue;
      }
      final path = ticket.photoUrl.trim();
      if (TicketImageStore.isWebBytesPath(path)) {
        final id =
            TicketImageStore.ticketIdFromWebBytesPath(path) ?? ticket.id;
        final bytes = await _imageStore.loadBytesForTicket(id);
        if (bytes != null && bytes.isNotEmpty) {
          next[ticket.id] = bytes;
        }
      }
    }
    return next;
  }

  /// Fetches data-URL / non-Storage http photos into [TicketsState.imageBytesById].
  Future<void> _prefetchNetworkEventPhotos(List<Ticket> tickets) async {
    final next = Map<String, Uint8List>.from(state.imageBytesById);
    var changed = false;
    for (final ticket in tickets) {
      if (next[ticket.id]?.isNotEmpty == true) continue;
      final path = ticket.photoUrl.trim();
      if (path.startsWith('data:')) {
        final decoded = decodeDataUrlBytes(path);
        if (decoded == null || decoded.isEmpty) continue;
        next[ticket.id] = decoded;
        changed = true;
        continue;
      }
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        continue;
      }
      if (TicketCloudSync.isFirebaseStorageUrl(path)) continue;
      final bytes = await fetchImageBytesCorsSafe(path);
      if (bytes == null || bytes.isEmpty) continue;
      next[ticket.id] = bytes;
      changed = true;
      try {
        await _imageStore.persistForTicket(
          ticketId: ticket.id,
          sourcePath: 'ticket.jpg',
          bytes: bytes,
        );
      } catch (_) {}
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
    // Never persist ephemeral web blob: picker URLs.
    var saved = ticket.copyWith(
      id: id,
      imagePath: sanitizeTicketImagePath(ticket.imagePath),
      qrData: TicketPayload.verificationUrl(ticket.code),
    );

    final nextBytes = Map<String, Uint8List>.from(state.imageBytesById);
    if (imageBytes != null && imageBytes.isNotEmpty) {
      nextBytes[id] = imageBytes;
      try {
        final jpeg = await compressImageToJpeg(imageBytes);
        final durable = await _imageStore.persistForTicket(
          ticketId: id,
          sourcePath: 'ticket.jpg',
          bytes: jpeg,
        );
        if (durable.isNotEmpty) {
          saved = saved.copyWith(imagePath: durable);
          nextBytes[id] = jpeg;
        }
      } catch (e, st) {
        debugPrint('Could not persist ticket photo locally: $e\n$st');
      }
    }

    final updated = [saved, ...state.tickets];

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

    // Public verify doc must exist before the QR is scannable.
    final published = await _cloudSync.publishPublicTicket(saved);
    if (!published && !isClosed) {
      try {
        if (Firebase.apps.isNotEmpty) {
          emit(
            state.copyWith(
              message:
                  'Ticket saved locally, but cloud verify link failed. Check connection and try Save again.',
            ),
          );
        }
      } catch (_) {
        // Firebase not available (tests) — keep local success message.
      }
    }

    // Owner photo embed / private doc (non-blocking).
    unawaited(
      _persistImageAndCloudInBackground(
        saved,
        nextBytes[id] ?? imageBytes,
      ),
    );
  }

  /// Door entrance: decode QR/manual payload, verify against host tickets,
  /// and mark valid unused tickets as checked in.
  Future<TicketVerifyResult> verifyAndCheckIn(String rawPayload) async {
    final code = TicketPayload.parseCode(rawPayload);
    if (code == null) {
      return const TicketVerifyResult(
        status: TicketVerifyStatus.invalidPayload,
      );
    }

    Ticket? match;
    for (final ticket in state.tickets) {
      if (ticket.code == code) {
        match = ticket;
        break;
      }
    }
    match ??= await _cloudSync.findTicketByCode(code);

    if (match == null) {
      return TicketVerifyResult(
        status: TicketVerifyStatus.notFound,
        code: code,
      );
    }

    if (match.isCheckedIn) {
      return TicketVerifyResult(
        status: TicketVerifyStatus.alreadyCheckedIn,
        ticket: match,
        code: code,
      );
    }

    final checkedInAt = DateTime.now();
    final updated = match.copyWith(checkedInAt: checkedInAt);

    final index = state.tickets.indexWhere((t) => t.id == updated.id);
    final next = [...state.tickets];
    if (index >= 0) {
      next[index] = updated;
    } else {
      next.insert(0, updated);
    }

    try {
      await _repository.saveTickets(next);
      emit(state.copyWith(tickets: next));
    } catch (e, st) {
      debugPrint('Local check-in persist failed: $e\n$st');
    }

    unawaited(
      _cloudSync.markCheckedIn(ticket: updated, checkedInAt: checkedInAt),
    );

    return TicketVerifyResult(
      status: TicketVerifyStatus.success,
      ticket: updated,
      code: code,
    );
  }

  /// Compresses the event photo locally and syncs the owner Firestore doc.
  /// Public verify doc is published separately (awaited) during [saveTicket].
  Future<void> _persistImageAndCloudInBackground(
    Ticket ticket,
    Uint8List? imageBytes,
  ) async {
    Uint8List? payload = imageBytes ?? state.imageBytesById[ticket.id];
    if ((payload == null || payload.isEmpty) &&
        ticket.imagePath.isNotEmpty &&
        ticket.imagePath.startsWith('data:')) {
      payload = decodeDataUrlBytes(ticket.imagePath);
    }
    if ((payload == null || payload.isEmpty) &&
        ticket.imagePath.isNotEmpty &&
        !kIsWeb &&
        !ticket.imagePath.startsWith('http') &&
        !TicketImageStore.isWebBytesPath(ticket.imagePath)) {
      try {
        final file = File(ticket.imagePath);
        if (file.existsSync()) {
          payload = await file.readAsBytes();
        }
      } catch (e, st) {
        debugPrint('Could not read ticket image for sync: $e\n$st');
      }
    }

    try {
      if (payload != null && payload.isNotEmpty) {
        final jpeg = await compressImageToJpeg(payload);

        final durable = await _imageStore.persistForTicket(
          ticketId: ticket.id,
          sourcePath: 'ticket.jpg',
          bytes: jpeg,
        );
        if (durable.isNotEmpty &&
            durable != ticket.imagePath &&
            !ticket.imagePath.startsWith('data:') &&
            !ticket.imagePath.startsWith('http')) {
          await _patchLocalImagePath(ticket.id, durable);
        }

        await _cloudSync.upsertTicketDocument(ticket, photoBytes: jpeg);
      } else {
        await _cloudSync.upsertTicketDocument(ticket);
      }
    } catch (e, st) {
      debugPrint('Ticket image / Firestore sync failed: $e\n$st');
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
        .expand((t) => [t.imagePath, t.id])
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
          .expand((t) => [t.imagePath, t.id])
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
        .expand((t) => [t.imagePath, t.id])
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
    final result = <Ticket>[];
    for (final ticket in tickets) {
      final path = ticket.imagePath.trim();
      // Drop ephemeral blob: picker URLs left from older web saves.
      if (path.startsWith('blob:')) {
        final found = await _imageStore.findExistingForTicket(ticket.id);
        result.add(
          ticket.copyWith(imagePath: found ?? ''),
        );
        continue;
      }
      if (kIsWeb) {
        result.add(ticket);
        continue;
      }
      if (path.isEmpty || path.startsWith('http')) {
        result.add(ticket);
        continue;
      }
      if (TicketImageStore.isWebBytesPath(path)) {
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

  bool _sameQrData(List<Ticket> a, List<Ticket> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].qrData != b[i].qrData) return false;
    }
    return true;
  }

  Ticket _withCanonicalVerifyUrl(Ticket ticket) {
    if (!TicketPayload.codePattern.hasMatch(ticket.code)) return ticket;
    final expected = TicketPayload.verificationUrl(ticket.code);
    if (ticket.qrData == expected) return ticket;
    return ticket.copyWith(qrData: expected);
  }

  Ticket _withoutStorageUrls(Ticket ticket) {
    final path = ticket.imagePath.trim();
    if (!TicketCloudSync.isFirebaseStorageUrl(path)) return ticket;
    return ticket.copyWith(imagePath: '');
  }
}
