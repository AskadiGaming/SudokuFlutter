import 'package:flutter/material.dart';

enum AppThemeKey {
  white('white', 'Weiss'),
  black('black', 'Schwarz'),
  darkBlue('darkBlue', 'Dunkelblau'),
  lightBlue('lightBlue', 'Hellblau'),
  red('red', 'Rot'),
  darkGreen('darkGreen', 'Dunkelgruen'),
  lightGreen('lightGreen', 'Hellgruen'),
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
