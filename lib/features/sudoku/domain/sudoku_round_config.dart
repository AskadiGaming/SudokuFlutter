import 'sudoku_difficulty.dart';

class SudokuRoundConfig {
  const SudokuRoundConfig({
    required this.difficulty,
    this.crazyModeEnabled = false,
  });

  final SudokuDifficulty difficulty;
  final bool crazyModeEnabled;
}
