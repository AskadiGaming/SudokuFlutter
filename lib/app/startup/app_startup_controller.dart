import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/data/local_profile_repository.dart';
import '../../features/sudoku/data/models/startup_progress.dart';
import '../../features/sudoku/data/services/sudoku_seed_service.dart';
import 'app_startup_state.dart';

class AppStartupController extends ChangeNotifier {
  AppStartupController({
    SudokuSeedService? seedService,
    Future<SharedPreferences> Function()? preferencesLoader,
    ProfileController Function(SharedPreferences preferences)?
    profileControllerFactory,
  }) : _seedService = seedService ?? SudokuSeedService.instance,
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _profileControllerFactory =
           profileControllerFactory ??
           ((SharedPreferences preferences) => ProfileController(
             repository: LocalProfileRepository(preferences: preferences),
           ));

  static const Locale defaultLocale = Locale('de');
  static const String languagePreferenceKey = 'app_language';
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  final SudokuSeedService _seedService;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final ProfileController Function(SharedPreferences preferences)
  _profileControllerFactory;

  AppStartupState _state = const AppStartupState.loading();
  Locale _locale = defaultLocale;
  ProfileController? _profileController;
  VoidCallback? _seedProgressListener;
  Future<void>? _startupFuture;

  AppStartupState get state => _state;
  Locale get locale => _locale;
  ProfileController? get profileController => _profileController;

  Future<void> initialize() {
    final Future<void>? existingFuture = _startupFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final Future<void> startupFuture = _runStartup();
    _startupFuture = startupFuture;
    return startupFuture;
  }

  Future<void> retry() async {
    _startupFuture = null;
    await initialize();
  }

  Future<void> _runStartup() async {
    _setState(
      const AppStartupState.loading(
        progress: 0.02,
        message: 'Lade Einstellungen',
      ),
    );

    ProfileController? nextProfileController;
    try {
      final SharedPreferences preferences = await _preferencesLoader();
      final String? savedLanguageCode = preferences.getString(
        languagePreferenceKey,
      );
      _locale =
          savedLanguageCode == null
              ? _locale
              : _localeFromLanguageCode(savedLanguageCode) ?? _locale;

      _setState(
        const AppStartupState.loading(progress: 0.04, message: 'Lade Profil'),
      );

      nextProfileController = _profileControllerFactory(preferences);
      await nextProfileController.initialize();

      final SudokuSeedProgress currentProgress =
          _seedService.progressListenable.value;
      _seedProgressListener = () {
        _syncSeedProgress(_seedService.progressListenable.value);
      };
      _seedService.progressListenable.addListener(_seedProgressListener!);
      _syncSeedProgress(currentProgress);

      await _seedService.ensureSeeded();

      _profileController?.dispose();
      _profileController = nextProfileController;
      nextProfileController = null;

      _setState(const AppStartupState.ready());
    } catch (error, stackTrace) {
      nextProfileController?.dispose();
      debugPrint('App startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _setState(
        AppStartupState.error(
          errorMessage: error.toString(),
          progress: _state.progress,
          message:
              _state.message.isEmpty
                  ? 'Initialisierung fehlgeschlagen'
                  : _state.message,
          showFirstLoadSplash: _state.showFirstLoadSplash,
        ),
      );
    } finally {
      final VoidCallback? seedProgressListener = _seedProgressListener;
      if (seedProgressListener != null) {
        _seedService.progressListenable.removeListener(seedProgressListener);
      }
      _seedProgressListener = null;
    }
  }

  Locale? _localeFromLanguageCode(String languageCode) {
    for (final Locale supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == languageCode) {
        return supportedLocale;
      }
    }
    return null;
  }

  void _syncSeedProgress(SudokuSeedProgress progress) {
    _setState(
      AppStartupState.loading(
        progress: progress.progress,
        message: progress.message,
        showFirstLoadSplash: progress.showSplash,
      ),
    );
  }

  void _setState(AppStartupState nextState) {
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    final VoidCallback? seedProgressListener = _seedProgressListener;
    if (seedProgressListener != null) {
      _seedService.progressListenable.removeListener(seedProgressListener);
    }
    _profileController?.dispose();
    super.dispose();
  }
}
