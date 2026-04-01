import 'datasources/sudoku_local_datasource.dart';
import 'repositories/sudoku_repository_impl.dart';

class LocalSudokuPuzzleRepository extends SudokuRepositoryImpl {
  LocalSudokuPuzzleRepository({SudokuLocalDataSource? localDataSource})
    : super(localDataSource: localDataSource);
}
