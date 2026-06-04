import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../domain/profile_state.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required ProfileRepository repository})
    : _repository = repository;

  static const String defaultUsername = 'SudokuPlayer';

  final ProfileRepository _repository;

  ProfileState _state = const ProfileState(username: defaultUsername);
  bool _isLoading = false;
  bool _isInitialized = false;

  ProfileState get state => _state;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final String? storedUsername = await _repository.loadUsername();
      _state = ProfileState(username: _normalizeUsername(storedUsername));
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUsername(String username) async {
    final String normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername == _state.username) {
      return;
    }

    _state = _state.copyWith(username: normalizedUsername);
    notifyListeners();

    await _repository.saveUsername(normalizedUsername);
  }

  String _normalizeUsername(String? username) {
    final String? trimmedUsername = username?.trim();
    if (trimmedUsername == null || trimmedUsername.isEmpty) {
      return defaultUsername;
    }
    return trimmedUsername;
  }
}
