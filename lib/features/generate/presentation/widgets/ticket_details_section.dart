import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

      // Always read bytes so Flutter Web can render via Image.memory.
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

      // Set preview bytes first so the UI updates immediately.
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
    const height = 188.0;
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

    return const TicketPhotoPlaceholder(width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );
    final cubit = context.read<GenerateCubit>();
    final path = ticket.imagePath;
    final hasImage = (imageBytes != null && imageBytes!.isNotEmpty) ||
        (!kIsWeb && path.isNotEmpty && File(path).existsSync());

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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: BracketedTicketField(
              controller: titleController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 3,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
              cursorColor: onGradient,
              hintText: 'Event title',
              onChanged: cubit.updateTitle,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickGalleryImage(context),
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _eventImage(),
                  ),
                  if (hasImage)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
            child: BracketedTicketField(
              controller: subtitleController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 4,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onGradient,
                height: 1.35,
              ),
              cursorColor: onGradient,
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
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: onGradient, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          ticket.dateLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onGradient,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.schedule_rounded, color: onGradient, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          ticket.timeLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onGradient,
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
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
            child: BracketedTicketField(
              controller: venueController,
              resetToken: bracketResetToken,
              minLines: 1,
              maxLines: 3,
              style: theme.textTheme.bodyMedium?.copyWith(color: onGradient),
              cursorColor: onGradient,
              hintText: 'Venue',
              onChanged: cubit.updateVenue,
              leading: Icon(
                Icons.place_outlined,
                color: onGradient,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
