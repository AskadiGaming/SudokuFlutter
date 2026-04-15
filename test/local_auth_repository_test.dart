import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/data/local_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalAuthRepository', () {
    test('creates a local session when there is no stored session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocalAuthRepository repository = LocalAuthRepository(
        preferences: preferences,
      );

      await repository.restoreSession();

      expect(repository.currentSession, isNotNull);
      expect(repository.currentSession!.isAuthenticated, isTrue);
      expect(repository.currentSession!.userId, 'local_profile_user');
    });

    test('replaces invalid stored session with local session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_session': '{"isAuthenticated":true}',
      });
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocalAuthRepository repository = LocalAuthRepository(
        preferences: preferences,
      );

      await repository.restoreSession();

      expect(repository.currentSession, isNotNull);
      expect(repository.currentSession!.userId, 'local_profile_user');
      expect(preferences.getString('auth_session'), isNotNull);
    });
  });
}
