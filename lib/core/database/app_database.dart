import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const String _databaseName = 'sudoku.db';
  static const int _databaseVersion = 1;

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
