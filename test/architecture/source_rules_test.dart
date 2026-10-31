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
      .where((file) => !file.path.endsWith('source_rules_test.dart'))
      .toList(growable: false);

  test('color literals and Material colors stay in AppColors (UI-02/03)', () {
    final inlineColor = RegExp(r'\bColor\s*\(\s*0[xX]|\bColors\s*\.');
    final violations = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll(Platform.pathSeparator, '/');
      if (path == 'lib/core/constants/color_constant.dart') {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (inlineColor.hasMatch(lines[i])) {
          violations.add('$path:${i + 1}');
        }
      }
    }
    expect(violations, isEmpty);
  });

  const authDsDir = 'lib/features/auth/data/datasources';
  const listingDsDir = 'lib/features/lesson_listings/data/datasources';

  test(
    'Firebase and Google SDK imports stay strictly inside Firebase datasources '
    'and core Firebase bootstrap/options (ARCH-03/04)',
    () {
      const allowedFiles = <String>{
        'lib/core/firebase/firebase_bootstrap.dart',
        'lib/core/firebase/firebase_options.dart',
        '$authDsDir/firebase_auth_data_source.dart',
        '$authDsDir/firestore_user_profile_data_source.dart',
        '$listingDsDir/firestore_lesson_listing_data_source.dart',
      };
      final sdkImport = RegExp(
        'package:(firebase_core|firebase_auth|cloud_firestore|google_sign_in)/',
      );
      final violations = <String>[];
      for (final file in files) {
        final path = file.path.replaceAll(Platform.pathSeparator, '/');
        if (!path.startsWith('lib/') || allowedFiles.contains(path)) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (sdkImport.hasMatch(lines[i])) {
            violations.add('$path:${i + 1}');
          }
        }
      }
      expect(violations, isEmpty);
    },
  );

  test('mock datasource files are preserved intact', () {
    const requiredMocks = <String>[
      '$authDsDir/mock_auth_data_source.dart',
      '$authDsDir/mock_user_profile_data_source.dart',
      '$listingDsDir/mock_lesson_listing_data_source.dart',
    ];
    for (final mockPath in requiredMocks) {
      final file = File(mockPath);
      expect(file.existsSync(), isTrue, reason: 'Missing $mockPath');
      expect(file.readAsStringSync().trim(), isNotEmpty);
    }
  });

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
