part of 'discover_cubit.dart';

class DiscoverState extends Equatable {
  const DiscoverState({
    this.allEvents = const [],
    this.filteredEvents = const [],
    this.query = '',
    this.isLoading = false,
  });

  final List<Event> allEvents;
  final List<Event> filteredEvents;
  final String query;
  final bool isLoading;

  DiscoverState copyWith({
    List<Event>? allEvents,
    List<Event>? filteredEvents,
    String? query,
    bool? isLoading,
  }) {
    return DiscoverState(
      allEvents: allEvents ?? this.allEvents,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [allEvents, filteredEvents, query, isLoading];
}
