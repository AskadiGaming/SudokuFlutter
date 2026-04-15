import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/application/auth_controller.dart';
import 'package:hello_world_app/features/profile/application/profile_controller.dart';
import 'package:hello_world_app/features/profile/data/auth_repository.dart';
import 'package:hello_world_app/features/profile/domain/user_session.dart';

void main() {
  group('ProfileController', () {
    test(
      'uses default username when no authenticated session is available',
      () async {
        final FakeAuthRepository authRepository = FakeAuthRepository();
        final AuthController authController = AuthController(
          repository: authRepository,
        );
        final ProfileController profileController = ProfileController(
          authController: authController,
        );

        await authController.initialize();
        await profileController.initialize();

      expect(profileController.state.effectiveUsername, 'SudokuPlayer#123123');

        profileController.dispose();
        authController.dispose();
      },
    );

    test('uses session display name when available', () async {
      final FakeAuthRepository authRepository = FakeAuthRepository(
        initialSession: const UserSession.authenticated(
          userId: 'local_profile_user',
          displayName: 'Alex',
        ),
      );
      final AuthController authController = AuthController(
        repository: authRepository,
      );
      final ProfileController profileController = ProfileController(
        authController: authController,
      );

      await authController.initialize();
      await profileController.initialize();

      expect(profileController.state.effectiveUsername, 'Alex');

      profileController.dispose();
      authController.dispose();
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({UserSession? initialSession})
    : _currentSession = initialSession;

  final StreamController<UserSession?> _controller =
      StreamController<UserSession?>.broadcast();
  final UserSession? _currentSession;

  @override
  UserSession? get currentSession => _currentSession;

  @override
  Stream<UserSession?> authStateChanges() => _controller.stream;

  @override
  Future<void> restoreSession() async {
    _controller.add(_currentSession);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
