import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku_history/domain/completed_sudoku_mode.dart';

class SudokuReplayRoundKey {
  const SudokuReplayRoundKey({
    required this.mode,
    required this.difficulty,
    this.challengeDate,
    this.sourceSudokuId,
  });

  final CompletedSudokuMode mode;
  final SudokuDifficulty difficulty;
  final DateTime? challengeDate;
  final int? sourceSudokuId;
}
