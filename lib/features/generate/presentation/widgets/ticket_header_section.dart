import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'bracketed_ticket_field.dart';
import 'generate_qr_code.dart';
import 'ticket_code_badge.dart';
import 'top_bg_color_customizer_sheet.dart';

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
    final onText = ColorContrast.onGradient(
      ticket.topGradientStart,
      ticket.topGradientEnd,
    );
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.pillText,
      letterSpacing: 0.4,
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BracketedTicketField(
              controller: headerLabelController,
              resetToken: bracketResetToken,
              textAlign: TextAlign.center,
              minLines: 1,
              maxLines: 2,
              style: labelStyle,
              cursorColor: onText,
              hintText: 'Tap to edit…',
              onChanged: cubit.updateHeaderLabel,
            ),
          ),
          const SizedBox(height: 28),
          GenerateQrCode(
            width: 150,
            height: 150,
            data: ticket.qrData,
            eyeStyleColor: ticket.eyeColor,
            dataModuleStyleColor: ticket.dataModuleColor,
            isSquare: ticket.isSquare,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChipButton(
                icon: Icons.palette_outlined,
                label: 'Change color',
                onTap: cubit.cycleQrColors,
              ),
              const SizedBox(width: 10),
              _ChipButton(
                icon: Icons.category_outlined,
                label: 'Change shape',
                onTap: cubit.toggleQrShape,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TicketCodeBadge(
            code: ticket.code,
            labelColor: onText,
            showInfo: true,
            showIdLabel: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 12, bottom: 12),
              child: _BgColorFab(
                onPressed: () => TopBgColorCustomizerSheet.show(context),
                labelColor: onText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color _chipBg = Color(0xFFF8F9FA);
  static const Color _chipBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _chipBg,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 118,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _chipBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.0,
                    letterSpacing: 0.3,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BgColorFab extends StatelessWidget {
  const _BgColorFab({
    required this.onPressed,
    required this.labelColor,
  });

  final VoidCallback onPressed;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 20,
                spreadRadius: 0.5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: AppColors.fabNeutral,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.palette_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bg color',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
