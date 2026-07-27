import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/generate/domain/entities/ticket.dart';
import 'package:ticket_maker/features/generate/presentation/bloc/generate_cubit.dart';

void main() {
  test('GenerateCubit defaults to personal birthday ticket values', () {
    final cubit = GenerateCubit();
    final ticket = cubit.state.ticket;

    expect(ticket.title, "Ejike's Birthday Bash");
    expect(ticket.subtitle, 'VIP Guest Pass');
    expect(ticket.code, '1234-5678-910');
    expect(ticket.qrData, 'https://ticketmaker.app/t/1234-5678-910');
    cubit.close();
  });

  test('generateTicketCode writes ticketmaker.app payload with new code', () {
    final cubit = GenerateCubit();
    cubit.generateTicketCode();
    final ticket = cubit.state.ticket;

    expect(ticket.code, isNot(equals('1234-5678-910')));
    expect(ticket.qrData, 'https://ticketmaker.app/t/${ticket.code}');
    cubit.close();
  });

  test('toShareText includes personal details and payload URL', () {
    final text = Ticket(
      id: 't1',
      headerLabel: 'GUEST PASS',
      title: "Ejike's Birthday Bash",
      subtitle: 'VIP Guest Pass',
      venue: 'Private gathering',
      dateLabel: 'Sat, Jul 18',
      timeLabel: '8:00 PM',
      eventAt: DateTime(2026, 7, 18, 20),
      code: '1234-5678-910',
      qrData: 'https://ticketmaker.app/t/1234-5678-910',
      imagePath: '',
      eyeColor: const Color(0xFFFF5963),
      dataModuleColor: const Color(0xFFFFFFFF),
      isSquare: false,
      topGradientStart: const Color(0xFF4B39EF),
      topGradientEnd: const Color(0xFF4B39EF),
      bottomGradientStart: const Color(0xFF4B39EF),
      bottomGradientEnd: const Color(0xFF4B39EF),
    ).toShareText();

    expect(text, contains("Ejike's Birthday Bash"));
    expect(text, contains('Private gathering'));
    expect(text, contains('VIP Guest Pass'));
    expect(text, contains('https://ticketmaker.app/t/1234-5678-910'));
  });
}
