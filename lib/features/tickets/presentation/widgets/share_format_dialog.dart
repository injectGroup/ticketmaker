import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Formats a guest can send their ticket in.
enum TicketShareFormat {
  image,
  pdf,
}

/// Asks whether to share the ticket as an image or as a PDF.
///
/// Returns `null` when the guest dismisses the sheet, which cancels the share.
Future<TicketShareFormat?> showShareFormatDialog(BuildContext context) {
  return showDialog<TicketShareFormat>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        key: const Key('share-format-dialog'),
        title: const Text('Share Ticket'),
        contentPadding: const EdgeInsets.only(bottom: 12),
        children: [
          _FormatOption(
            optionKey: const Key('share-format-image'),
            icon: Icons.image_outlined,
            label: 'Share as image',
            detail: 'Best for WhatsApp, Messages and other chats',
            format: TicketShareFormat.image,
          ),
          _FormatOption(
            optionKey: const Key('share-format-pdf'),
            icon: Icons.picture_as_pdf_outlined,
            label: 'Share as PDF',
            detail: 'Best for email, or printing at the door',
            format: TicketShareFormat.pdf,
          ),
        ],
      );
    },
  );
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.optionKey,
    required this.icon,
    required this.label,
    required this.detail,
    required this.format,
  });

  final Key optionKey;
  final IconData icon;
  final String label;
  final String detail;
  final TicketShareFormat format;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: optionKey,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: Text(
        detail,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
      onTap: () => Navigator.of(context).pop(format),
    );
  }
}
