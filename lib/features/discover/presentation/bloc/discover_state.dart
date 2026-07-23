part of 'discover_cubit.dart';

enum DiscoverLocationStatus { detecting, granted, denied, manual }

class DiscoverState extends Equatable {
  const DiscoverState({
    this.allEvents = const [],
    this.filteredEvents = const [],
    this.availableCities = const [],
    this.selectedCity = EventCatalog.defaultCity,
    this.query = '',
    this.isLoading = false,
    this.locationStatus = DiscoverLocationStatus.detecting,
  });

  final List<Event> allEvents;
  final List<Event> filteredEvents;
  final List<String> availableCities;
  final String selectedCity;
  final String query;
  final bool isLoading;
  final DiscoverLocationStatus locationStatus;

  DiscoverState copyWith({
    List<Event>? allEvents,
    List<Event>? filteredEvents,
    List<String>? availableCities,
    String? selectedCity,
    String? query,
    bool? isLoading,
    DiscoverLocationStatus? locationStatus,
  }) {
    return DiscoverState(
      allEvents: allEvents ?? this.allEvents,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      availableCities: availableCities ?? this.availableCities,
      selectedCity: selectedCity ?? this.selectedCity,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      locationStatus: locationStatus ?? this.locationStatus,
    );
  }

  @override
  List<Object?> get props => [
    allEvents,
    filteredEvents,
    availableCities,
    selectedCity,
    query,
    isLoading,
    locationStatus,
  ];
}
