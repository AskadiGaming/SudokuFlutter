import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/data/local_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalProfileRepository', () {
    test('returns null when no username is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocalProfileRepository repository = LocalProfileRepository(
        preferences: preferences,
      );

      expect(await repository.loadUsername(), isNull);
    });

    test('returns stored username', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile_username': 'Alex',
      });
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocalProfileRepository repository = LocalProfileRepository(
        preferences: preferences,
      );

      expect(await repository.loadUsername(), 'Alex');
    });

    test('persists custom username and removes default username', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocalProfileRepository repository = LocalProfileRepository(
        preferences: preferences,
      );

      await repository.saveUsername('Mila');
      expect(preferences.getString('profile_username'), 'Mila');

      await repository.saveUsername('SudokuPlayer');
      expect(preferences.getString('profile_username'), isNull);
    });
  });
}
