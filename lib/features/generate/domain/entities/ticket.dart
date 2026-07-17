import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.headerLabel,
    required this.title,
    required this.subtitle,
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
  });

  final String id;
  final String headerLabel;
  final String title;
  final String subtitle;
  final String dateLabel;
  final String timeLabel;
  final DateTime eventAt;
  final String code;
  final String qrData;

  /// Local gallery file path. Empty → show bundled placeholder asset.
  final String imagePath;
  final Color eyeColor;
  final Color dataModuleColor;
  final bool isSquare;
  final Color topGradientStart;
  final Color topGradientEnd;
  final Color bottomGradientStart;
  final Color bottomGradientEnd;

  Ticket copyWith({
    String? id,
    String? headerLabel,
    String? title,
    String? subtitle,
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
  }) {
    return Ticket(
      id: id ?? this.id,
      headerLabel: headerLabel ?? this.headerLabel,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
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
    );
  }

  @override
  List<Object?> get props => [
        id,
        headerLabel,
        title,
        subtitle,
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
      ];
}
