import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generate/domain/entities/ticket.dart';
import '../../data/ticket_local_repository.dart';

part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._repository) : super(const TicketsState());

  final TicketLocalRepository _repository;

  Future<void> loadTickets() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final tickets = await _repository.loadTickets();
      emit(state.copyWith(tickets: tickets, isLoading: false));
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
    final saved = ticket.copyWith(
      id: 'ticket-${DateTime.now().millisecondsSinceEpoch}',
    );
    final updated = [saved, ...state.tickets];
    try {
      await _repository.saveTickets(updated);
      emit(state.copyWith(tickets: updated, message: 'Ticket saved'));
    } catch (_) {
      emit(state.copyWith(message: 'Could not save ticket'));
    }
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }
}
