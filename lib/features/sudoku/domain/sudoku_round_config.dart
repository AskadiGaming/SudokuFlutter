import 'sudoku_difficulty.dart';
import 'sudoku_round_mode.dart';

class SudokuRoundConfig {
  const SudokuRoundConfig({
    required this.difficulty,
    this.mode = SudokuRoundMode.normal,
    this.crazyModeEnabled = false,
    this.challengeDate,
    this.challengePuzzleId,
  });

  final SudokuDifficulty difficulty;
  final SudokuRoundMode mode;
  final bool crazyModeEnabled;
  final DateTime? challengeDate;
  final int? challengePuzzleId;
}
