import 'package:flutter/material.dart';

/// Ticket text field that shows decorative `[ ]` until the user starts editing.
/// Brackets return when [resetToken] changes (e.g. after Save Ticket).
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

  /// When this value changes (e.g. after Save Ticket), brackets show again.
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
  bool _showBrackets = true;

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
      setState(() => _showBrackets = true);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus || !_showBrackets) return;
    setState(() => _showBrackets = false);
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
        if (_showBrackets) Text('[ ', style: widget.style),
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
            decoration: BracketedTicketField.plainDecoration.copyWith(
              hintText: widget.hintText,
              hintStyle: hintStyle,
            ),
            onChanged: widget.onChanged,
          ),
        ),
        if (_showBrackets) Text(' ]', style: widget.style),
      ],
    );
  }
}
