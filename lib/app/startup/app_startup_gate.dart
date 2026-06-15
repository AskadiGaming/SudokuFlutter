import 'package:flutter/material.dart';

import '../main_navigation_page.dart';
import 'app_startup_controller.dart';
import 'app_startup_state.dart';
import 'first_load_splash_page.dart';

class AppStartupGate extends StatelessWidget {
  const AppStartupGate({
    required this.controller,
    required this.currentLocale,
    required this.onLocaleChanged,
    super.key,
  });

  final AppStartupController controller;
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final AppStartupState state = controller.state;
        if (state.isReady) {
          return MainNavigationPage(
            currentLocale: currentLocale,
            onLocaleChanged: onLocaleChanged,
          );
        }

        if (state.showFirstLoadSplash || state.hasError) {
          return FirstLoadSplashPage(
            progress: state.progress.clamp(0, 1),
            message: state.message,
            isLoading: state.status == AppStartupStatus.loading,
            errorMessage: state.errorMessage,
            onRetry: controller.retry,
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
