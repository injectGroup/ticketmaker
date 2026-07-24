import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/color_contrast.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<GenerateCubit>();
    final onTop = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: onTop,
      letterSpacing: 0.2,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ticket.topGradientStart, ticket.topGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: BracketedTicketField(
              controller: headerLabelController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 2,
              style: labelStyle,
              cursorColor: onTop,
              hintText: 'Pass title',
              onChanged: cubit.updateHeaderLabel,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
            foreground: onTop,
            background: onTop.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}
