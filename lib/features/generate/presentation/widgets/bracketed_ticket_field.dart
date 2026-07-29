import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ticket text field in an off-white capsule so it reads as an editable input.
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

  /// Kept for call-site compatibility after Save Ticket.
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

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _requestEdit() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style;
    final fieldStyle = baseStyle?.copyWith(
      color: AppColors.pillText,
      fontWeight: FontWeight.w800,
    );
    final hintStyle = fieldStyle?.copyWith(
      color: AppColors.pillText.withValues(alpha: 0.45),
      fontWeight: FontWeight.w600,
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
      cursorColor: AppColors.primary,
      cursorWidth: 2,
      decoration: BracketedTicketField.plainDecoration.copyWith(
        hintText: widget.hintText ?? 'Tap to edit…',
        hintStyle: hintStyle,
      ),
      onChanged: widget.onChanged,
    );

    final pill = Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text('•', style: bulletStyle),
          const SizedBox(width: 8),
          Expanded(child: field),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _requestEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.primary.withValues(
                  alpha: _focusNode.hasFocus ? 1 : 0.75,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Expanded(child: pill),
      ],
    );
  }
}
