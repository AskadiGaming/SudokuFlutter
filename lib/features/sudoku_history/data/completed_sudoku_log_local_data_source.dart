import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../sudoku/domain/sudoku_difficulty.dart';
import '../domain/completed_sudoku_entry.dart';
import '../domain/completed_sudoku_mode.dart';

class CompletedSudokuLogLocalDataSource {
  CompletedSudokuLogLocalDataSource({
    AppDatabase? appDatabase,
    Future<Database> Function()? databaseProvider,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _databaseProvider = databaseProvider;

  final AppDatabase _appDatabase;
  final Future<Database> Function()? _databaseProvider;

  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {
    final Database db = await _database;
    await db.insert('completed_sudoku_log', _toRow(entry));
  }

  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'completed_sudoku_log',
      orderBy: 'completed_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Database> get _database async {
    final Future<Database> Function()? databaseProvider = _databaseProvider;
    if (databaseProvider != null) {
      return databaseProvider();
    }
    return _appDatabase.database;
  }

  Map<String, Object?> _toRow(CompletedSudokuEntry entry) {
    return <String, Object?>{
      'difficulty': entry.difficulty.storageValue,
      'mode': entry.mode.storageValue,
      'started_at': entry.startedAt.toIso8601String(),
      'completed_at': entry.completedAt.toIso8601String(),
      'duration_seconds': entry.durationSeconds,
      'challenge_date': _toIsoDate(entry.challengeDate),
      'source_sudoku_id': entry.sourceSudokuId,
    };
  }

  CompletedSudokuEntry _fromRow(Map<String, Object?> row) {
    return CompletedSudokuEntry(
      id: row['id']! as int,
      difficulty: SudokuDifficultyStorageMapper.fromStorageValue(
        row['difficulty']! as String,
      ),
      mode: CompletedSudokuModeStorageMapper.fromStorageValue(
        row['mode']! as String,
      ),
      startedAt: DateTime.parse(row['started_at']! as String),
      completedAt: DateTime.parse(row['completed_at']! as String),
      durationSeconds: row['duration_seconds']! as int,
      challengeDate: _parseIsoDate(row['challenge_date'] as String?),
      sourceSudokuId: row['source_sudoku_id'] as int?,
    );
  }

  String? _toIsoDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseIsoDate(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value);
  }
}
