import '../domain/sudoku_difficulty.dart';

abstract class SudokuPuzzleRepository {
  Future<String> loadPuzzle(SudokuDifficulty difficulty);
}
