import 'package:flutter/material.dart';

/// Options presented by the web Share Ticket dialog.
enum WebShareOption {
  downloadImage,
  copyLink,
}

/// Shows Download Ticket Image / Copy Share Link choices (Flutter Web).
Future<WebShareOption?> showWebShareOptionsDialog(BuildContext context) {
  return showDialog<WebShareOption>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('web-share-options-dialog'),
        title: const Text('Share Ticket'),
        content: const Text(
          'Choose how you want to share this ticket.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            key: const Key('web-share-copy-link'),
            onPressed: () => Navigator.of(dialogContext).pop(
              WebShareOption.copyLink,
            ),
            child: const Text('Copy Share Link'),
          ),
          FilledButton(
            key: const Key('web-share-download-ticket'),
            onPressed: () => Navigator.of(dialogContext).pop(
              WebShareOption.downloadImage,
            ),
            child: const Text('Download Ticket Image'),
          ),
        ],
      );
    },
  );
}
