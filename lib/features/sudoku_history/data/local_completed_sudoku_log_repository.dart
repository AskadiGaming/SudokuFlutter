import '../domain/completed_sudoku_entry.dart';
import 'completed_sudoku_log_local_data_source.dart';
import 'completed_sudoku_log_repository.dart';

class LocalCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  LocalCompletedSudokuLogRepository({
    CompletedSudokuLogLocalDataSource? localDataSource,
  }) : _localDataSource =
           localDataSource ?? CompletedSudokuLogLocalDataSource();

  final CompletedSudokuLogLocalDataSource _localDataSource;

  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) {
    return _localDataSource.addCompletedSudoku(entry);
  }

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() {
    return _localDataSource.getCompletedSudokus();
  }
}
