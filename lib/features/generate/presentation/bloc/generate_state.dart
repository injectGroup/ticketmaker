part of 'generate_cubit.dart';

class GenerateState extends Equatable {
  const GenerateState({
    required this.ticket,
    this.message,
    this.selectedCategory,
    this.imageBytes,
  });

  final Ticket ticket;
  final String? message;
  final String? selectedCategory;

  /// In-memory gallery bytes for Flutter Web (and Instant preview).
  final Uint8List? imageBytes;

  GenerateState copyWith({
    Ticket? ticket,
    String? message,
    bool clearMessage = false,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    Uint8List? imageBytes,
    bool clearImageBytes = false,
  }) {
    return GenerateState(
      ticket: ticket ?? this.ticket,
      message: clearMessage ? null : (message ?? this.message),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      imageBytes: clearImageBytes ? null : (imageBytes ?? this.imageBytes),
    );
  }

  @override
  List<Object?> get props => [ticket, message, selectedCategory, imageBytes];
}
