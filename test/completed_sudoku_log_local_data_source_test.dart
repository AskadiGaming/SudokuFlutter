import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku_history/data/completed_sudoku_log_local_data_source.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_entry.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_mode.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('maps entries and returns them sorted by completed_at desc', () async {
    final Database db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE completed_sudoku_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            difficulty TEXT NOT NULL,
            mode TEXT NOT NULL,
            started_at TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            challenge_date TEXT NULL,
            source_sudoku_id INTEGER NULL,
            replay_id INTEGER NULL
          )
        ''');
      },
    );

    final CompletedSudokuLogLocalDataSource dataSource =
        CompletedSudokuLogLocalDataSource(databaseProvider: () async => db);

    await dataSource.addCompletedSudoku(
      CompletedSudokuEntry(
        difficulty: SudokuDifficulty.easy,
        mode: CompletedSudokuMode.challenge,
        startedAt: DateTime(2026, 6, 4, 8, 0),
        completedAt: DateTime(2026, 6, 4, 8, 10),
        durationSeconds: 600,
        challengeDate: DateTime(2026, 6, 4),
        sourceSudokuId: 77,
        replayId: 11,
      ),
    );
    await dataSource.addCompletedSudoku(
      CompletedSudokuEntry(
        difficulty: SudokuDifficulty.hard,
        mode: CompletedSudokuMode.normal,
        startedAt: DateTime(2026, 6, 4, 9, 0),
        completedAt: DateTime(2026, 6, 4, 9, 5),
        durationSeconds: 300,
      ),
    );

    final List<CompletedSudokuEntry> entries =
        await dataSource.getCompletedSudokus();

    expect(entries, hasLength(2));
    expect(entries.first.difficulty, SudokuDifficulty.hard);
    expect(entries.first.mode, CompletedSudokuMode.normal);
    expect(entries.first.durationSeconds, 300);
    expect(entries.last.mode, CompletedSudokuMode.challenge);
    expect(entries.last.challengeDate, DateTime(2026, 6, 4));
    expect(entries.last.sourceSudokuId, 77);
    expect(entries.last.replayId, 11);

    await db.close();
  });
}
