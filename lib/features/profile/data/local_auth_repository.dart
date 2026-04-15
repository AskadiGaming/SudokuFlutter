import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_session.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _sessionKey = 'auth_session';
  static const String _localUserId = 'local_profile_user';
  static const String _defaultDisplayName = 'SudokuPlayer#123123';

  final SharedPreferences _preferences;
  final StreamController<UserSession?> _authStateController =
      StreamController<UserSession?>.broadcast();

  UserSession? _currentSession;

  @override
  UserSession? get currentSession => _currentSession;

  @override
  Stream<UserSession?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> restoreSession() async {
    final String? storedSession = _preferences.getString(_sessionKey);
    if (storedSession == null) {
      await _createDefaultSession();
      _emitCurrentSession();
      return;
    }

    try {
      final UserSession restoredSession = UserSession.fromJson(storedSession);
      if (!restoredSession.isAuthenticated ||
          restoredSession.userId == null ||
          restoredSession.userId!.isEmpty) {
        await _createDefaultSession();
      } else {
        _currentSession = restoredSession;
      }
    } catch (_) {
      await _createDefaultSession();
    }
    _emitCurrentSession();
  }

  @override
  void dispose() {
    _authStateController.close();
  }

  Future<void> _createDefaultSession() async {
    _currentSession = const UserSession.authenticated(
      userId: _localUserId,
      displayName: _defaultDisplayName,
    );
    await _preferences.setString(_sessionKey, _currentSession!.toJson());
  }

  void _emitCurrentSession() {
    if (_authStateController.isClosed) {
      return;
    }
    _authStateController.add(_currentSession);
  }
}
