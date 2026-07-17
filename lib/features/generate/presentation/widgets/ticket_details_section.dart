import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'top_bg_color_customizer_sheet.dart';

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

  static const String placeholderAsset =
      'assets/images/ticket_event_placeholder.png';

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

  Future<void> _pickGalleryImage(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    context.read<GenerateCubit>().setImagePath(file.path);
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final cubit = context.read<GenerateCubit>();
    final initial = ticket.eventAt;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    cubit.setEventDateTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Widget _eventImage() {
    const width = 300.0;
    const height = 200.0;

    if (ticket.imagePath.isEmpty) {
      return Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(width, height),
      );
    }

    return Image.file(
      File(ticket.imagePath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(width, height),
      ),
    );
  }

  Widget _imageFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondaryText.withValues(alpha: 0.3),
      child: const Icon(Icons.broken_image, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Bottom half shares Task 2.3 top background colors.
    final onGradient = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );
    final cubit = context.read<GenerateCubit>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ticket.topGradientStart, ticket.topGradientEnd],
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
                child: _eventImage(),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.outlined(
                  onPressed: () => _pickGalleryImage(context),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickDateTime(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                      Icon(
                        Icons.access_time_rounded,
                        color: onGradient,
                        size: 24,
                      ),
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
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 20, 24),
              child: Column(
                children: [
                  IconButton.outlined(
                    onPressed: () => TopBgColorCustomizerSheet.show(context),
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
