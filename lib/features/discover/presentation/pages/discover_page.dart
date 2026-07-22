import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/discover_cubit.dart';
import '../widgets/discover_event_card.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  static const String routeName = 'discover';
  static const String routePath = '/discover';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoverCubit(),
      child: const _DiscoverView(),
    );
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
        title: const Text('Discover · Abuja'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Abuja events',
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
                    if (value.text.isEmpty) return const SizedBox.shrink();
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
                            ? 'No events in Abuja yet.'
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
                    return DiscoverEventCard(
                      event: state.filteredEvents[index],
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
