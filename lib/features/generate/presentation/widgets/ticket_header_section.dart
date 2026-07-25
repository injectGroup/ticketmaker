import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'bracketed_ticket_field.dart';
import 'generate_qr_code.dart';
import 'ticket_code_badge.dart';

class TicketHeaderSection extends StatelessWidget {
  const TicketHeaderSection({
    super.key,
    required this.ticket,
    required this.headerLabelController,
    this.bracketResetToken,
  });

  final Ticket ticket;
  final TextEditingController headerLabelController;
  final Object? bracketResetToken;

  static const Color _onCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<GenerateCubit>();
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: _onCard,
      letterSpacing: 0.2,
      fontSize: 18,
      height: 1.25,
    );

    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BracketedTicketField(
            controller: headerLabelController,
            resetToken: bracketResetToken,
            textAlign: TextAlign.center,
            minLines: 1,
            maxLines: 2,
            style: labelStyle,
            cursorColor: _onCard,
            hintText: 'Pass title',
            onChanged: cubit.updateHeaderLabel,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GenerateQrCode(
            width: 140,
            height: 140,
            data: ticket.qrData,
            eyeStyleColor: ticket.eyeColor,
            dataModuleStyleColor: ticket.dataModuleColor,
            isSquare: ticket.isSquare,
          ),
        ),
        const SizedBox(height: 18),
        TicketCodeBadge(
          code: ticket.code,
          foreground: _onCard,
          background: _onCard.withValues(alpha: 0.16),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
