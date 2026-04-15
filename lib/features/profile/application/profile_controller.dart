import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/profile_state.dart';
import 'auth_controller.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required AuthController authController})
    : _authController = authController {
    _authController.addListener(_onSessionChanged);
  }

  static const String defaultUsername = 'SudokuPlayer#123123';

  final AuthController _authController;

  ProfileState _state = const ProfileState(effectiveUsername: defaultUsername);
  bool _isLoading = false;
  bool _isInitialized = false;

  ProfileState get state => _state;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    await _syncWithSession();
    _isInitialized = true;
  }

  @override
  void dispose() {
    _authController.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    unawaited(_syncWithSession());
  }

  Future<void> _syncWithSession() async {
    if (!_authController.isAuthenticated) {
      _state = const ProfileState(effectiveUsername: defaultUsername);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final String? displayName = _authController.session?.displayName?.trim();
    _state = ProfileState(
      effectiveUsername:
          (displayName == null || displayName.isEmpty)
              ? defaultUsername
              : displayName,
    );
    _isLoading = false;
    notifyListeners();
  }
}
