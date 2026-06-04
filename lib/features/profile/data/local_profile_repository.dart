import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _usernameKey = 'profile_username';

  final SharedPreferences _preferences;

  @override
  Future<String?> loadUsername() async {
    final String? storedUsername = _preferences.getString(_usernameKey)?.trim();
    if (storedUsername == null || storedUsername.isEmpty) {
      return null;
    }
    return storedUsername;
  }

  @override
  Future<void> saveUsername(String username) async {
    final String normalizedUsername = username.trim();
    if (normalizedUsername == 'SudokuPlayer') {
      await _preferences.remove(_usernameKey);
      return;
    }
    await _preferences.setString(_usernameKey, normalizedUsername);
  }
}
