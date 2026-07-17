part of 'tickets_cubit.dart';

class TicketsState extends Equatable {
  const TicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.message,
  });

  final List<Ticket> tickets;
  final bool isLoading;
  final String? message;

  TicketsState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [tickets, isLoading, message];
}
