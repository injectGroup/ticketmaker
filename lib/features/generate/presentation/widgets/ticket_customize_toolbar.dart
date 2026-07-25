import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/generate_cubit.dart';
import 'top_bg_color_customizer_sheet.dart';

enum _DesignTool { color, shape, bg, code }

/// Four individual floating design-control chips under the Generate AppBar.
class TicketCustomizeToolbar extends StatefulWidget {
  const TicketCustomizeToolbar({super.key});

  @override
  State<TicketCustomizeToolbar> createState() => _TicketCustomizeToolbarState();
}

class _TicketCustomizeToolbarState extends State<TicketCustomizeToolbar> {
  _DesignTool? _selected;

  void _select(_DesignTool tool, VoidCallback action) {
    setState(() => _selected = tool);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateCubit>();
    final isSquare = context.select(
      (GenerateCubit c) => c.state.ticket.isSquare,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionChip(
          icon: Icons.palette_outlined,
          label: 'Color',
          selected: _selected == _DesignTool.color,
          onTap: () => _select(_DesignTool.color, cubit.cycleQrColors),
        ),
        _ActionChip(
          icon: isSquare ? Icons.crop_square_rounded : Icons.circle_outlined,
          label: 'Shape',
          selected: _selected == _DesignTool.shape || isSquare,
          onTap: () => _select(_DesignTool.shape, cubit.toggleQrShape),
        ),
        _ActionChip(
          icon: Icons.gradient_rounded,
          label: 'Bg',
          selected: _selected == _DesignTool.bg,
          onTap: () => _select(
            _DesignTool.bg,
            () => TopBgColorCustomizerSheet.show(context),
          ),
        ),
        _ActionChip(
          icon: Icons.qr_code_2_rounded,
          label: 'Code',
          selected: _selected == _DesignTool.code,
          onTap: () => _select(_DesignTool.code, cubit.generateTicketCode),
        ),
      ],
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.secondaryBackground;
    final border = selected
        ? AppColors.primary.withValues(alpha: 0.55)
        : AppColors.primaryText.withValues(alpha: 0.12);
    final iconColor = selected ? AppColors.primary : AppColors.primary;
    final labelColor =
        selected ? AppColors.primary : AppColors.primaryText;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.12 : 0.08),
                blurRadius: selected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: iconColor, size: 24),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor,
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
