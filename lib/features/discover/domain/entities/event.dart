import 'package:equatable/equatable.dart';

class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.eventAt,
    required this.category,
    required this.description,
    required this.host,
    required this.priceLabel,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String venue;
  final String city;
  final DateTime eventAt;
  final String category;
  final String description;
  final String host;
  final String priceLabel;

  /// Asset path (`assets/...`) or network URL. Null → palette color fallback.
  final String? imageUrl;

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

  bool get hasAssetImage =>
      imageUrl != null && imageUrl!.startsWith('assets/');

  bool get hasNetworkImage =>
      imageUrl != null &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  List<Object?> get props => [
    id,
    title,
    venue,
    city,
    eventAt,
    category,
    description,
    host,
    priceLabel,
    imageUrl,
  ];
}
