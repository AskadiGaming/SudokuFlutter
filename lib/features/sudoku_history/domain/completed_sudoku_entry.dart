import '../../sudoku/domain/sudoku_difficulty.dart';
import 'completed_sudoku_mode.dart';

class CompletedSudokuEntry {
  const CompletedSudokuEntry({
    this.id,
    required this.difficulty,
    required this.mode,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    this.challengeDate,
    this.sourceSudokuId,
  });

  final int? id;
  final SudokuDifficulty difficulty;
  final CompletedSudokuMode mode;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final DateTime? challengeDate;
  final int? sourceSudokuId;
}
