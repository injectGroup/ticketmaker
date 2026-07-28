import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/tickets/data/ticket_raster_export.dart';

void main() {
  final sampleTicket = Ticket(
    id: 'ticket-raster-test',
    headerLabel: 'VIP Pass',
    title: 'Raster Export Concert',
    subtitle: 'National Stadium',
    venue: 'National Stadium',
    dateLabel: 'Sat, Jul 18',
    timeLabel: '8:00 PM',
    eventAt: DateTime(2026, 7, 18, 20),
    code: '1111-2222-333',
    qrData: 'https://example.com/ticket/raster-export',
    imagePath: '',
    eyeColor: const Color(0xFFF44336),
    dataModuleColor: const Color(0xFFFF9800),
    isSquare: false,
    topGradientStart: const Color(0xFF4B39EF),
    topGradientEnd: const Color(0xFF39D2C0),
    bottomGradientStart: const Color(0xFF4B39EF),
    bottomGradientEnd: const Color(0xFF39D2C0),
  );

  test('TicketRasterExport produces PNG without photo bytes', () async {
    final bytes = await TicketRasterExport.toPngBytes(sampleTicket);
    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test('TicketRasterExport embeds event photo bytes when provided', () async {
    // Minimal valid 1x1 PNG.
    final photo = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    final withPhoto = await TicketRasterExport.toPngBytes(
      sampleTicket,
      eventImageBytes: photo,
    );
    final withoutPhoto = await TicketRasterExport.toPngBytes(sampleTicket);

    expect(withPhoto, isNotNull);
    expect(withoutPhoto, isNotNull);
    expect(withPhoto!, isNotEmpty);
    // Composite with photo should differ from placeholder version.
    expect(withPhoto.length, isNot(withoutPhoto!.length));
  });
}
