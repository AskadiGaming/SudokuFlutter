import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const String _databaseName = 'sudoku.db';
  static const int _databaseVersion = 5;

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final Database opened = await _openDatabase();
    _database = opened;
    return opened;
  }

  Future<Database> _openDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String databasePath = path.join(databasesPath, _databaseName);
    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sudoku (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level INTEGER NOT NULL,
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        sudoku_string TEXT NOT NULL,
        daily TEXT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_sudoku_difficulty_level ON sudoku(difficulty, level)',
    );
    await db.execute(
      'CREATE INDEX idx_sudoku_difficulty ON sudoku(difficulty)',
    );
    await db.execute('CREATE INDEX idx_sudoku_daily ON sudoku(daily)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_sudoku_daily_unique ON sudoku(daily) WHERE daily IS NOT NULL',
    );
    await _createChallengeTables(db);
    await _createCompletedSudokuLogTable(db);
    await _createSudokuReplayTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChallengeTables(db);
    }
    if (oldVersion < 3) {
      await _createCompletedSudokuLogTable(db);
    }
    if (oldVersion < 4) {
      await _ensureCompletedSudokuLogReplayColumn(db);
      await _createSudokuReplayTables(db);
    }
    if (oldVersion < 5) {
      await _ensureCompletedSudokuLogReplayColumn(db);
      await _createSudokuReplayTables(db);
    }
  }

  Future<void> _createChallengeTables(Database db) async {
    await db.execute('''
      CREATE TABLE challenge_puzzle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_date TEXT NOT NULL,
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        sudoku_id INTEGER NOT NULL,
        UNIQUE(challenge_date, difficulty)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_challenge_puzzle_date ON challenge_puzzle(challenge_date)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_challenge_puzzle_date_difficulty ON challenge_puzzle(challenge_date, difficulty)',
    );

    await db.execute('''
      CREATE TABLE challenge_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_date TEXT NOT NULL,
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        sudoku_id INTEGER NOT NULL,
        current_grid TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0 CHECK(is_completed IN (0, 1)),
        started_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT NULL,
        UNIQUE(challenge_date, difficulty)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_challenge_progress_date ON challenge_progress(challenge_date)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_challenge_progress_date_difficulty ON challenge_progress(challenge_date, difficulty)',
    );
  }

  Future<void> _createCompletedSudokuLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS completed_sudoku_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        mode TEXT NOT NULL CHECK(mode IN ('normal', 'daily', 'challenge')),
        started_at TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        challenge_date TEXT NULL,
        source_sudoku_id INTEGER NULL,
        replay_id INTEGER NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completed_sudoku_log_completed_at ON completed_sudoku_log(completed_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completed_sudoku_log_replay_id ON completed_sudoku_log(replay_id)',
    );
  }

  Future<void> _createSudokuReplayTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sudoku_replay (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL CHECK(mode IN ('normal', 'daily', 'challenge')),
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        challenge_date TEXT NULL,
        source_sudoku_id INTEGER NULL,
        puzzle_string TEXT NOT NULL,
        final_grid_string TEXT NOT NULL,
        played_duration_millis INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sudoku_replay_move (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        replay_id INTEGER NOT NULL,
        sequence INTEGER NOT NULL,
        cell_row INTEGER NOT NULL,
        cell_col INTEGER NOT NULL,
        previous_value INTEGER NOT NULL,
        next_value INTEGER NOT NULL,
        elapsed_millis INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sudoku_play_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        replay_id INTEGER NOT NULL,
        session_index INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT NULL,
        active_duration_millis INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sudoku_replay_mode_created_at ON sudoku_replay(mode, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sudoku_replay_move_replay_sequence ON sudoku_replay_move(replay_id, sequence)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sudoku_play_session_replay_session_index ON sudoku_play_session(replay_id, session_index)',
    );
  }

  Future<void> _ensureCompletedSudokuLogReplayColumn(Database db) async {
    final List<Map<String, Object?>> columns = await db.rawQuery(
      "PRAGMA table_info('completed_sudoku_log')",
    );
    final bool hasReplayId = columns.any(
      (Map<String, Object?> column) => column['name'] == 'replay_id',
    );
    if (!hasReplayId) {
      await db.execute(
        'ALTER TABLE completed_sudoku_log ADD COLUMN replay_id INTEGER NULL',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completed_sudoku_log_replay_id ON completed_sudoku_log(replay_id)',
    );
  }
}
