import 'package:flutter_test/flutter_test.dart';
import 'package:privatelesson/core/config/google_sign_in_config.dart';

void main() {
  group('GoogleSignInConfig', () {
    test('omitted and empty client IDs become null', () {
      const config = GoogleSignInConfig();

      expect(config.serverClientId, isNull);
      expect(config.iosClientId, isNull);
    });

    test('whitespace-only client IDs become null', () {
      const config = GoogleSignInConfig(
        serverClientId: '  ',
        iosClientId: '\t\n',
      );

      expect(config.serverClientId, isNull);
      expect(config.iosClientId, isNull);
    });

    test('trims configured IDs and keeps server and iOS IDs distinct', () {
      const config = GoogleSignInConfig(
        serverClientId: '  test-web-client-id  ',
        iosClientId: '  test-ios-client-id  ',
      );

      expect(config.serverClientId, 'test-web-client-id');
      expect(config.iosClientId, 'test-ios-client-id');
    });

    test('either client ID can be supplied independently', () {
      const serverOnly = GoogleSignInConfig(serverClientId: 'test-web-id');
      const iosOnly = GoogleSignInConfig(iosClientId: 'test-ios-id');

      expect(serverOnly.serverClientId, 'test-web-id');
      expect(serverOnly.iosClientId, isNull);
      expect(iosOnly.serverClientId, isNull);
      expect(iosOnly.iosClientId, 'test-ios-id');
    });

    test('reads the compile-time client ID configuration', () {
      const config = GoogleSignInConfig.fromEnvironment();
      final serverClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ).trim();
      final iosClientId = const String.fromEnvironment(
        'GOOGLE_IOS_CLIENT_ID',
      ).trim();

      expect(
        config.serverClientId,
        serverClientId.isEmpty ? null : serverClientId,
      );
      expect(config.iosClientId, iosClientId.isEmpty ? null : iosClientId);
    });
  });
}
