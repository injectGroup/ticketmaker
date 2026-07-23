import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';
import '../theme/event_theme.dart';

/// Shared hero / fallback media band for Discover cards and detail sheets.
class EventHeroHeader extends StatelessWidget {
  const EventHeroHeader({
    super.key,
    required this.event,
    this.height = 152,
    this.borderRadius,
  });

  final Event event;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(12));
    final accent = EventTheme.accent(event.category);

    final Widget media;
    if (event.hasAssetImage) {
      media = Image.asset(
        event.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (_, _, _) => _FallbackHeader(
          category: event.category,
          height: height,
        ),
      );
    } else if (event.hasNetworkImage) {
      media = Image.network(
        event.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (_, _, _) => _FallbackHeader(
          category: event.category,
          height: height,
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _FallbackHeader(category: event.category, height: height),
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: EventTheme.onAccent(event.category),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      media = _FallbackHeader(category: event.category, height: height);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            media,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackHeader extends StatelessWidget {
  const _FallbackHeader({required this.category, required this.height});

  final String category;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: EventTheme.headerGradient(category),
        ),
        child: Center(
          child: Icon(
            Icons.event_outlined,
            size: 48,
            color: EventTheme.onAccent(category).withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
