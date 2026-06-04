import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../sudoku/data/datasources/sudoku_local_datasource.dart';
import '../../sudoku/domain/sudoku_difficulty.dart';
import '../domain/challenge_day_entry.dart';
import '../domain/challenge_day_status.dart';
import '../domain/challenge_month_data.dart';
import '../domain/challenge_round_data.dart';
import 'challenge_repository.dart';

class LocalChallengeRepository implements ChallengeRepository {
  LocalChallengeRepository({
    AppDatabase? appDatabase,
    SudokuLocalDataSource? sudokuLocalDataSource,
    SharedPreferences? preferences,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _sudokuLocalDataSource =
           sudokuLocalDataSource ?? SudokuLocalDataSource(),
       _preferences = preferences;

  static const String _lastPlayedMonthKey = 'challenge_last_played_month';

  final AppDatabase _appDatabase;
  final SudokuLocalDataSource _sudokuLocalDataSource;
  SharedPreferences? _preferences;

  @override
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  }) async {
    await _sudokuLocalDataSource.ensureSeeded();
    final Database db = await _appDatabase.database;
    final DateTime normalizedMonth = _firstDayOfMonth(month);
    final DateTime displayStart = _firstDisplayedDay(normalizedMonth);
    final DateTime displayEnd = displayStart.add(const Duration(days: 41));

    final List<Map<String, Object?>> rows = await db.query(
      'challenge_progress',
      columns: <String>['challenge_date', 'is_completed'],
      where: 'difficulty = ? AND challenge_date >= ? AND challenge_date <= ?',
      whereArgs: <Object>[
        difficulty.storageValue,
        _toIsoDate(displayStart),
        _toIsoDate(displayEnd),
      ],
    );

    final Map<String, ChallengeDayStatus> statusesByDate =
        <String, ChallengeDayStatus>{};
    for (final Map<String, Object?> row in rows) {
      statusesByDate[row['challenge_date']! as String] =
          (row['is_completed']! as int) == 1
              ? ChallengeDayStatus.completed
              : ChallengeDayStatus.inProgress;
    }

    final List<ChallengeDayEntry> entries = <ChallengeDayEntry>[];
    for (int offset = 0; offset < 42; offset++) {
      final DateTime day = displayStart.add(Duration(days: offset));
      final String dayKey = _toIsoDate(day);
      entries.add(
        ChallengeDayEntry(
          date: day,
          isInCurrentMonth: day.month == normalizedMonth.month,
          status: statusesByDate[dayKey] ?? ChallengeDayStatus.notStarted,
        ),
      );
    }

    return ChallengeMonthData(month: normalizedMonth, entries: entries);
  }

  @override
  Future<ChallengeRoundData> loadOrCreateRoundData({
    required DateTime date,
    required SudokuDifficulty difficulty,
  }) async {
    await _sudokuLocalDataSource.ensureSeeded();
    final DateTime normalizedDate = _dateOnly(date);
    await saveLastPlayedMonth(normalizedDate);
    final Database db = await _appDatabase.database;

    return db.transaction((Transaction txn) async {
      final _ChallengePuzzle puzzle = await _getOrCreatePuzzle(
        txn: txn,
        date: normalizedDate,
        difficulty: difficulty,
      );
      final String isoDate = _toIsoDate(normalizedDate);

      final List<Map<String, Object?>> progressRows = await txn.query(
        'challenge_progress',
        where: 'challenge_date = ? AND difficulty = ?',
        whereArgs: <Object>[isoDate, difficulty.storageValue],
        limit: 1,
      );

      if (progressRows.isEmpty) {
        final String now = DateTime.now().toIso8601String();
        await txn.insert('challenge_progress', <String, Object?>{
          'challenge_date': isoDate,
          'difficulty': difficulty.storageValue,
          'sudoku_id': puzzle.sudokuId,
          'current_grid': puzzle.puzzleString,
          'is_completed': 0,
          'started_at': now,
          'updated_at': now,
          'completed_at': null,
        });
        return ChallengeRoundData(
          date: normalizedDate,
          difficulty: difficulty,
          sudokuId: puzzle.sudokuId,
          puzzleString: puzzle.puzzleString,
          currentGridString: puzzle.puzzleString,
          isCompleted: false,
        );
      }

      final Map<String, Object?> row = progressRows.first;
      return ChallengeRoundData(
        date: normalizedDate,
        difficulty: difficulty,
        sudokuId: row['sudoku_id']! as int,
        puzzleString: puzzle.puzzleString,
        currentGridString: row['current_grid']! as String,
        isCompleted: (row['is_completed']! as int) == 1,
      );
    });
  }

