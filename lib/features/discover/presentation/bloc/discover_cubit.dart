import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/abuja_event_catalog.dart';
import '../../domain/entities/event.dart';

part 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit() : super(const DiscoverState()) {
    loadEvents();
  }

  void loadEvents() {
    emit(state.copyWith(isLoading: true));
    final events = AbujaEventCatalog.all();
    emit(
      state.copyWith(
        allEvents: events,
        filteredEvents: _filter(events, state.query),
        isLoading: false,
      ),
    );
  }

  void updateQuery(String query) {
    emit(
      state.copyWith(
        query: query,
        filteredEvents: _filter(state.allEvents, query),
      ),
    );
  }

  static List<Event> _filter(List<Event> events, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Event>.unmodifiable(events);
    return List<Event>.unmodifiable(
      events.where((event) {
        return event.title.toLowerCase().contains(q) ||
            event.venue.toLowerCase().contains(q) ||
            event.category.toLowerCase().contains(q) ||
            event.description.toLowerCase().contains(q) ||
            event.city.toLowerCase().contains(q);
      }),
    );
  }
}
