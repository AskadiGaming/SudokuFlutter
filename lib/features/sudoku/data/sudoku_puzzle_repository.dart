import '../domain/sudoku_difficulty.dart';

abstract class SudokuPuzzleRepository {
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty);
  Future<String> getOrCreateDailyPuzzle(DateTime date);
}
