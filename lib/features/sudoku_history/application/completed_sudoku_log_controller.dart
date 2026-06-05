import 'package:flutter/foundation.dart';

import '../data/completed_sudoku_log_repository.dart';
import '../domain/completed_sudoku_entry.dart';

class CompletedSudokuLogController extends ChangeNotifier {
  CompletedSudokuLogController({
    required CompletedSudokuLogRepository repository,
  }) : _repository = repository;

  final CompletedSudokuLogRepository _repository;

  bool _isLoading = false;
  Object? _error;
  List<CompletedSudokuEntry> _entries = const <CompletedSudokuEntry>[];

  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<CompletedSudokuEntry> get entries => _entries;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.getCompletedSudokus();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
