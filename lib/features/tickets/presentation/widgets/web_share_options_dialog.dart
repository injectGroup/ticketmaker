import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Options presented by the web Share Ticket dialog.
enum WebShareOption {
  downloadImage,
  sharePdf,
  copyLink,
}

/// Shows Download Ticket Image / Share as PDF / Copy Share Link (Flutter Web).
Future<WebShareOption?> showWebShareOptionsDialog(BuildContext context) {
  return showDialog<WebShareOption>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        key: const Key('web-share-options-dialog'),
        title: const Text('Share Ticket'),
        contentPadding: const EdgeInsets.only(bottom: 12),
        children: [
          _WebShareTile(
            optionKey: const Key('web-share-download-ticket'),
            icon: Icons.download_outlined,
            label: 'Download Ticket Image',
            detail: 'Saves a PNG you can attach anywhere',
            option: WebShareOption.downloadImage,
          ),
          _WebShareTile(
            optionKey: const Key('web-share-share-pdf'),
            icon: Icons.picture_as_pdf_outlined,
            label: 'Share as PDF',
            detail: 'Uses your browser share sheet, or downloads the file',
            option: WebShareOption.sharePdf,
          ),
          _WebShareTile(
            optionKey: const Key('web-share-copy-link'),
            icon: Icons.link_outlined,
            label: 'Copy Share Link',
            detail: 'Sends the verification link instead of a file',
            option: WebShareOption.copyLink,
          ),
        ],
      );
    },
  );
}

class _WebShareTile extends StatelessWidget {
  const _WebShareTile({
    required this.optionKey,
    required this.icon,
    required this.label,
    required this.detail,
    required this.option,
  });

  final Key optionKey;
  final IconData icon;
  final String label;
  final String detail;
  final WebShareOption option;

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
      onTap: () => Navigator.of(context).pop(option),
    );
  }
}
