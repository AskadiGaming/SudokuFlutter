import 'package:flutter/material.dart';

import '../application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../domain/user_session.dart';
import 'profile_scope.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileScope scope = ProfileScope.of(context);
    final AuthController authController = scope.authController;
    final ProfileController profileController = scope.profileController;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        authController,
        profileController,
      ]),
      builder: (BuildContext context, Widget? _) {
        final UserSession? session = authController.session;
        final String username = profileController.state.effectiveUsername;

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _ProfileHeader(session: session, username: username),
              const SizedBox(height: 20),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Username'),
                subtitle: Text(
                  'Der Username ist aktuell fest vorgegeben und kann nicht geaendert werden.',
                ),
              ),
              if (authController.errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  authController.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session, required this.username});

  final UserSession? session;
  final String username;

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = session?.photoUrl?.trim();
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 28,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: hasPhoto ? null : const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(username, style: Theme.of(context).textTheme.titleLarge),
              const Text('Lokales Profil'),
            ],
          ),
        ),
      ],
    );
  }
}
