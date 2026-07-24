import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Clean editable ticket field (no decorative brackets).
/// Shows a subtle underline hint until focused or [resetToken] cycles.
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

  /// When this value changes (e.g. after Save Ticket), hint underline returns.
  final Object? resetToken;

  final TextAlign textAlign;
  final int minLines;
  final int maxLines;
  final Color? cursorColor;
  final Widget? leading;
  final String? hintText;

  static InputDecoration decoration({
    required bool showHintLine,
    Color? hintLineColor,
    String? hintText,
    TextStyle? hintStyle,
  }) {
    final lineColor =
        (hintLineColor ?? AppColors.secondaryText).withValues(alpha: 0.35);
    return InputDecoration(
      isDense: true,
      isCollapsed: false,
      filled: false,
      fillColor: Colors.transparent,
      hintText: hintText,
      hintStyle: hintStyle,
      border: InputBorder.none,
      enabledBorder: showHintLine
          ? UnderlineInputBorder(
              borderSide: BorderSide(color: lineColor, width: 1),
            )
          : InputBorder.none,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: (hintLineColor ?? AppColors.primary).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      hoverColor: Colors.transparent,
    );
  }

  @override
  State<BracketedTicketField> createState() => _BracketedTicketFieldState();
}

class _BracketedTicketFieldState extends State<BracketedTicketField> {
  late final FocusNode _focusNode;
  bool _showHintLine = true;

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
      setState(() => _showHintLine = true);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _showHintLine) {
      setState(() => _showHintLine = false);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle = widget.style?.copyWith(
      color: widget.style?.color?.withValues(alpha: 0.45),
      fontWeight: FontWeight.w400,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textAlign: widget.textAlign,
            textAlignVertical: TextAlignVertical.center,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            style: widget.style,
            cursorColor: widget.cursorColor,
            decoration: BracketedTicketField.decoration(
              showHintLine: _showHintLine && !_focusNode.hasFocus,
              hintLineColor: widget.cursorColor ?? widget.style?.color,
              hintText: widget.hintText,
              hintStyle: hintStyle,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
