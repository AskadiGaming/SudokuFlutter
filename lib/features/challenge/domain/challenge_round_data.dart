import '../../sudoku/domain/sudoku_difficulty.dart';

class ChallengeRoundData {
  const ChallengeRoundData({
    required this.date,
    required this.difficulty,
    required this.sudokuId,
    required this.puzzleString,
    required this.currentGridString,
    required this.isCompleted,
  });

  final DateTime date;
  final SudokuDifficulty difficulty;
  final int sudokuId;
  final String puzzleString;
  final String currentGridString;
  final bool isCompleted;

  ChallengeRoundData copyWith({String? currentGridString, bool? isCompleted}) {
    return ChallengeRoundData(
      date: date,
      difficulty: difficulty,
      sudokuId: sudokuId,
      puzzleString: puzzleString,
      currentGridString: currentGridString ?? this.currentGridString,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
