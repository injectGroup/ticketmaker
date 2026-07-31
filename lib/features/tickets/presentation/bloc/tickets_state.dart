part of 'tickets_cubit.dart';

class TicketsState extends Equatable {
  const TicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.message,
    this.imageBytesById = const {},
  });

  final List<Ticket> tickets;
  final bool isLoading;
  final String? message;

  /// Session cache of ticket event photos (especially for Flutter Web).
  final Map<String, Uint8List> imageBytesById;

  Uint8List? imageBytesFor(String ticketId) => imageBytesById[ticketId];

  TicketsState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    Map<String, Uint8List>? imageBytesById,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      imageBytesById: imageBytesById ?? this.imageBytesById,
    );
  }

  @override
  List<Object?> get props => [tickets, isLoading, message, imageBytesById];
}
