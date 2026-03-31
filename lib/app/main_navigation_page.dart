import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../features/duell/presentation/duell_page.dart';
import '../features/quickmatch/presentation/quickmatch_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'theme/app_theme.dart';

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
