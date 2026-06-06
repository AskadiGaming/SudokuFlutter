import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku_history/domain/completed_sudoku_mode.dart';

class SudokuReplayDraft {
  const SudokuReplayDraft({
    required this.mode,
    required this.difficulty,
    required this.puzzleString,
    required this.createdAt,
    this.challengeDate,
    this.sourceSudokuId,
  });

  final CompletedSudokuMode mode;
  final SudokuDifficulty difficulty;
  final DateTime? challengeDate;
  final int? sourceSudokuId;
  final String puzzleString;
  final DateTime createdAt;
}
