import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/generate_cubit.dart';

enum _TopBgMode { solid, gradient }

/// Modal bottom sheet for solid or gradient top ticket backgrounds.
class TopBgColorCustomizerSheet extends StatefulWidget {
  const TopBgColorCustomizerSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<GenerateCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: const TopBgColorCustomizerSheet(),
          ),
        );
      },
    );
  }

  @override
  State<TopBgColorCustomizerSheet> createState() =>
      _TopBgColorCustomizerSheetState();
}

class _TopBgColorCustomizerSheetState extends State<TopBgColorCustomizerSheet> {
  late final TextEditingController _solidHexController;
  late final TextEditingController _startHexController;
  late final TextEditingController _endHexController;

  _TopBgMode _mode = _TopBgMode.solid;
  String? _solidHexError;
  String? _startHexError;
  String? _endHexError;

  late Color _solidPreview;
  late Color _startPreview;
  late Color _endPreview;

  @override
  void initState() {
    super.initState();
    final ticket = context.read<GenerateCubit>().state.ticket;
    final start = ticket.topGradientStart;
    final end = ticket.topGradientEnd;
    final isSolid = start.toARGB32() == end.toARGB32();

    _mode = isSolid ? _TopBgMode.solid : _TopBgMode.gradient;
    _solidPreview = start;
    _startPreview = start;
    _endPreview = end;
    _solidHexController = TextEditingController(text: _toHex(start));
    _startHexController = TextEditingController(text: _toHex(start));
    _endHexController = TextEditingController(text: _toHex(end));
  }

  @override
  void dispose() {
    _solidHexController.dispose();
    _startHexController.dispose();
    _endHexController.dispose();
    super.dispose();
  }

  static String _toHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _dismissAfterApply() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onSolidPresetSelected(Color color) {
    setState(() {
      _solidPreview = color;
      _solidHexController.text = _toHex(color);
      _solidHexError = null;
    });
    context.read<GenerateCubit>().applyTopBackgroundSolid(color);
    _dismissAfterApply();
  }

  void _onSolidHexChanged(String raw) {
    final color = GenerateCubit.tryParseHexColor(raw);
    setState(() {
      _solidHexError = null;
      if (color != null) {
        _solidPreview = color;
      }
    });
    if (color != null) {
      context.read<GenerateCubit>().applyTopBackgroundSolid(color);
    }
  }

  void _submitSolidHex() {
    final ok = context.read<GenerateCubit>().applyTopBackgroundSolidHex(
      _solidHexController.text,
    );
    if (ok) {
      final color = GenerateCubit.tryParseHexColor(_solidHexController.text)!;
      setState(() {
        _solidPreview = color;
        _solidHexError = null;
      });
      _dismissAfterApply();
      return;
    }
    setState(() {
      _solidHexError = 'Enter a valid hex color (#RRGGBB)';
    });
  }

  void _onStartHexChanged(String raw) {
    final color = GenerateCubit.tryParseHexColor(raw);
    setState(() {
      _startHexError = null;
      if (color != null) {
        _startPreview = color;
      }
    });
    _liveApplyGradientIfReady();
  }

  void _onEndHexChanged(String raw) {
    final color = GenerateCubit.tryParseHexColor(raw);
    setState(() {
      _endHexError = null;
      if (color != null) {
        _endPreview = color;
      }
    });
    _liveApplyGradientIfReady();
  }

  void _liveApplyGradientIfReady() {
    final start = GenerateCubit.tryParseHexColor(_startHexController.text);
    final end = GenerateCubit.tryParseHexColor(_endHexController.text);
    if (start == null || end == null) return;
    context.read<GenerateCubit>().setTopBackgroundGradient(
      start: start,
      end: end,
    );
  }

