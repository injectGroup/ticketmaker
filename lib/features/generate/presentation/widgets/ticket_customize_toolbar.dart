import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/generate_cubit.dart';
import 'top_bg_color_customizer_sheet.dart';

/// Floating design-control pill (Color, Shape, Bg, Code).
/// Anchored under the Generate AppBar so it stays visible while the ticket scrolls.
class TicketCustomizeToolbar extends StatelessWidget {
  const TicketCustomizeToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateCubit>();

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      color: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Tool(
              icon: Icons.palette_outlined,
              label: 'Color',
              onTap: cubit.cycleQrColors,
            ),
            _Tool(
              icon: Icons.crop_square_rounded,
              label: 'Shape',
              onTap: cubit.toggleQrShape,
            ),
            _Tool(
              icon: Icons.gradient_rounded,
              label: 'Bg',
              onTap: () => TopBgColorCustomizerSheet.show(context),
            ),
            _Tool(
              icon: Icons.qr_code_2_rounded,
              label: 'Code',
              onTap: cubit.generateTicketCode,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatefulWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Tool> createState() => _ToolState();
}

class _ToolState extends State<_Tool> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
