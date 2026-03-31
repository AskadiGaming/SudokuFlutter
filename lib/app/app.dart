import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _themePreferenceKey = 'app_theme';
  static const List<Locale> _supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  Locale _locale = _defaultLocale;
  AppThemeKey _currentTheme = AppThemeKey.white;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? savedLanguageCode = preferences.getString(
      _languagePreferenceKey,
    );
    final String? savedThemeKey = preferences.getString(_themePreferenceKey);

    Locale? loadedLocale;
    AppThemeKey? loadedTheme;

    if (savedLanguageCode != null) {
      loadedLocale = _localeFromLanguageCode(savedLanguageCode);
    }

    if (savedThemeKey != null) {
      loadedTheme = appThemeFromStorageKey(savedThemeKey);
    }

    if (!mounted) {
      return;
    }

    if (loadedLocale != null || loadedTheme != null) {
      setState(() {
        if (loadedLocale != null) {
          _locale = loadedLocale;
        }
        if (loadedTheme != null) {
          _currentTheme = loadedTheme;
        }
      });
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

  Future<void> _updateTheme(AppThemeKey themeKey) async {
    setState(() {
      _currentTheme = themeKey;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, themeKey.storageKey);
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
    return MaterialApp(
      title: 'Sudoku',
      theme: appThemes[_currentTheme],
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: _supportedLocales,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> _) => _resolveLocale(locale),
      home: MainNavigationPage(
        currentLocale: _locale,
        onLocaleChanged: _updateLocale,
        currentTheme: _currentTheme,
        onThemeChanged: _updateTheme,
      ),
    );
  }
}
