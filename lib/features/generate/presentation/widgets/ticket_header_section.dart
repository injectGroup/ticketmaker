import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'bracketed_ticket_field.dart';
import 'generate_qr_code.dart';
import 'top_bg_color_customizer_sheet.dart';

/// Indigo-purple brand tint for QR edit chips.
const Color _qrControlPurple = Color(0xFF4B39EF);

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
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.primaryText,
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
              cursorColor: AppColors.primaryText,
              hintText: 'Pass title',
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
          _GenerateQrButton(onPressed: cubit.generateTicketCode),
          const SizedBox(height: 20),
          Text(
            '[ ${ticket.code} ]',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.secondaryText,
            size: 24,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 8, bottom: 12),
              child: _BgColorFab(
                onPressed: () => TopBgColorCustomizerSheet.show(context),
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.85),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 118,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: _qrControlPurple),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _qrControlPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerateQrButton extends StatelessWidget {
  const _GenerateQrButton({required this.onPressed});

  final VoidCallback onPressed;

  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_indigo, _violet],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Text(
              'Generate Qr Code',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BgColorFab extends StatelessWidget {
  const _BgColorFab({required this.onPressed});

  final VoidCallback onPressed;

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
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.85),
                shape: CircleBorder(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo_mark.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.confirmation_number_rounded,
                              color: Color(0xFF6366F1),
                              size: 26,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.palette_rounded,
                              size: 12,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bg color',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
