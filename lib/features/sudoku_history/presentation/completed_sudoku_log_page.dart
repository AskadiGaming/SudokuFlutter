import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../sudoku/domain/sudoku_difficulty.dart';
import '../application/completed_sudoku_log_controller.dart';
import '../data/completed_sudoku_log_repository.dart';
import '../data/local_completed_sudoku_log_repository.dart';
import '../domain/completed_sudoku_entry.dart';

class CompletedSudokuLogPage extends StatefulWidget {
  const CompletedSudokuLogPage({this.repository, super.key});

  final CompletedSudokuLogRepository? repository;

  @override
  State<CompletedSudokuLogPage> createState() => _CompletedSudokuLogPageState();
}

class _CompletedSudokuLogPageState extends State<CompletedSudokuLogPage> {
  late final CompletedSudokuLogController _controller =
      CompletedSudokuLogController(
        repository: widget.repository ?? LocalCompletedSudokuLogRepository(),
      );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completedSudokusTitle)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isLoading && _controller.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null && _controller.entries.isEmpty) {
            return Center(
              child: Text(
                '${l10n.completedSudokusLoadingError}: ${_controller.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (_controller.entries.isEmpty) {
            return Center(child: Text(l10n.completedSudokusEmpty));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final CompletedSudokuEntry entry = _controller.entries[index];
              return _CompletedSudokuEntryCard(entry: entry);
            },
          );
        },
      ),
    );
  }
}

class _CompletedSudokuEntryCard extends StatelessWidget {
  const _CompletedSudokuEntryCard({required this.entry});

  final CompletedSudokuEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateFormat timestampFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _difficultyLabel(l10n, entry.difficulty),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.completedSudokusCompletedAtLabel}: ${timestampFormat.format(entry.completedAt)}',
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.completedSudokusDurationLabel}: ${_formatDuration(entry.durationSeconds)}',
            ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(AppLocalizations l10n, SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return l10n.quickmatchDifficultyEasy;
      case SudokuDifficulty.medium:
        return l10n.quickmatchDifficultyMedium;
      case SudokuDifficulty.hard:
        return l10n.quickmatchDifficultyHard;
      case SudokuDifficulty.extreme:
        return l10n.quickmatchDifficultyExtreme;
    }
  }

  String _formatDuration(int durationSeconds) {
    final Duration duration = Duration(seconds: durationSeconds);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ${duration.inMinutes.remainder(60)} min ${duration.inSeconds.remainder(60)} s';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ${duration.inSeconds.remainder(60)} s';
    }
    return '${duration.inSeconds} s';
  }
}
