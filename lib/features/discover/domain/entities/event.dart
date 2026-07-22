import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../data/event_category_palettes.dart';

class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.eventAt,
    required this.category,
    required this.description,
  });

  final String id;
  final String title;
  final String venue;
  final String city;
  final DateTime eventAt;
  final String category;
  final String description;

  /// Category-driven QR + background defaults for Generate.
  EventPalette get palette => EventCategoryPalettes.forCategory(category);

  Color get eyeColor => palette.eyeColor;
  Color get dataModuleColor => palette.dataModuleColor;
  Color get backgroundStart => palette.backgroundStart;
  Color get backgroundEnd => palette.backgroundEnd;

  String get dateLabel {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[eventAt.weekday - 1]}, ${months[eventAt.month - 1]} ${eventAt.day}';
  }

  String get timeLabel {
    final hour = eventAt.hour % 12 == 0 ? 12 : eventAt.hour % 12;
    final period = eventAt.hour >= 12 ? 'PM' : 'AM';
    final minute = eventAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    venue,
    city,
    eventAt,
    category,
    description,
  ];
}
