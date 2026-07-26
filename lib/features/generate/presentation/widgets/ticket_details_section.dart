import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../../../core/widgets/ticket_photo_placeholder.dart';
import '../../../tickets/data/ticket_image_store.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'bracketed_ticket_field.dart';

class TicketDetailsSection extends StatelessWidget {
  const TicketDetailsSection({
    super.key,
    required this.ticket,
    required this.titleController,
    required this.subtitleController,
    required this.venueController,
    this.bracketResetToken,
    this.imageStore,
    this.imageBytes,
  });

  final Ticket ticket;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController venueController;
  final Object? bracketResetToken;
  final TicketImageStore? imageStore;
  final Uint8List? imageBytes;

  Future<void> _pickGalleryImage(BuildContext context) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null || !context.mounted) return;

      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Could not read image')),
          );
        return;
      }

      context.read<GenerateCubit>().setPickedImage(path: file.path, bytes: bytes);

      if (!kIsWeb) {
        final store = imageStore ?? TicketImageStore();
        try {
          final durablePath = await store.import(
            sourcePath: file.path,
            bytes: bytes,
          );
          if (durablePath.isNotEmpty && context.mounted) {
            context
                .read<GenerateCubit>()
                .setPickedImage(path: durablePath, bytes: bytes);
          }
        } catch (_) {
          // Bytes already set for preview.
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not read image: $e')),
        );
    }
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
    final bytes = imageBytes;
    final path = ticket.imagePath;

    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        ),
      );
    }

    if (!kIsWeb && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        ),
      );
    }

    return const TicketPhotoPlaceholder(width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<GenerateCubit>();
    final onText = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );

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
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BracketedTicketField(
              controller: titleController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 3,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: onText,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1.2,
              ),
              cursorColor: onText,
              hintText: 'Event title',
              onChanged: cubit.updateTitle,
            ),
          ),
          const SizedBox(height: 16),
          // Dark image preview card with gallery picker overlay (top-right).
          Material(
            color: const Color(0xFF2D3436),
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 300,
                    height: 200,
                    child: ColoredBox(
                      color: const Color(0xFF2D3436),
                      child: Center(child: _eventImage()),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.85),
                        child: InkWell(
                          onTap: () => _pickGalleryImage(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: AppColors.primaryText,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 28, 30, 16),
            child: BracketedTicketField(
              controller: subtitleController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 4,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onText,
                height: 1.35,
              ),
              cursorColor: onText,
              hintText: 'Subtitle',
              onChanged: cubit.updateSubtitle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickDateTime(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_sharp, color: onText, size: 24),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '[ ${ticket.dateLabel} ]',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onText,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded, color: onText, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '[ ${ticket.timeLabel} ]',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onText,
                            fontWeight: FontWeight.w600,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: BracketedTicketField(
              controller: venueController,
              resetToken: bracketResetToken,
              minLines: 1,
              maxLines: 3,
              style: theme.textTheme.bodyMedium?.copyWith(color: onText),
              cursorColor: onText,
              hintText: 'Venue',
              onChanged: cubit.updateVenue,
              leading: Icon(Icons.place_outlined, color: onText, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
