import 'package:flutter/material.dart';

/// Ticket text field that shows decorative `[ ]` when idle and hides them
/// while the field is focused for editing.
class BracketedTicketField extends StatefulWidget {
  const BracketedTicketField({
    super.key,
    required this.controller,
    required this.style,
    required this.onChanged,
    this.textAlign = TextAlign.start,
    this.minLines = 1,
    this.maxLines = 1,
    this.cursorColor,
    this.leading,
  });

  final TextEditingController controller;
  final TextStyle? style;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final int minLines;
  final int maxLines;
  final Color? cursorColor;
  final Widget? leading;

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
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _editing) return;
    setState(() => _editing = focused);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 20),
        ],
        if (!_editing) Text('[ ', style: widget.style),
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
            decoration: BracketedTicketField.plainDecoration,
            onChanged: widget.onChanged,
          ),
        ),
        if (!_editing) Text(' ]', style: widget.style),
      ],
    );
  }
}
