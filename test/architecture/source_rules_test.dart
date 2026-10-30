import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checks project rules that the standard analyzer rules do not enforce.
void main() {
  final cascade = RegExp(r'(?<!\.)\.\.(?![./])');
  final forbidden = <String, Pattern>{
    'cascade operator (STYLE-01)': cascade,
    'setState (STATE-01)': 'setState(',
    'Navigator (ROUTE-01)': 'Navigator.',
    'MaterialPageRoute (ROUTE-01)': 'MaterialPageRoute',
  };

  final files = ['lib', 'test']
      .map(Directory.new)
      .where((dir) => dir.existsSync())
      .expand((dir) => dir.listSync(recursive: true))
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('source_rules_test.dart'));

  for (final entry in forbidden.entries) {
    test('no ${entry.key} in sources', () {
      final violations = <String>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) {
            continue;
          }
          if (line.contains(entry.value)) {
            violations.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(violations, isEmpty);
    });
  }
}
