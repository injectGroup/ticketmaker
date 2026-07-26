import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'bracketed_ticket_field.dart';
import 'generate_qr_code.dart';
import 'top_bg_color_customizer_sheet.dart';

/// FlutterFlow-style indigo used for QR control pills / primary QR action.
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
                label: 'Change color',
                onTap: cubit.cycleQrColors,
              ),
              const SizedBox(width: 10),
              _ChipButton(
                label: 'Change shape',
                onTap: cubit.toggleQrShape,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: cubit.generateTicketCode,
            style: FilledButton.styleFrom(
              backgroundColor: _qrControlPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Generate Qr Code'),
          ),
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
  const _ChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 118,
          height: 28,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _qrControlPurple,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
        Material(
          color: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(color: _qrControlPurple, width: 1.5),
          ),
          elevation: 2,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.color_lens, color: AppColors.primaryText),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bg color',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
