part of 'generate_cubit.dart';

class GenerateState extends Equatable {
  const GenerateState({
    required this.ticket,
    this.message,
  });

  final Ticket ticket;
  final String? message;

  GenerateState copyWith({
    Ticket? ticket,
    String? message,
    bool clearMessage = false,
  }) {
    return GenerateState(
      ticket: ticket ?? this.ticket,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [ticket, message];
}
