import '../../sudoku/domain/sudoku_difficulty.dart';

class ChallengeRoundData {
  const ChallengeRoundData({
    required this.date,
    required this.difficulty,
    required this.sudokuId,
    required this.puzzleString,
    required this.currentGridString,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
  });

  final DateTime date;
  final SudokuDifficulty difficulty;
  final int sudokuId;
  final String puzzleString;
  final String currentGridString;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  ChallengeRoundData copyWith({
    String? currentGridString,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ChallengeRoundData(
      date: date,
      difficulty: difficulty,
      sudokuId: sudokuId,
      puzzleString: puzzleString,
      currentGridString: currentGridString ?? this.currentGridString,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
