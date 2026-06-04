import '../../sudoku/domain/sudoku_difficulty.dart';

class ChallengeSelection {
  const ChallengeSelection({required this.date, required this.difficulty});

  final DateTime date;
  final SudokuDifficulty difficulty;
}
