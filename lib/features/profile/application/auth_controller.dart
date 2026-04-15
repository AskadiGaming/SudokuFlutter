import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/user_session.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  StreamSubscription<UserSession?>? _authSubscription;
  UserSession? _session;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserSession? get session => _session;
  bool get isAuthenticated => _session?.isAuthenticated ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    _authSubscription = _repository.authStateChanges().listen(
      (UserSession? nextSession) {
        _session = nextSession;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object _) {
        _errorMessage = 'Session konnte nicht geladen werden.';
        _isLoading = false;
        notifyListeners();
      },
    );

    try {
      await _repository.restoreSession();
      _session ??= _repository.currentSession;
    } catch (_) {
      _errorMessage = 'Session konnte nicht geladen werden.';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
