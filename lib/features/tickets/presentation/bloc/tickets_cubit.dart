import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_image_store.dart';
import '../../data/ticket_local_repository.dart';

part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._repository, {TicketImageStore? imageStore})
    : _imageStore = imageStore ?? TicketImageStore(),
      super(const TicketsState());

  final TicketLocalRepository _repository;
  final TicketImageStore _imageStore;

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
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Could not load saved tickets',
        ),
      );
    }
  }

  /// Serializes [ticket] to JSON via the repository and refreshes list state.
  Future<void> saveTicket(Ticket ticket) async {
    final id = 'ticket-${DateTime.now().millisecondsSinceEpoch}';
    var imagePath = ticket.imagePath;
    var photoWarning = false;

    if (imagePath.isNotEmpty) {
      final durable = await _imageStore.persistForTicket(
        sourcePath: imagePath,
        ticketId: id,
      );
      if (durable.isNotEmpty) {
        imagePath = durable;
      } else {
        // Never wipe imagePath on a failed persist.
        photoWarning = true;
      }
    }

    final saved = ticket.copyWith(id: id, imagePath: imagePath);
    final updated = [saved, ...state.tickets];
    try {
      await _repository.saveTickets(updated);
      emit(
        state.copyWith(
          tickets: updated,
          message: photoWarning
              ? 'Ticket saved, but photo could not be stored'
              : 'Ticket saved',
        ),
      );
    } catch (_) {
      emit(state.copyWith(message: 'Could not save ticket'));
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
    final result = <Ticket>[];
    for (final ticket in tickets) {
      final path = ticket.imagePath;
      if (path.isEmpty) {
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
