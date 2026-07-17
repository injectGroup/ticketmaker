import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/generate_cubit.dart';
import 'generate_qr_code.dart';
import 'top_bg_color_customizer_sheet.dart';

class TicketHeaderSection extends StatelessWidget {
  const TicketHeaderSection({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text(
            '[ MY TICKET ]',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 30),
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
                onTap: () => context.read<GenerateCubit>().cycleQrColors(),
              ),
              const SizedBox(width: 10),
              _ChipButton(
                label: 'Change shape',
                onTap: () => context.read<GenerateCubit>().toggleQrShape(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<GenerateCubit>().generateTicketCode(),
            child: const Text('Generate Qr Code'),
          ),
          const SizedBox(height: 20),
          Text(
            '[ ${ticket.code} ]',
            style: theme.textTheme.bodyMedium,
          ),
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.secondaryText,
            size: 24,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 12),
              child: _IconAction(
                icon: Icons.color_lens,
                label: 'Bg color',
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
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 110,
          height: 25,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.outlined(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryText,
            side: const BorderSide(color: AppColors.primary),
            backgroundColor: AppColors.secondaryBackground,
          ),
          icon: Icon(icon),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
