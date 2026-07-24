import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Structured empty / error state for the ticket event photo slot.
class TicketPhotoPlaceholder extends StatelessWidget {
  const TicketPhotoPlaceholder({
    super.key,
    this.width = 300,
    this.height = 200,
    this.broken = false,
  });

  final double width;
  final double height;

  /// When true, shows a broken-image affordance instead of "add photo".
  final bool broken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: AppColors.secondaryText.withValues(alpha: 0.45),
        radius: 16,
      ),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.secondaryText.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              broken
                  ? Icons.broken_image_outlined
                  : Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppColors.secondaryText.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 10),
            Text(
              broken ? 'Photo unavailable' : 'Add event photo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
