import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku_history/domain/completed_sudoku_mode.dart';
import '../domain/sudoku_play_session.dart';
import '../domain/sudoku_replay.dart';
import '../domain/sudoku_replay_details.dart';
import '../domain/sudoku_replay_draft.dart';
import '../domain/sudoku_replay_move.dart';
import '../domain/sudoku_replay_round_key.dart';

class SudokuReplayLocalDataSource {
  SudokuReplayLocalDataSource({
    AppDatabase? appDatabase,
    Future<Database> Function()? databaseProvider,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _databaseProvider = databaseProvider;

  final AppDatabase _appDatabase;
  final Future<Database> Function()? _databaseProvider;

  Future<SudokuReplay> createReplay(SudokuReplayDraft draft) async {
    final Database db = await _database;
    final String timestamp = draft.createdAt.toIso8601String();
    final int id = await db.insert('sudoku_replay', <String, Object?>{
      'mode': draft.mode.storageValue,
      'difficulty': draft.difficulty.storageValue,
      'challenge_date': _toIsoDate(draft.challengeDate),
      'source_sudoku_id': draft.sourceSudokuId,
      'puzzle_string': draft.puzzleString,
      'final_grid_string': draft.puzzleString,
      'played_duration_millis': 0,
      'created_at': timestamp,
      'updated_at': timestamp,
      'completed_at': null,
    });
    final Map<String, Object?> row = (await db.query(
      'sudoku_replay',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    )).single;
    return _replayFromRow(row);
  }

  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'sudoku_replay',
      where:
          'mode = ? AND difficulty = ? AND completed_at IS NULL AND challenge_date IS ? AND source_sudoku_id IS ?',
      whereArgs: <Object?>[
        key.mode.storageValue,
        key.difficulty.storageValue,
        _toIsoDate(key.challengeDate),
        key.sourceSudokuId,
      ],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _replayFromRow(rows.single);
  }

  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  }) async {
    final Database db = await _database;
    return db.insert('sudoku_play_session', <String, Object?>{
      'replay_id': replayId,
      'session_index': sessionIndex,
      'started_at': startedAt.toIso8601String(),
      'ended_at': null,
      'active_duration_millis': 0,
    });
  }

  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  }) async {
    final Database db = await _database;
    await db.update(
      'sudoku_play_session',
      <String, Object?>{
        'ended_at': endedAt.toIso8601String(),
        'active_duration_millis': activeDurationMillis,
      },
      where: 'id = ?',
      whereArgs: <Object>[sessionId],
    );
  }

  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  }) async {
    final Database db = await _database;
    await db.insert('sudoku_replay_move', <String, Object?>{
      'replay_id': replayId,
      'sequence': sequence,
      'cell_row': cellRow,
      'cell_col': cellCol,
      'previous_value': previousValue,
      'next_value': nextValue,
      'elapsed_millis': elapsedMillis,
    });
    await db.update(
      'sudoku_replay',
      <String, Object?>{'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: <Object>[replayId],
    );
  }

  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  }) async {
    final Database db = await _database;
    final String completedAtValue = completedAt.toIso8601String();
    await db.update(
      'sudoku_replay',
      <String, Object?>{
        'final_grid_string': finalGridString,
        'played_duration_millis': playedDurationMillis,
        'updated_at': completedAtValue,
        'completed_at': completedAtValue,
      },
      where: 'id = ?',
      whereArgs: <Object>[replayId],
    );
  }

  Future<SudokuReplayDetails?> getReplayDetails(int replayId) async {
    final Database db = await _database;
    final List<Map<String, Object?>> replayRows = await db.query(
      'sudoku_replay',
      where: 'id = ?',
      whereArgs: <Object>[replayId],
      limit: 1,
    );
    if (replayRows.isEmpty) {
      return null;
    }
    final List<Map<String, Object?>> moveRows = await db.query(
      'sudoku_replay_move',
      where: 'replay_id = ?',
      whereArgs: <Object>[replayId],
      orderBy: 'sequence ASC',
    );
    final List<Map<String, Object?>> sessionRows = await db.query(
      'sudoku_play_session',
      where: 'replay_id = ?',
      whereArgs: <Object>[replayId],
      orderBy: 'session_index ASC',
    );
    return SudokuReplayDetails(
      replay: _replayFromRow(replayRows.single),
      moves: moveRows.map(_moveFromRow).toList(),
      sessions: sessionRows.map(_sessionFromRow).toList(),
    );
  }

  Future<Database> get _database async {
    final Future<Database> Function()? databaseProvider = _databaseProvider;
    if (databaseProvider != null) {
      return databaseProvider();
    }
    return _appDatabase.database;
  }

  SudokuReplay _replayFromRow(Map<String, Object?> row) {
    return SudokuReplay(
      id: row['id']! as int,
      mode: CompletedSudokuModeStorageMapper.fromStorageValue(
        row['mode']! as String,
      ),
      difficulty: SudokuDifficultyStorageMapper.fromStorageValue(
        row['difficulty']! as String,
      ),
      challengeDate: _parseIsoDate(row['challenge_date'] as String?),
      sourceSudokuId: row['source_sudoku_id'] as int?,
      puzzleString: row['puzzle_string']! as String,
      finalGridString: row['final_grid_string']! as String,
      playedDurationMillis: row['played_duration_millis']! as int,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      completedAt:
          row['completed_at'] == null
              ? null
              : DateTime.parse(row['completed_at']! as String),
    );
  }

  SudokuReplayMove _moveFromRow(Map<String, Object?> row) {
    return SudokuReplayMove(
      id: row['id']! as int,
      replayId: row['replay_id']! as int,
      sequence: row['sequence']! as int,
      cellRow: row['cell_row']! as int,
      cellCol: row['cell_col']! as int,
      previousValue: row['previous_value']! as int,
      nextValue: row['next_value']! as int,
      elapsedMillis: row['elapsed_millis']! as int,
    );
  }

  SudokuPlaySession _sessionFromRow(Map<String, Object?> row) {
    return SudokuPlaySession(
      id: row['id']! as int,
      replayId: row['replay_id']! as int,
      sessionIndex: row['session_index']! as int,
      startedAt: DateTime.parse(row['started_at']! as String),
      endedAt:
          row['ended_at'] == null
              ? null
              : DateTime.parse(row['ended_at']! as String),
      activeDurationMillis: row['active_duration_millis']! as int,
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
