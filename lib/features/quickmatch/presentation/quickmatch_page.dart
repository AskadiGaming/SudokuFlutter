import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku/domain/sudoku_round_config.dart';
import '../application/quickmatch_round_starter.dart';
import '../domain/quickmatch_difficulty.dart';

class QuickmatchPage extends StatefulWidget {
  const QuickmatchPage({super.key});

  @override
  State<QuickmatchPage> createState() => _QuickmatchPageState();
}

class _QuickmatchPageState extends State<QuickmatchPage> {
  QuickmatchDifficulty _selectedDifficulty = QuickmatchDifficulty.easy;
  bool _isCrazyModeEnabled = false;
  late final QuickmatchRoundStarter _roundStarter;
  bool _isStartingRound = false;

  @override
  void initState() {
    super.initState();
    _roundStarter = QuickmatchRoundStarter();
  }

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

  Future<void> _startQuickmatchRound() async {
    if (_isStartingRound) {
      return;
    }

    setState(() {
      _isStartingRound = true;
    });

    try {
      await _roundStarter.startRound(
        context: context,
        roundConfig: SudokuRoundConfig(
          difficulty: _mapToSudokuDifficulty(_selectedDifficulty),
          crazyModeEnabled: _isCrazyModeEnabled,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRound = false;
        });
      }
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
          SwitchListTile(
            value: _isCrazyModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _isCrazyModeEnabled = value;
              });
            },
            title: Text(l10n.quickmatchCrazyModeToggle),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isStartingRound ? null : _startQuickmatchRound,
            child:
                _isStartingRound
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(l10n.quickmatchPlay),
          ),
        ],
      ),
    );
  }
}
