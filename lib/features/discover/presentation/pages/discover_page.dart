import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/discover_cubit.dart';
import '../widgets/discover_event_card.dart';
import '../widgets/event_details_sheet.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  static const String routeName = 'discover';
  static const String routePath = '/discover';

  @override
  Widget build(BuildContext context) {
    return const _DiscoverView();
  }
}

class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: BlocBuilder<DiscoverCubit, DiscoverState>(
          buildWhen: (previous, current) =>
              previous.selectedCity != current.selectedCity,
          builder: (context, state) {
            return Text('Discover · ${state.selectedCity}');
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<DiscoverCubit, DiscoverState>(
                  buildWhen: (previous, current) =>
                      previous.selectedCity != current.selectedCity ||
                      previous.availableCities != current.availableCities ||
                      previous.locationStatus != current.locationStatus,
                  builder: (context, state) {
                    final nearYou =
                        state.locationStatus == DiscoverLocationStatus.granted;
                    return Row(
                      children: [
                        Icon(
                          nearYou
                              ? Icons.my_location
                              : Icons.location_city_outlined,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nearYou
                                ? 'Near you · ${state.selectedCity}'
                                : 'Showing · ${state.selectedCity}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        if (state.availableCities.isNotEmpty)
                          PopupMenuButton<String>(
                            tooltip: 'Switch city',
                            initialValue: state.selectedCity,
                            onSelected: context.read<DiscoverCubit>().selectCity,
                            itemBuilder: (context) {
                              return [
                                for (final city in state.availableCities)
                                  PopupMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ),
                              ];
                            },
                            child: Chip(
                              avatar: const Icon(Icons.place, size: 16),
                              label: Text(state.selectedCity),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                BlocBuilder<DiscoverCubit, DiscoverState>(
                  buildWhen: (previous, current) =>
                      previous.selectedCity != current.selectedCity,
                  builder: (context, state) {
                    return TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search ${state.selectedCity} events',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.secondaryBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchController.clear();
                                context.read<DiscoverCubit>().updateQuery('');
                              },
                              icon: const Icon(Icons.clear),
                            );
                          },
                        ),
                      ),
                      onChanged: context.read<DiscoverCubit>().updateQuery,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DiscoverCubit, DiscoverState>(
              builder: (context, state) {
                if (state.isLoading && state.filteredEvents.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.filteredEvents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.query.trim().isEmpty
                            ? 'No events in ${state.selectedCity} yet.'
                            : 'No events match “${state.query.trim()}”.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: state.filteredEvents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = state.filteredEvents[index];
                    return DiscoverEventCard(
                      event: event,
                      onTap: () => showEventDetailsSheet(
                        context,
                        event: event,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
