import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/ticket_category_palettes.dart';
import '../bloc/generate_cubit.dart';

/// Horizontal category chips that apply Generate ticket color palettes.
class TicketCategoryPaletteBar extends StatelessWidget {
  const TicketCategoryPaletteBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenerateCubit, GenerateState>(
      buildWhen: (previous, current) =>
          previous.selectedCategory != current.selectedCategory,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Event category palette',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: TicketCategoryPalettes.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = TicketCategoryPalettes.all[index];
                  final selected = state.selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => context
                        .read<GenerateCubit>()
                        .applyCategoryPalette(category),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.secondaryText,
                        ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : AppColors.secondaryText.withValues(alpha: 0.3),
                    ),
                    backgroundColor: AppColors.secondaryBackground,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
