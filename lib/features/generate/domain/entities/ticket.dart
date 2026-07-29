import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.headerLabel,
    required this.title,
    required this.subtitle,
    required this.venue,
    required this.dateLabel,
    required this.timeLabel,
    required this.eventAt,
    required this.code,
    required this.qrData,
    required this.imagePath,
    required this.eyeColor,
    required this.dataModuleColor,
    required this.isSquare,
    required this.topGradientStart,
    required this.topGradientEnd,
    required this.bottomGradientStart,
    required this.bottomGradientEnd,
    this.checkedInAt,
  });

  final String id;
  final String headerLabel;
  final String title;
  final String subtitle;
  final String venue;
  final String dateLabel;
  final String timeLabel;
  final DateTime eventAt;
  final String code;
  final String qrData;

  /// Local file path, `data:` URL, `web-bytes:<id>`, or non-Storage http(s) URL.
  /// Empty → show placeholder (no Firebase Storage).
  final String imagePath;

  /// Alias for [imagePath] (Firestore may also store `imageUrl` / `photoUrl`).
  String get photoUrl => imagePath;

  final Color eyeColor;
  final Color dataModuleColor;
  final bool isSquare;
  final Color topGradientStart;
  final Color topGradientEnd;
  final Color bottomGradientStart;
  final Color bottomGradientEnd;

  /// When set, guest has been admitted at the door.
  final DateTime? checkedInAt;

  bool get isCheckedIn => checkedInAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'headerLabel': headerLabel,
    'title': title,
    'subtitle': subtitle,
    'venue': venue,
    'dateLabel': dateLabel,
    'timeLabel': timeLabel,
    'eventAt': eventAt.toIso8601String(),
    'code': code,
    'qrData': qrData,
    'imagePath': imagePath,
    'imageUrl': imagePath,
    'photoUrl': imagePath,
    'eyeColor': eyeColor.toARGB32(),
    'dataModuleColor': dataModuleColor.toARGB32(),
    'isSquare': isSquare,
    'topGradientStart': topGradientStart.toARGB32(),
    'topGradientEnd': topGradientEnd.toARGB32(),
    'bottomGradientStart': bottomGradientStart.toARGB32(),
    'bottomGradientEnd': bottomGradientEnd.toARGB32(),
    'checkedIn': isCheckedIn,
    if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
  };

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final path = _readImagePath(json);
    DateTime? checkedInAt;
    final rawCheckedIn = json['checkedInAt'];
    if (rawCheckedIn is String && rawCheckedIn.isNotEmpty) {
      checkedInAt = DateTime.tryParse(rawCheckedIn);
    }
    return Ticket(
      id: json['id'] as String,
      headerLabel: json['headerLabel'] as String? ?? 'My Ticket',
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      venue: json['venue'] as String? ?? '',
      dateLabel: json['dateLabel'] as String,
      timeLabel: json['timeLabel'] as String,
      eventAt: DateTime.parse(json['eventAt'] as String),
      code: json['code'] as String,
      qrData: json['qrData'] as String? ??
          'https://quick-ticket-maker-sandbox.web.app/verify/${json['code'] as String? ?? ''}',
      imagePath: path,
      eyeColor: Color(json['eyeColor'] as int),
      dataModuleColor: Color(json['dataModuleColor'] as int),
      isSquare: json['isSquare'] as bool? ?? false,
      topGradientStart: Color(json['topGradientStart'] as int),
      topGradientEnd: Color(json['topGradientEnd'] as int),
      bottomGradientStart: Color(json['bottomGradientStart'] as int),
      bottomGradientEnd: Color(json['bottomGradientEnd'] as int),
      checkedInAt: checkedInAt,
    );
  }

  static String _readImagePath(Map<String, dynamic> json) {
    for (final key in ['imagePath', 'imageUrl', 'photoUrl']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  /// Plain-text summary for the native share sheet.
  /// Includes ticket details and the generated URL when [qrData] is http(s).
  String toShareText() {
    final titleText =
        title.trim().isEmpty ? 'my personal event' : title.trim();
    final pass = subtitle.trim();
    final place = venue.trim().isNotEmpty
        ? venue.trim()
        : (pass.isEmpty ? 'a private gathering' : pass);
    final when = dateLabel.trim().isEmpty ? 'soon' : dateLabel.trim();
    final buffer = StringBuffer(
      "You're invited: $titleText at $place on $when",
    );
    if (pass.isNotEmpty) {
      buffer.write(' ($pass)');
    }
    buffer.write('!');
    final link = qrData.trim();
    if (link.startsWith('http://') || link.startsWith('https://')) {
      buffer.write('\n$link');
    }
    return buffer.toString();
  }

  Ticket copyWith({
    String? id,
    String? headerLabel,
    String? title,
    String? subtitle,
    String? venue,
    String? dateLabel,
    String? timeLabel,
    DateTime? eventAt,
    String? code,
    String? qrData,
    String? imagePath,
    Color? eyeColor,
    Color? dataModuleColor,
    bool? isSquare,
    Color? topGradientStart,
    Color? topGradientEnd,
    Color? bottomGradientStart,
    Color? bottomGradientEnd,
    DateTime? checkedInAt,
    bool clearCheckedIn = false,
  }) {
    return Ticket(
      id: id ?? this.id,
      headerLabel: headerLabel ?? this.headerLabel,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      venue: venue ?? this.venue,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      eventAt: eventAt ?? this.eventAt,
      code: code ?? this.code,
      qrData: qrData ?? this.qrData,
      imagePath: imagePath ?? this.imagePath,
      eyeColor: eyeColor ?? this.eyeColor,
      dataModuleColor: dataModuleColor ?? this.dataModuleColor,
      isSquare: isSquare ?? this.isSquare,
      topGradientStart: topGradientStart ?? this.topGradientStart,
      topGradientEnd: topGradientEnd ?? this.topGradientEnd,
      bottomGradientStart: bottomGradientStart ?? this.bottomGradientStart,
      bottomGradientEnd: bottomGradientEnd ?? this.bottomGradientEnd,
      checkedInAt:
          clearCheckedIn ? null : (checkedInAt ?? this.checkedInAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    headerLabel,
    title,
    subtitle,
    venue,
    dateLabel,
    timeLabel,
    eventAt,
    code,
    qrData,
    imagePath,
    eyeColor,
    dataModuleColor,
    isSquare,
    topGradientStart,
    topGradientEnd,
    bottomGradientStart,
    bottomGradientEnd,
    checkedInAt,
  ];
}
