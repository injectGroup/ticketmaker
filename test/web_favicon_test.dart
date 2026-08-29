import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web index uses quick_ticket_maker1.jpeg as favicon', () {
    final html = File('web/index.html').readAsStringSync();

    expect(
      html,
      contains(
        '<link rel="icon" type="image/jpeg" href="quick_ticket_maker1.jpeg"/>',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="apple-touch-icon" href="quick_ticket_maker1.jpeg"/>',
      ),
    );
    expect(html, isNot(contains('favicon.png')));
    expect(html, isNot(contains('favicon.ico')));
    expect(html, isNot(contains('icons/Icon-192.png')));
    expect(
      html.contains('quick_ticket_maker1.JPEG'),
      isFalse,
      reason: 'href must be lowercase .jpeg for case-sensitive hosting',
    );
    expect(File('web/quick_ticket_maker1.jpeg').existsSync(), isTrue);
  });
}
