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

  @override
  void initState() {
    super.initState();
    final ticket = context.read<GenerateCubit>().state.ticket;
    final start = ticket.topGradientStart;
    final end = ticket.topGradientEnd;
    final isSolid = start.toARGB32() == end.toARGB32();

    _mode = isSolid ? _TopBgMode.solid : _TopBgMode.gradient;
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
    context.read<GenerateCubit>().applyTopBackgroundSolid(color);
    _dismissAfterApply();
  }

  void _submitSolidHex() {
    final ok =
        context.read<GenerateCubit>().applyTopBackgroundSolidHex(
              _solidHexController.text,
            );
    if (ok) {
      _dismissAfterApply();
      return;
    }
    setState(() {
      _solidHexError = 'Enter a valid hex color (#RRGGBB)';
    });
  }

  void _submitGradientHex() {
    final startRaw = _startHexController.text;
    final endRaw = _endHexController.text;
    final start = GenerateCubit.tryParseHexColor(startRaw);
    final end = GenerateCubit.tryParseHexColor(endRaw);

    final startError =
        start == null ? 'Enter a valid hex color (#RRGGBB)' : null;
    final endError = end == null ? 'Enter a valid hex color (#RRGGBB)' : null;

    if (start == null || end == null) {
      setState(() {
        _startHexError = startError;
        _endHexError = endError;
      });
      return;
    }

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
                onPresetSelected: _onSolidPresetSelected,
                onHexChanged: () {
                  if (_solidHexError != null) {
                    setState(() => _solidHexError = null);
                  }
                },
                onHexSubmitted: _submitSolidHex,
              )
            else
              _GradientColorPanel(
                startController: _startHexController,
                endController: _endHexController,
                startError: _startHexError,
                endError: _endHexError,
                onStartChanged: () {
                  if (_startHexError != null) {
                    setState(() => _startHexError = null);
                  }
                },
                onEndChanged: () {
                  if (_endHexError != null) {
                    setState(() => _endHexError = null);
                  }
                },
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
    required this.onPresetSelected,
    required this.onHexChanged,
    required this.onHexSubmitted,
  });

  final TextEditingController hexController;
  final String? hexError;
  final ValueChanged<Color> onPresetSelected;
  final VoidCallback onHexChanged;
  final VoidCallback onHexSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<GenerateCubit, GenerateState>(
          buildWhen: (previous, current) =>
              previous.ticket.topGradientStart !=
                  current.ticket.topGradientStart ||
              previous.ticket.topGradientEnd != current.ticket.topGradientEnd,
          builder: (context, state) {
            final selected = state.ticket.topGradientStart;
            final isSolid = selected.toARGB32() ==
                state.ticket.topGradientEnd.toARGB32();
            return SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: GenerateCubit.topBgColorPresets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = GenerateCubit.topBgColorPresets[index];
                  final isSelected = isSolid &&
                      color.toARGB32() == selected.toARGB32();
                  return _ColorSwatch(
                    color: color,
                    selected: isSelected,
                    onTap: () => onPresetSelected(color),
                  );
                },
              ),
            );
          },
        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (_) => onHexChanged(),
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
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onApply,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final String? startError;
  final String? endError;
  final VoidCallback onStartChanged;
  final VoidCallback onEndChanged;
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
        BlocBuilder<GenerateCubit, GenerateState>(
          buildWhen: (previous, current) =>
              previous.ticket.topGradientStart !=
                  current.ticket.topGradientStart ||
              previous.ticket.topGradientEnd != current.ticket.topGradientEnd,
          builder: (context, state) {
            return Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    state.ticket.topGradientStart,
                    state.ticket.topGradientEnd,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(color: AppColors.secondaryText.withValues(alpha: 0.2)),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onApply,
          child: const Text('Apply gradient'),
        ),
      ],
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
  final VoidCallback onChanged;
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) => onChanged(),
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
