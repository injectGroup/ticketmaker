import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';

class TicketDetailsSection extends StatelessWidget {
  const TicketDetailsSection({
    super.key,
    required this.ticket,
    required this.titleController,
    required this.subtitleController,
  });

  final Ticket ticket;
  final TextEditingController titleController;
  final TextEditingController subtitleController;

  static const InputDecoration _plainFieldDecoration = InputDecoration(
    isDense: true,
    isCollapsed: true,
    filled: false,
    fillColor: Colors.transparent,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    hoverColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = ColorContrast.onGradient(
      ticket.bottomGradientStart,
      ticket.bottomGradientEnd,
    );
    final cubit = context.read<GenerateCubit>();

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '[ ',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: onGradient,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    minLines: 1,
                    maxLines: 3,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: onGradient,
                    ),
                    cursorColor: onGradient,
                    decoration: _plainFieldDecoration,
                    onChanged: cubit.updateTitle,
                  ),
                ),
                Text(
                  ' ]',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: onGradient,
                  ),
                ),
              ],
            ),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.threed_rotation, color: onGradient, size: 24),
                const SizedBox(width: 20),
                Text(
                  '[ ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onGradient,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: subtitleController,
                    textAlignVertical: TextAlignVertical.center,
                    minLines: 1,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onGradient,
                    ),
                    cursorColor: onGradient,
                    decoration: _plainFieldDecoration,
                    onChanged: cubit.updateSubtitle,
                  ),
                ),
                Text(
                  ' ]',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onGradient,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 16),
            child: Row(
              children: [
                Icon(Icons.date_range_sharp, color: onGradient, size: 24),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    '[ ${ticket.dateLabel} ]',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onGradient,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time_rounded, color: onGradient, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '[ ${ticket.timeLabel} ]',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onGradient,
                    ),
                    overflow: TextOverflow.ellipsis,
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
