import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku_history/domain/completed_sudoku_mode.dart';

class SudokuReplay {
  const SudokuReplay({
    required this.id,
    required this.mode,
    required this.difficulty,
    required this.puzzleString,
    required this.finalGridString,
    required this.playedDurationMillis,
    required this.createdAt,
    required this.updatedAt,
    this.challengeDate,
    this.sourceSudokuId,
    this.completedAt,
  });

  final int id;
  final CompletedSudokuMode mode;
  final SudokuDifficulty difficulty;
  final DateTime? challengeDate;
  final int? sourceSudokuId;
  final String puzzleString;
  final String finalGridString;
  final int playedDurationMillis;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
}
