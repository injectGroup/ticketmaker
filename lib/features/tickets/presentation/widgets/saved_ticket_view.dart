import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/color_contrast.dart';
import '../../../../core/widgets/ticket_photo_placeholder.dart';
import '../../../../core/widgets/ticket_event_photo_frame.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../../../generate/presentation/widgets/generate_qr_code.dart';
import '../../../generate/presentation/widgets/ticket_branding_footer.dart';
import '../../../generate/presentation/widgets/ticket_code_badge.dart';
import '../../../generate/presentation/widgets/ticket_date_text.dart';
import '../../../generate/presentation/widgets/ticket_perforation.dart';
import '../../../generate/presentation/widgets/ticket_section_label.dart';
import '../../data/ticket_image_store.dart';
import '../../data/ticket_network_image.dart';

/// Read-only visual of a saved ticket (mirrors Generate layout without editors).
class SavedTicketView extends StatelessWidget {
  const SavedTicketView({
    super.key,
    required this.ticket,
    this.imageBytes,
  });

  final Ticket ticket;
  final Uint8List? imageBytes;

  Widget _eventImage() {
    const width = TicketEventPhotoFrame.width;
    const height = TicketEventPhotoFrame.height;

    final bytes = imageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        ),
      );
    }

    final path = ticket.photoUrl.trim();
    if (path.isEmpty ||
        path.startsWith('blob:') ||
        TicketImageStore.isWebBytesPath(path)) {
      // Empty / ephemeral / web-bytes marker without session bytes → placeholder.
      // Never hit the network for these (keeps RepaintBoundary capture stable).
      return const TicketPhotoPlaceholder(width: width, height: height);
    }

    if (path.startsWith('data:')) {
      final decoded = decodeDataUrlBytes(path);
      if (decoded == null || decoded.isEmpty) {
        return const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        );
      }
      return Image.memory(
        decoded,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
          width: width,
          height: height,
          broken: true,
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Fetch bytes → MemoryImage so Flutter Web CanvasKit snapshots are not
      // CORS-tainted by Image.network / NetworkImage.
      return TicketCorsSafeNetworkImage(
        url: path,
        width: width,
        height: height,
      );
    }

    if (kIsWeb) {
      return const TicketPhotoPlaceholder(width: width, height: height);
    }

    final hasFile = File(path).existsSync();
    if (!hasFile) {
      return const TicketPhotoPlaceholder(width: width, height: height);
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => const TicketPhotoPlaceholder(
        width: width,
        height: height,
        broken: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ticket.topGradientStart, ticket.topGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              ticket.headerLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: onCard,
              ),
            ),
          ),
          const SizedBox(height: 30),
          GenerateQrCode(
            width: 150,
            height: 150,
            data: ticket.qrData,
            eyeStyleColor: ticket.eyeColor,
            dataModuleStyleColor: ticket.dataModuleColor,
            isSquare: ticket.isSquare,
          ),
          const SizedBox(height: 20),
          TicketCodeBadge(
            code: ticket.code,
            labelColor: onCard,
            showIdLabel: true,
          ),
          const SizedBox(height: 16),
          const TicketPerforation(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              ticket.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: onCard,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TicketEventPhotoFrame(child: _eventImage()),
          if (ticket.subtitle.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 16),
              child: Column(
                children: [
                  TicketSectionLabel(
                    text: 'About this event',
                    color: onCard,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      ticket.subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onCard,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 8),
            child: Row(
              children: [
                Icon(Icons.date_range_sharp, color: onCard, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TicketDateText(
                    eventAt: ticket.eventAt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onCard,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.access_time_rounded, color: onCard, size: 20),
                const SizedBox(width: 8),
                Text(
                  ticket.timeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onCard,
                  ),
                ),
              ],
            ),
          ),
          if (ticket.venue.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, color: onCard, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ticket.venue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onCard,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
          TicketBrandingFooter(color: onCard),
        ],
      ),
    );
  }
}
