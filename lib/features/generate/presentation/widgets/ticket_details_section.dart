import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';

class TicketDetailsSection extends StatelessWidget {
  const TicketDetailsSection({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = AppColors.secondaryBackground;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ticket.bottomGradientStart, ticket.bottomGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Text(
            '[ ${ticket.title} ]',
            style: theme.textTheme.headlineLarge?.copyWith(color: onGradient),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ticket.imageUrl,
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 300,
                    height: 200,
                    color: AppColors.secondaryText.withValues(alpha: 0.3),
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.outlined(
                  onPressed: () =>
                      context.read<GenerateCubit>().refreshImage(),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.primary),
                    backgroundColor: AppColors.secondaryBackground,
                  ),
                  icon: const Icon(Icons.insert_photo),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 16),
            child: Row(
              children: [
                Icon(Icons.threed_rotation, color: onGradient, size: 24),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    '[ ${ticket.subtitle} ]',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                Icon(Icons.date_range_sharp, color: onGradient, size: 24),
                const SizedBox(width: 16),
                Text(
                  '[ ${ticket.dateLabel} ]',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onGradient,
                  ),
                ),
                const SizedBox(width: 30),
                Icon(Icons.access_time_rounded, color: onGradient, size: 24),
                const SizedBox(width: 20),
                Text(
                  '[ ${ticket.timeLabel} ]',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onGradient,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 20, 24),
              child: Column(
                children: [
                  IconButton.outlined(
                    onPressed: () =>
                        context.read<GenerateCubit>().cycleBackgroundColors(),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      side: const BorderSide(color: AppColors.primary),
                      backgroundColor: AppColors.secondaryBackground,
                    ),
                    icon: const Icon(Icons.color_lens),
                  ),
                  Text('Bg color', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
