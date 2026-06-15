import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/sudoku_difficulty.dart';
import '../services/sudoku_seed_service.dart';

export '../services/sudoku_seed_parser.dart' show parseSudokuLines;

class SudokuLocalDataSource {
  SudokuLocalDataSource({
    AppDatabase? appDatabase,
    SudokuSeedService? seedService,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _seedService = seedService ?? SudokuSeedService.instance;

  final AppDatabase _appDatabase;
  final SudokuSeedService _seedService;

  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async {
    await ensureSeeded();
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      'sudoku',
      columns: <String>['sudoku_string'],
      where: 'difficulty = ?',
      whereArgs: <Object>[difficulty.storageValue],
      orderBy: 'RANDOM()',
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('No puzzle found for difficulty: $difficulty');
    }
    return rows.first['sudoku_string']! as String;
  }

  Future<String> getOrCreateDailySudoku(DateTime date) async {
    await ensureSeeded();
    final Database db = await _appDatabase.database;
    final String day = _toIsoDate(date);

    final List<Map<String, Object?>> existing = await db.query(
      'sudoku',
      columns: <String>['sudoku_string'],
      where: 'daily = ?',
      whereArgs: <Object>[day],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['sudoku_string']! as String;
    }

    return db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> available = await txn.query(
        'sudoku',
        columns: <String>['id', 'sudoku_string'],
        where: 'daily IS NULL',
        orderBy: 'RANDOM()',
        limit: 1,
      );
      if (available.isNotEmpty) {
        final int id = available.first['id']! as int;
        final String sudoku = available.first['sudoku_string']! as String;
        await txn.update(
          'sudoku',
          <String, Object?>{'daily': day},
          where: 'id = ?',
          whereArgs: <Object>[id],
        );
        return sudoku;
      }

      final List<Map<String, Object?>> fallback = await txn.query(
        'sudoku',
        columns: <String>['sudoku_string'],
        orderBy: 'RANDOM()',
        limit: 1,
      );
      if (fallback.isEmpty) {
        throw StateError('No Sudoku puzzles available for daily challenge.');
      }
      return fallback.first['sudoku_string']! as String;
    });
  }

  Future<void> ensureSeeded() async {
    await _seedService.ensureSeeded();
  }

  String _toIsoDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
