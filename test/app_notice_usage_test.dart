import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature UI presents transient feedback through AppNotice', () {
    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('app_notice.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'\bSnackBar\s*\(').allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        violations.add('${file.path}:$line');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature UI must present transient feedback through AppNotice:\n'
          '${violations.join('\n')}',
    );
  });
}
