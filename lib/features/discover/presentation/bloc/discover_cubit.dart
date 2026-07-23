import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/event_catalog.dart';
import '../../data/geolocator_city_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/location_city_service.dart';

part 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({LocationCityService? locationCityService})
    : _locationCityService = locationCityService ?? GeolocatorCityService(),
      super(const DiscoverState()) {
    loadEvents();
  }

  final LocationCityService _locationCityService;

  Future<void> loadEvents() async {
    emit(
      state.copyWith(
        isLoading: true,
        locationStatus: DiscoverLocationStatus.detecting,
      ),
    );

    final events = EventCatalog.all();
    final cities = EventCatalog.cities();

    String selectedCity = EventCatalog.defaultCity;
    var locationStatus = DiscoverLocationStatus.denied;

    try {
      final detected = await _locationCityService.resolveCity();
      if (detected != null && detected.trim().isNotEmpty) {
        final match = _matchCatalogCity(detected, cities);
        if (match != null) {
          selectedCity = match;
          locationStatus = DiscoverLocationStatus.granted;
        } else {
          selectedCity = EventCatalog.defaultCity;
          locationStatus = DiscoverLocationStatus.denied;
        }
      }
    } catch (_) {
      locationStatus = DiscoverLocationStatus.denied;
      selectedCity = EventCatalog.defaultCity;
    }

    emit(
      state.copyWith(
        allEvents: events,
        availableCities: cities,
        selectedCity: selectedCity,
        locationStatus: locationStatus,
        filteredEvents: _filter(events, state.query, selectedCity),
        isLoading: false,
      ),
    );
  }

  void updateQuery(String query) {
    emit(
      state.copyWith(
        query: query,
        filteredEvents: _filter(state.allEvents, query, state.selectedCity),
      ),
    );
  }

  void selectCity(String city) {
    if (city == state.selectedCity) return;
    emit(
      state.copyWith(
        selectedCity: city,
        locationStatus: DiscoverLocationStatus.manual,
        filteredEvents: _filter(state.allEvents, state.query, city),
      ),
    );
  }

  static String? _matchCatalogCity(String detected, List<String> cities) {
    final needle = detected.trim().toLowerCase();
    for (final city in cities) {
      final c = city.toLowerCase();
      if (c == needle || needle.contains(c) || c.contains(needle)) {
        return city;
      }
    }
    if (needle.contains('fct') || needle.contains('federal capital')) {
      for (final city in cities) {
        if (city.toLowerCase() == 'abuja') return city;
      }
    }
    return null;
  }

  static List<Event> _filter(
    List<Event> events,
    String query,
    String selectedCity,
  ) {
    final byCity = events.where(
      (event) => event.city.toLowerCase() == selectedCity.toLowerCase(),
    );
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Event>.unmodifiable(byCity);
    return List<Event>.unmodifiable(
      byCity.where((event) {
        return event.title.toLowerCase().contains(q) ||
            event.venue.toLowerCase().contains(q) ||
            event.category.toLowerCase().contains(q) ||
            event.description.toLowerCase().contains(q) ||
            event.host.toLowerCase().contains(q) ||
            event.city.toLowerCase().contains(q);
      }),
    );
  }
}
