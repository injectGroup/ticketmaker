part of 'generate_cubit.dart';

class GenerateState extends Equatable {
  const GenerateState({
    required this.ticket,
    this.message,
    this.selectedCategory,
  });

  final Ticket ticket;
  final String? message;
  final String? selectedCategory;

  GenerateState copyWith({
    Ticket? ticket,
    String? message,
    bool clearMessage = false,
    String? selectedCategory,
    bool clearSelectedCategory = false,
  }) {
    return GenerateState(
      ticket: ticket ?? this.ticket,
      message: clearMessage ? null : (message ?? this.message),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  List<Object?> get props => [ticket, message, selectedCategory];
}
