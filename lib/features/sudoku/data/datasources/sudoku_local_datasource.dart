import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/sudoku_difficulty.dart';

class SudokuLocalDataSource {
  SudokuLocalDataSource({AppDatabase? appDatabase, AssetBundle? assetBundle})
    : _appDatabase = appDatabase ?? AppDatabase.instance,
      _assetBundle = assetBundle ?? rootBundle;

  final AppDatabase _appDatabase;
  final AssetBundle _assetBundle;
  Future<void>? _seedFuture;

  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async {
    await _ensureSeeded();
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
    await _ensureSeeded();
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

  Future<void> _ensureSeeded() async {
    final Future<void>? existingFuture = _seedFuture;
    if (existingFuture != null) {
      return existingFuture;
    }
    final Future<void> seedFuture = _seedIfNeeded();
    _seedFuture = seedFuture;
    return seedFuture;
  }

  Future<void> _seedIfNeeded() async {
    final Database db = await _appDatabase.database;
    final int existingCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sudoku'),
        ) ??
        0;
    if (existingCount > 0) {
      return;
    }

    final Map<SudokuDifficulty, List<String>> puzzlesByDifficulty =
        <SudokuDifficulty, List<String>>{};
    for (final SudokuDifficulty difficulty in SudokuDifficulty.values) {
      final String fileContent = await _assetBundle.loadString(
        _assetPathForDifficulty(difficulty),
      );
      puzzlesByDifficulty[difficulty] = parseSudokuLines(fileContent);
    }

    await db.transaction((Transaction txn) async {
      for (final SudokuDifficulty difficulty in SudokuDifficulty.values) {
        final List<String> puzzles = puzzlesByDifficulty[difficulty]!;
        final Batch batch = txn.batch();
        int level = 1;
        for (final String puzzle in puzzles) {
          batch.insert('sudoku', <String, Object?>{
            'level': level,
            'difficulty': difficulty.storageValue,
            'sudoku_string': puzzle,
            'daily': null,
          });
          level++;
        }
        await batch.commit(noResult: true);
      }
    });
  }

  String _assetPathForDifficulty(SudokuDifficulty difficulty) {
    return 'assets/sudoku/${difficulty.storageValue}.txt';
  }

  String _toIsoDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

List<String> parseSudokuLines(String content) {
  final List<String> puzzles = <String>[];
  final List<String> lines = content.split(RegExp(r'\r?\n'));
  for (int i = 0; i < lines.length; i++) {
    final String candidate = lines[i].trim();
    if (candidate.isEmpty) {
      continue;
    }
    if (candidate.length != 81) {
      throw FormatException(
        'Sudoku line ${i + 1} must contain exactly 81 characters, got ${candidate.length}.',
      );
    }
    if (!RegExp(r'^[0-9]{81}$').hasMatch(candidate)) {
      throw FormatException(
        'Sudoku line ${i + 1} may only contain digits 0-9.',
      );
    }
    puzzles.add(candidate);
  }
  return puzzles;
}
