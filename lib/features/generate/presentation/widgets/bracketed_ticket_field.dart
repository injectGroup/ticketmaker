import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ticket text field with a modern section badge (light-pink tag + • •)
/// until the user starts editing. Badge returns when [resetToken] changes.
class BracketedTicketField extends StatefulWidget {
  const BracketedTicketField({
    super.key,
    required this.controller,
    required this.style,
    required this.onChanged,
    this.resetToken,
    this.textAlign = TextAlign.start,
    this.minLines = 1,
    this.maxLines = 1,
    this.cursorColor,
    this.leading,
    this.hintText,
  });

  final TextEditingController controller;
  final TextStyle? style;
  final ValueChanged<String> onChanged;

  /// When this value changes (e.g. after Save Ticket), badge shows again.
  final Object? resetToken;

  final TextAlign textAlign;
  final int minLines;
  final int maxLines;
  final Color? cursorColor;
  final Widget? leading;
  final String? hintText;

  static const InputDecoration plainDecoration = InputDecoration(
    isDense: true,
    isCollapsed: true,
    filled: false,
    fillColor: Colors.transparent,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    hoverColor: Colors.transparent,
  );

  @override
  State<BracketedTicketField> createState() => _BracketedTicketFieldState();
}

class _BracketedTicketFieldState extends State<BracketedTicketField> {
  late final FocusNode _focusNode;
  bool _showBadge = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant BracketedTicketField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      setState(() => _showBadge = true);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus || !_showBadge) return;
    setState(() => _showBadge = false);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style;
    // Pink pills sit on light blush — use dark, heavier type for legibility.
    // When the badge is dismissed, keep the caller style for the dark card.
    final fieldStyle = _showBadge
        ? baseStyle?.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w800,
          )
        : baseStyle;
    final hintStyle = fieldStyle?.copyWith(
      color: (_showBadge
              ? AppColors.primaryText
              : baseStyle?.color)
          ?.withValues(alpha: _showBadge ? 0.55 : 0.45),
      fontWeight: _showBadge ? FontWeight.w600 : FontWeight.w400,
    );
    final bulletStyle = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      fontSize: baseStyle?.fontSize,
      height: baseStyle?.height,
      letterSpacing: 0,
    );

    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      textAlignVertical: TextAlignVertical.center,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: fieldStyle,
      cursorColor: _showBadge ? AppColors.primary : widget.cursorColor,
      decoration: BracketedTicketField.plainDecoration.copyWith(
        hintText: widget.hintText,
        hintStyle: hintStyle,
      ),
      onChanged: widget.onChanged,
    );

    final content = _showBadge
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Text('•', style: bulletStyle),
                const SizedBox(width: 8),
                Expanded(child: field),
                const SizedBox(width: 8),
                Text('•', style: bulletStyle),
              ],
            ),
          )
        : Row(children: [Expanded(child: field)]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Expanded(child: content),
      ],
    );
  }
}
