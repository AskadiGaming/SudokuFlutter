import '../domain/user_session.dart';

abstract interface class AuthRepository {
  UserSession? get currentSession;

  Stream<UserSession?> authStateChanges();

  Future<void> restoreSession();

  void dispose();
}
