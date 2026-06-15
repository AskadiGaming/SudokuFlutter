import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/profile_scope.dart';
import '../features/profile/presentation/widgets/profile_avatar_button.dart';
import 'startup/app_startup_controller.dart';
import 'startup/app_startup_gate.dart';
import 'theme/app_theme.dart';

class SudokuApp extends StatefulWidget {
  const SudokuApp({super.key});

  @override
  State<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> {
  Locale _locale = AppStartupController.defaultLocale;
  late final AppStartupController _startupController;
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _startupController =
        AppStartupController()..addListener(_handleStartupChanged);
    _startupController.initialize();
  }

  void _handleStartupChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _locale = _startupController.locale;
    });
  }

  Future<void> _updateLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      AppStartupController.languagePreferenceKey,
      locale.languageCode,
    );
  }

  Locale _resolveLocale(Locale? deviceLocale) {
    if (deviceLocale == null) {
      return AppStartupController.defaultLocale;
    }
    for (final Locale supportedLocale
        in AppStartupController.supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }
    return AppStartupController.defaultLocale;
  }

  @override
  Widget build(BuildContext context) {
    final profileController = _startupController.profileController;
    final bool isStartupReady = _startupController.state.isReady;

    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      title: 'Sudoku',
      theme: darkBlueTheme,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppStartupController.supportedLocales,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> _) => _resolveLocale(locale),
      builder: (BuildContext context, Widget? child) {
        final Widget resolvedChild = child ?? const SizedBox.shrink();
        if (profileController == null || !isStartupReady) {
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
      home: AppStartupGate(
        controller: _startupController,
        currentLocale: _locale,
        onLocaleChanged: _updateLocale,
      ),
    );
  }

  @override
  void dispose() {
    _startupController
      ..removeListener(_handleStartupChanged)
      ..dispose();
    super.dispose();
  }
}
