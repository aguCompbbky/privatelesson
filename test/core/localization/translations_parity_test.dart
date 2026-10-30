import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _flatKeys(Map<String, dynamic> json, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in json.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      keys.addAll(_flatKeys(value, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}

Map<String, dynamic> _load(String name) {
  final content = File('assets/translations/$name.json').readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

void main() {
  test('tr.json and en.json contain exactly the same keys', () {
    final tr = _flatKeys(_load('tr'));
    final en = _flatKeys(_load('en'));

    expect(tr, isNotEmpty);
    expect(tr.difference(en), isEmpty, reason: 'Missing in en.json');
    expect(en.difference(tr), isEmpty, reason: 'Missing in tr.json');
  });
}
