import '../../domain/sudoku_difficulty.dart';
import '../datasources/sudoku_local_datasource.dart';
import '../sudoku_puzzle_repository.dart';

class SudokuRepositoryImpl implements SudokuPuzzleRepository {
  SudokuRepositoryImpl({SudokuLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? SudokuLocalDataSource();

  final SudokuLocalDataSource _localDataSource;

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) {
    return _localDataSource.getRandomByDifficulty(difficulty);
  }

  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) {
    return _localDataSource.getOrCreateDailySudoku(date);
  }
}
