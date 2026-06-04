import 'package:flutter/material.dart';

import '../application/profile_controller.dart';
import 'profile_scope.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController =
        ProfileScope.of(context).profileController;

    return AnimatedBuilder(
      animation: profileController,
      builder: (BuildContext context, Widget? _) {
        final String username = profileController.state.username;

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _ProfileHeader(
                username: username,
                onEdit:
                    () => _showEditUsernameDialog(context, profileController),
              ),
              if (profileController.isLoading) ...<Widget>[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditUsernameDialog(
    BuildContext context,
    ProfileController profileController,
  ) async {
    final TextEditingController textController = TextEditingController(
      text: profileController.state.username,
    );

    final String? editedUsername = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Username bearbeiten'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'SudokuPlayer',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed:
                  () => Navigator.of(dialogContext).pop(textController.text),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (editedUsername == null) {
      return;
    }

    await profileController.updateUsername(editedUsername);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username, required this.onEdit});

  final String username;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const CircleAvatar(radius: 28, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(username, style: Theme.of(context).textTheme.titleLarge),
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.edit, size: 14),
                      SizedBox(width: 4),
                      Text('bearbeiten'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
