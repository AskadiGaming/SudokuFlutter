import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/profile/application/profile_controller.dart';
import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/profile_scope.dart';
import '../features/profile/presentation/widgets/profile_avatar_button.dart';
import 'main_navigation_page.dart';
import 'theme/app_theme.dart';

class SudokuApp extends StatefulWidget {
  const SudokuApp({super.key});

  @override
  State<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> {
  static const Locale _defaultLocale = Locale('de');
  static const String _languagePreferenceKey = 'app_language';
  static const List<Locale> _supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  Locale _locale = _defaultLocale;
  ProfileController? _profileController;
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    ProfileController? profileController;

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? savedLanguageCode = preferences.getString(
        _languagePreferenceKey,
      );
      final Locale? loadedLocale =
          savedLanguageCode == null
              ? null
              : _localeFromLanguageCode(savedLanguageCode);

      profileController = ProfileController(
        repository: LocalProfileRepository(preferences: preferences),
      );
      await profileController.initialize();

      if (!mounted) {
        profileController.dispose();
        return;
      }

      setState(() {
        _locale = loadedLocale ?? _locale;
        _profileController = profileController;
      });
    } catch (error, stackTrace) {
      profileController?.dispose();
      debugPrint('Profile initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Locale? _localeFromLanguageCode(String languageCode) {
    for (final Locale supportedLocale in _supportedLocales) {
      if (supportedLocale.languageCode == languageCode) {
        return supportedLocale;
      }
    }
    return null;
  }

  Future<void> _updateLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languagePreferenceKey, locale.languageCode);
  }

  Locale _resolveLocale(Locale? deviceLocale) {
    if (deviceLocale == null) {
      return _defaultLocale;
    }
    for (final Locale supportedLocale in _supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }
    return _defaultLocale;
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController? profileController = _profileController;

    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      title: 'Sudoku',
      theme: darkBlueTheme,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: _supportedLocales,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> _) => _resolveLocale(locale),
      builder: (BuildContext context, Widget? child) {
        final Widget resolvedChild = child ?? const SizedBox.shrink();
        if (profileController == null) {
          return resolvedChild;
        }

        return ProfileScope(
          profileController: profileController,
          child: Stack(
            children: <Widget>[
              resolvedChild,
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: ProfileAvatarButton(
                      onPressed: () {
                        _rootNavigatorKey.currentState?.push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      home: MainNavigationPage(
        currentLocale: _locale,
        onLocaleChanged: _updateLocale,
      ),
    );
  }

  @override
  void dispose() {
    _profileController?.dispose();
    super.dispose();
  }
}
