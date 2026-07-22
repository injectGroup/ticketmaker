import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../../generate/domain/entities/ticket.dart';
import '../../../generate/presentation/widgets/generate_qr_code.dart';
import '../../../generate/presentation/widgets/ticket_perforation.dart';

/// Read-only visual of a saved ticket (mirrors Generate layout without editors).
class SavedTicketView extends StatelessWidget {
  const SavedTicketView({super.key, required this.ticket});

  final Ticket ticket;

  static const String placeholderAsset =
      'assets/images/ticket_event_placeholder.png';

  Widget _eventImage() {
    const width = 300.0;
    const height = 200.0;

    final path = ticket.imagePath;
    final hasFile = path.isNotEmpty && File(path).existsSync();
    if (!hasFile) {
      return Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(width, height),
      );
    }

    return Image.file(
      File(path),
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
    final onTop = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );

    return Column(
      children: [
        Container(
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ticket.headerLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onTop,
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
              Text(
                '[ ${ticket.code} ]',
                style: theme.textTheme.bodyMedium?.copyWith(color: onTop),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const TicketPerforation(),
        Container(
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
                child: Text(
                  ticket.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: onTop,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _eventImage(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 30, 30, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.threed_rotation, color: onTop, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ticket.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onTop,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 32),
                child: Row(
                  children: [
                    Icon(Icons.date_range_sharp, color: onTop, size: 24),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        ticket.dateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onTop,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, color: onTop, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        ticket.timeLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onTop,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
