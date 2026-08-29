import 'package:flutter/material.dart';

/// Clipped 3:2 slot for the ticket event / guest photo.
///
/// Children should paint with [BoxFit.cover] so tall or wide uploads crop
/// instead of stretching.
class TicketEventPhotoFrame extends StatelessWidget {
  const TicketEventPhotoFrame({
    super.key,
    required this.child,
    this.borderRadius = 16,
  });

  static const Key frameKey = Key('ticket-event-photo-frame');

  static const double width = 300;
  static const double height = 200;
  static const double aspectRatio = width / height;

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: frameKey,
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}
