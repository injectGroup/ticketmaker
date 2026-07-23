import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/discover/domain/entities/event.dart';
import '../../features/discover/presentation/bloc/discover_cubit.dart';
import '../../features/discover/presentation/widgets/event_details_sheet.dart';
import '../../features/generate/presentation/bloc/generate_cubit.dart';
import '../../features/generate/presentation/pages/generate_page.dart';
import '../molecules/location_search_bar.dart';
import '../organisms/event_card_tile.dart';
import '../templates/discover_feed_template.dart';

/// Discover page: wires Cubit state into [DiscoverFeedTemplate] + [EventCardTile].
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  static const String routeName = 'discover';
  static const String routePath = '/discover';

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCity(DiscoverState state) async {
    final cities = state.availableCities;
    if (cities.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final city in cities)
                ListTile(
                  leading: Icon(
                    city == state.selectedCity
                        ? Icons.check_circle
                        : Icons.place_outlined,
                  ),
                  title: Text(city),
                  onTap: () => Navigator.of(sheetContext).pop(city),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    context.read<DiscoverCubit>().selectCity(selected);
  }

  void _bookSpot(BuildContext context, Event event) {
    context.read<GenerateCubit>().prefillFromEvent(event);
    context.go(GeneratePage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        final nearYou =
            state.locationStatus == DiscoverLocationStatus.granted;
        final emptyMessage = state.query.trim().isEmpty
            ? 'No events in ${state.selectedCity} yet.'
            : 'No events match “${state.query.trim()}”.';

        return DiscoverFeedTemplate(
          title: 'Discover · ${state.selectedCity}',
          isLoading: state.isLoading,
          isEmpty: state.filteredEvents.isEmpty,
          emptyMessage: emptyMessage,
          locationSearchBar: LocationSearchBar(
            controller: _searchController,
            hintText: 'Search ${state.selectedCity} events',
            locationLabel: state.selectedCity,
            nearYou: nearYou,
            onQueryChanged: context.read<DiscoverCubit>().updateQuery,
            onLocationTap: () => _pickCity(state),
            onClear: () => context.read<DiscoverCubit>().updateQuery(''),
          ),
          eventTiles: [
            for (final event in state.filteredEvents)
              EventCardTile(
                event: event,
                onTap: () => showEventDetailsSheet(context, event: event),
                onBookSpot: () => _bookSpot(context, event),
              ),
          ],
        );
      },
    );
  }
}
