import '../domain/completed_sudoku_entry.dart';

abstract class CompletedSudokuLogRepository {
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry);

  Future<List<CompletedSudokuEntry>> getCompletedSudokus();
}