  @override
  Future<void> saveChallengeProgress({
    required DateTime date,
    required SudokuDifficulty difficulty,
    required int sudokuId,
    required String currentGrid,
    required bool isCompleted,
  }) async {
    final Database db = await _appDatabase.database;
    final String now = DateTime.now().toIso8601String();
    await db.update(
      'challenge_progress',
      <String, Object?>{
        'sudoku_id': sudokuId,
        'current_grid': currentGrid,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': now,
        'completed_at': isCompleted ? now : null,
      },
      where: 'challenge_date = ? AND difficulty = ?',
      whereArgs: <Object>[_toIsoDate(_dateOnly(date)), difficulty.storageValue],
    );
  }

  @override
  Future<DateTime?> loadLastPlayedMonth() async {
    final SharedPreferences preferences = await _getPreferences();
    final String? rawValue = preferences.getString(_lastPlayedMonthKey);
    if (rawValue == null || !RegExp(r'^\d{4}-\d{2}$').hasMatch(rawValue)) {
      return null;
    }
    final List<String> parts = rawValue.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  Future<void> saveLastPlayedMonth(DateTime month) async {
    final SharedPreferences preferences = await _getPreferences();
    final DateTime normalizedMonth = _firstDayOfMonth(month);
    final String year = normalizedMonth.year.toString().padLeft(4, '0');
    final String monthText = normalizedMonth.month.toString().padLeft(2, '0');
    await preferences.setString(_lastPlayedMonthKey, '$year-$monthText');
  }

  Future<_ChallengePuzzle> _getOrCreatePuzzle({
    required Transaction txn,
    required DateTime date,
    required SudokuDifficulty difficulty,
  }) async {
    final String isoDate = _toIsoDate(date);
    final List<Map<String, Object?>> existingRows = await txn.rawQuery(
      '''
      SELECT cp.sudoku_id, s.sudoku_string
      FROM challenge_puzzle cp
      INNER JOIN sudoku s ON s.id = cp.sudoku_id
      WHERE cp.challenge_date = ? AND cp.difficulty = ?
      LIMIT 1
      ''',
      <Object>[isoDate, difficulty.storageValue],
    );
    if (existingRows.isNotEmpty) {
      final Map<String, Object?> row = existingRows.first;
      return _ChallengePuzzle(
        sudokuId: row['sudoku_id']! as int,
        puzzleString: row['sudoku_string']! as String,
      );
    }

    final List<Map<String, Object?>> puzzleRows = await txn.query(
      'sudoku',
      columns: <String>['id', 'sudoku_string'],
      where: 'difficulty = ?',
      whereArgs: <Object>[difficulty.storageValue],
      orderBy: 'RANDOM()',
      limit: 1,
    );
    if (puzzleRows.isEmpty) {
      throw StateError('No puzzle found for difficulty: $difficulty');
    }

    final Map<String, Object?> puzzleRow = puzzleRows.first;
    final int sudokuId = puzzleRow['id']! as int;
    final String puzzleString = puzzleRow['sudoku_string']! as String;

    await txn.insert('challenge_puzzle', <String, Object?>{
      'challenge_date': isoDate,
      'difficulty': difficulty.storageValue,
      'sudoku_id': sudokuId,
    });

    return _ChallengePuzzle(sudokuId: sudokuId, puzzleString: puzzleString);
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  DateTime _firstDisplayedDay(DateTime month) {
    return month.subtract(Duration(days: month.weekday - DateTime.monday));
  }

  DateTime _firstDayOfMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _toIsoDate(DateTime date) {
    final DateTime normalized = _dateOnly(date);
    final String year = normalized.year.toString().padLeft(4, '0');
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _ChallengePuzzle {
  const _ChallengePuzzle({required this.sudokuId, required this.puzzleString});

  final int sudokuId;
  final String puzzleString;
}
