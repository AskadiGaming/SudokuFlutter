import 'package:flutter/material.dart';

import '../application/auth_controller.dart';
import '../application/profile_controller.dart';

class ProfileScope extends InheritedWidget {
  const ProfileScope({
    required this.authController,
    required this.profileController,
    required super.child,
    super.key,
  });

  final AuthController authController;
  final ProfileController profileController;

  static ProfileScope of(BuildContext context, {bool listen = true}) {
    final ProfileScope? scope;
    if (listen) {
      scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    } else {
      final Element? element =
          context.getElementForInheritedWidgetOfExactType<ProfileScope>();
      final Widget? widget = element?.widget;
      scope = widget is ProfileScope ? widget : null;
    }

    assert(scope != null, 'ProfileScope is not available in this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ProfileScope oldWidget) {
    return authController != oldWidget.authController ||
        profileController != oldWidget.profileController;
  }
}
