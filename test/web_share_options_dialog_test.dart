import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/web_share_options_dialog.dart';

void main() {
  testWidgets('web share dialog offers download and copy link actions', (
    tester,
  ) async {
    WebShareOption? choice;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showWebShareOptionsDialog(context);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web-share-options-dialog')), findsOneWidget);
    expect(find.text('Download Ticket Image'), findsOneWidget);
    expect(find.text('Copy Share Link'), findsOneWidget);

    await tester.tap(find.byKey(const Key('web-share-copy-link')));
    await tester.pumpAndSettle();
    expect(choice, WebShareOption.copyLink);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('web-share-download-ticket')));
    await tester.pumpAndSettle();
    expect(choice, WebShareOption.downloadImage);
  });
}
