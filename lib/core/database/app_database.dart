import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const String _databaseName = 'sudoku.db';
  static const int _databaseVersion = 3;

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChallengeTables(db);
    }
    if (oldVersion < 3) {
      await _createCompletedSudokuLogTable(db);
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
      CREATE TABLE completed_sudoku_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard', 'extreme')),
        mode TEXT NOT NULL CHECK(mode IN ('normal', 'daily', 'challenge')),
        started_at TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        challenge_date TEXT NULL,
        source_sudoku_id INTEGER NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_completed_sudoku_log_completed_at ON completed_sudoku_log(completed_at DESC)',
    );
  }
}