  void _submitGradientHex() {
    final startRaw = _startHexController.text;
    final endRaw = _endHexController.text;
    final start = GenerateCubit.tryParseHexColor(startRaw);
    final end = GenerateCubit.tryParseHexColor(endRaw);

    final startError = start == null
        ? 'Enter a valid hex color (#RRGGBB)'
        : null;
    final endError = end == null ? 'Enter a valid hex color (#RRGGBB)' : null;

    if (start == null || end == null) {
      setState(() {
        _startHexError = startError;
        _endHexError = endError;
      });
      return;
    }

    setState(() {
      _startPreview = start;
      _endPreview = end;
      _startHexError = null;
      _endHexError = null;
    });
    context.read<GenerateCubit>().setTopBackgroundGradient(
      start: start,
      end: end,
    );
    _dismissAfterApply();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Top background', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose a solid color or a two-stop gradient for the ticket header.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<_TopBgMode>(
              segments: const [
                ButtonSegment(
                  value: _TopBgMode.solid,
                  label: Text('Solid Color'),
                  icon: Icon(Icons.circle, size: 16),
                ),
                ButtonSegment(
                  value: _TopBgMode.gradient,
                  label: Text('Gradient Color'),
                  icon: Icon(Icons.gradient, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selected) {
                setState(() {
                  _mode = selected.first;
                  _solidHexError = null;
                  _startHexError = null;
                  _endHexError = null;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_mode == _TopBgMode.solid)
              _SolidColorPanel(
                hexController: _solidHexController,
                hexError: _solidHexError,
                previewColor: _solidPreview,
                onPresetSelected: _onSolidPresetSelected,
                onHexChanged: _onSolidHexChanged,
                onHexSubmitted: _submitSolidHex,
              )
            else
              _GradientColorPanel(
                startController: _startHexController,
                endController: _endHexController,
                startError: _startHexError,
                endError: _endHexError,
                startPreview: _startPreview,
                endPreview: _endPreview,
                onStartChanged: _onStartHexChanged,
                onEndChanged: _onEndHexChanged,
                onApply: _submitGradientHex,
              ),
          ],
        ),
      ),
    );
  }
}

class _SolidColorPanel extends StatelessWidget {
  const _SolidColorPanel({
    required this.hexController,
    required this.hexError,
    required this.previewColor,
    required this.onPresetSelected,
    required this.onHexChanged,
    required this.onHexSubmitted,
  });

  final TextEditingController hexController;
  final String? hexError;
  final Color previewColor;
  final ValueChanged<Color> onPresetSelected;
  final ValueChanged<String> onHexChanged;
  final VoidCallback onHexSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GenerateCubit.topBgColorPresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final color = GenerateCubit.topBgColorPresets[index];
              final isSelected =
                  color.toARGB32() == previewColor.toARGB32();
              return _ColorSwatch(
                color: color,
                selected: isSelected,
                onTap: () => onPresetSelected(color),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _ColorPreviewBar(color: previewColor),
        const SizedBox(height: 20),
        TextField(
          controller: hexController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[#a-fA-F0-9]')),
            LengthLimitingTextInputFormatter(7),
          ],
          decoration: InputDecoration(
            labelText: 'Hex color',
            hintText: '#RRGGBB',
            errorText: hexError,
            prefixIcon: const Icon(Icons.tag),
            suffixIcon: IconButton(
              tooltip: 'Apply',
              onPressed: onHexSubmitted,
              icon: const Icon(Icons.check_circle_outline),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: onHexChanged,
          onSubmitted: (_) => onHexSubmitted(),
        ),
      ],
    );
  }
}

class _GradientColorPanel extends StatelessWidget {
  const _GradientColorPanel({
    required this.startController,
    required this.endController,
    required this.startError,
    required this.endError,
    required this.startPreview,
    required this.endPreview,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onApply,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final String? startError;
  final String? endError;
  final Color startPreview;
  final Color endPreview;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HexColorField(
          label: 'Color A (top)',
          controller: startController,
          errorText: startError,
          onChanged: onStartChanged,
          onSubmitted: onApply,
        ),
        const SizedBox(height: 12),
        _HexColorField(
          label: 'Color B (bottom)',
          controller: endController,
          errorText: endError,
          onChanged: onEndChanged,
          onSubmitted: onApply,
        ),
        const SizedBox(height: 16),
        _ColorPreviewBar(
          color: startPreview,
          endColor: endPreview,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onApply, child: const Text('Apply gradient')),
      ],
    );
  }
}

class _ColorPreviewBar extends StatelessWidget {
  const _ColorPreviewBar({
    required this.color,
    this.endColor,
  });

  final Color color;
  final Color? endColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: endColor == null ? color : null,
        gradient: endColor == null
            ? null
            : LinearGradient(
                colors: [color, endColor!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        border: Border.all(
          color: AppColors.secondaryText.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _HexColorField extends StatelessWidget {
  const _HexColorField({
    required this.label,
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[#a-fA-F0-9]')),
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: '#RRGGBB',
        errorText: errorText,
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = color.computeLuminance() > 0.85
        ? AppColors.secondaryText
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
