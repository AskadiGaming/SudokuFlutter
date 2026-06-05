import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../application/profile_controller.dart';
import '../../sudoku_history/data/completed_sudoku_log_repository.dart';
import '../../sudoku_history/presentation/completed_sudoku_log_page.dart';
import 'profile_scope.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({this.completedSudokuLogRepository, super.key});

  final CompletedSudokuLogRepository? completedSudokuLogRepository;

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController =
        ProfileScope.of(context).profileController;

    return AnimatedBuilder(
      animation: profileController,
      builder: (BuildContext context, Widget? _) {
        final String username = profileController.state.username;
        final AppLocalizations l10n = AppLocalizations.of(context)!;

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
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                leading: const Icon(Icons.history),
                title: Text(l10n.showCompletedSudokus),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (BuildContext context) => CompletedSudokuLogPage(
                              repository: completedSudokuLogRepository,
                            ),
                      ),
                    ),
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed:
                  () => Navigator.of(dialogContext).pop(textController.text),
              child: Text(l10n.dialogSave),
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
