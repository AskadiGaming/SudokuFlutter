import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/sudoku/domain/sudoku_difficulty.dart';
import 'features/sudoku/presentation/play_sudoku_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.onThemeChanged,
    super.key,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final AppThemeKey currentTheme;
  final ValueChanged<AppThemeKey> onThemeChanged;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<String> titles = <String>[
      l10n.pageDuell,
      l10n.pageQuickmatch,
      l10n.pageSettings,
    ];
    final List<Widget> pages = <Widget>[
      const DuellPage(),
      const QuickmatchPage(),
      SettingsPage(
        currentLocale: widget.currentLocale,
        onLocaleChanged: widget.onLocaleChanged,
        currentTheme: widget.currentTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[_selectedIndex]),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_kabaddi),
            label: l10n.tabDuell,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.today),
            label: l10n.tabQuickmatch,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

class DuellPage extends StatelessWidget {
  const DuellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.pageDuell));
  }
}

enum QuickmatchDifficulty { easy, medium, hard, extreme }

class QuickmatchPage extends StatefulWidget {
  const QuickmatchPage({super.key});

  @override
  State<QuickmatchPage> createState() => _QuickmatchPageState();
}

class _QuickmatchPageState extends State<QuickmatchPage> {
  QuickmatchDifficulty _selectedDifficulty = QuickmatchDifficulty.easy;

  SudokuDifficulty _mapToSudokuDifficulty(
    QuickmatchDifficulty quickmatchDifficulty,
  ) {
    switch (quickmatchDifficulty) {
      case QuickmatchDifficulty.easy:
        return SudokuDifficulty.easy;
      case QuickmatchDifficulty.medium:
        return SudokuDifficulty.medium;
      case QuickmatchDifficulty.hard:
        return SudokuDifficulty.hard;
      case QuickmatchDifficulty.extreme:
        return SudokuDifficulty.extreme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Map<QuickmatchDifficulty, String> difficultyLabels =
        <QuickmatchDifficulty, String>{
          QuickmatchDifficulty.easy: l10n.quickmatchDifficultyEasy,
          QuickmatchDifficulty.medium: l10n.quickmatchDifficultyMedium,
          QuickmatchDifficulty.hard: l10n.quickmatchDifficultyHard,
          QuickmatchDifficulty.extreme: l10n.quickmatchDifficultyExtreme,
        };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<QuickmatchDifficulty>(
            value: _selectedDifficulty,
            decoration: InputDecoration(
              labelText: l10n.quickmatchDifficultyLabel,
              border: const OutlineInputBorder(),
            ),
            items:
                QuickmatchDifficulty.values
                    .map(
                      (QuickmatchDifficulty difficulty) =>
                          DropdownMenuItem<QuickmatchDifficulty>(
                            value: difficulty,
                            child: Text(difficultyLabels[difficulty]!),
                          ),
                    )
                    .toList(),
            onChanged: (QuickmatchDifficulty? selectedDifficulty) {
              if (selectedDifficulty == null) {
                return;
              }
              setState(() {
                _selectedDifficulty = selectedDifficulty;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (BuildContext context) => PlaySudokuPage(
                        difficulty: _mapToSudokuDifficulty(_selectedDifficulty),
                      ),
                ),
              );
            },
            child: Text(l10n.quickmatchPlay),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.onThemeChanged,
    super.key,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final AppThemeKey currentTheme;
  final ValueChanged<AppThemeKey> onThemeChanged;

  static const List<_LanguageOption> _languageOptions = <_LanguageOption>[
    _LanguageOption(code: 'de', label: 'Deutsch'),
    _LanguageOption(code: 'en', label: 'English'),
    _LanguageOption(code: 'es', label: 'Español'),
    _LanguageOption(code: 'fr', label: 'Français'),
    _LanguageOption(code: 'it', label: 'Italiano'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l10n.settingsLanguageTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: currentLocale.languageCode,
          decoration: InputDecoration(
            labelText: l10n.settingsLanguageLabel,
            border: const OutlineInputBorder(),
          ),
          items:
              _languageOptions
                  .map(
                    (_LanguageOption option) => DropdownMenuItem<String>(
                      value: option.code,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
          onChanged: (String? selectedCode) {
            if (selectedCode == null) {
              return;
            }
            onLocaleChanged(Locale(selectedCode));
          },
        ),
        const SizedBox(height: 20),
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<AppThemeKey>(
          value: currentTheme,
          decoration: const InputDecoration(
            labelText: 'Farbschema',
            border: OutlineInputBorder(),
          ),
          items:
              AppThemeKey.values
                  .map(
                    (AppThemeKey option) => DropdownMenuItem<AppThemeKey>(
                      value: option,
                      child: Text(option.displayName),
                    ),
                  )
                  .toList(),
          onChanged: (AppThemeKey? selectedTheme) {
            if (selectedTheme == null) {
              return;
            }
            onThemeChanged(selectedTheme);
          },
        ),
      ],
    );
  }
}

enum AppThemeKey {
  white('white', 'Weiß'),
  black('black', 'Schwarz'),
  darkBlue('darkBlue', 'Dunkelblau'),
  lightBlue('lightBlue', 'Hellblau'),
  red('red', 'Rot'),
  darkGreen('darkGreen', 'Dunkelgrün'),
  lightGreen('lightGreen', 'Hellgrün'),
  orange('orange', 'Orange'),
  yellow('yellow', 'Gelb'),
  brown('brown', 'Braun');

  const AppThemeKey(this.storageKey, this.displayName);

  final String storageKey;
  final String displayName;
}

AppThemeKey? appThemeFromStorageKey(String value) {
  for (final AppThemeKey theme in AppThemeKey.values) {
    if (theme.storageKey == value) {
      return theme;
    }
  }
  return null;
}

final Map<AppThemeKey, ThemeData> appThemes = <AppThemeKey, ThemeData>{
  AppThemeKey.white: _buildTheme(
    seedColor: Colors.blueGrey,
    brightness: Brightness.light,
  ),
  AppThemeKey.black: _buildTheme(
    seedColor: Colors.grey,
    brightness: Brightness.dark,
  ),
  AppThemeKey.darkBlue: _buildTheme(
    seedColor: const Color(0xFF0D47A1),
    brightness: Brightness.dark,
  ),
  AppThemeKey.lightBlue: _buildTheme(
    seedColor: const Color(0xFF4FC3F7),
    brightness: Brightness.light,
  ),
  AppThemeKey.red: _buildTheme(
    seedColor: const Color(0xFFC62828),
    brightness: Brightness.light,
  ),
  AppThemeKey.darkGreen: _buildTheme(
    seedColor: const Color(0xFF1B5E20),
    brightness: Brightness.dark,
  ),
  AppThemeKey.lightGreen: _buildTheme(
    seedColor: const Color(0xFF81C784),
    brightness: Brightness.light,
  ),
  AppThemeKey.orange: _buildTheme(
    seedColor: const Color(0xFFF57C00),
    brightness: Brightness.light,
  ),
  AppThemeKey.yellow: _buildTheme(
    seedColor: const Color(0xFFFBC02D),
    brightness: Brightness.light,
  ),
  AppThemeKey.brown: _buildTheme(
    seedColor: const Color(0xFF6D4C41),
    brightness: Brightness.light,
  ),
};

ThemeData _buildTheme({
  required Color seedColor,
  required Brightness brightness,
}) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => IconThemeData(
          color:
              states.contains(WidgetState.selected)
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
    ),
    cardTheme: CardThemeData(color: colorScheme.surfaceContainerLow),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.primary),
    ),
  );
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}
