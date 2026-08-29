import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web index uses quick_ticket_maker1.JPEG as favicon', () {
    final html = File('web/index.html').readAsStringSync();

    expect(
      html,
      contains(
        '<link rel="icon" type="image/jpeg" href="quick_ticket_maker1.JPEG"/>',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="apple-touch-icon" href="quick_ticket_maker1.JPEG"/>',
      ),
    );
    expect(html, isNot(contains('favicon.png')));
    expect(html, isNot(contains('favicon.ico')));
    expect(html, isNot(contains('icons/Icon-192.png')));
    expect(File('web/quick_ticket_maker1.JPEG').existsSync(), isTrue);
  });
}
