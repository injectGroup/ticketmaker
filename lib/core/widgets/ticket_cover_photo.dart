import 'package:flutter/material.dart';

import 'ticket_event_photo_frame.dart';
import 'ticket_photo_placeholder.dart';

/// Event photo that fills [TicketEventPhotoFrame] with [BoxFit.cover].
///
/// Do not pass a finite [Image.width]/[Image.height] — that resizes the
/// bitmap into the slot and stretches portraits. The frame sizes the box;
/// this widget only covers it.
class TicketCoverPhoto extends StatelessWidget {
  const TicketCoverPhoto({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.gaplessPlayback = false,
    this.errorBuilder,
  });

  final ImageProvider image;
  final BoxFit fit;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      fit: fit,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => const TicketPhotoPlaceholder(
            width: TicketEventPhotoFrame.width,
            height: TicketEventPhotoFrame.height,
            broken: true,
          ),
    );
  }
}
