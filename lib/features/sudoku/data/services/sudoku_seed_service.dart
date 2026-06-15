import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/sudoku_difficulty.dart';
import '../models/startup_progress.dart';
import 'sudoku_seed_parser.dart';

class SudokuSeedService {
  SudokuSeedService({
    AppDatabase? appDatabase,
    Future<Database> Function()? databaseProvider,
    AssetBundle? assetBundle,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _databaseProvider = databaseProvider,
       _assetBundle = assetBundle ?? rootBundle;

  static final SudokuSeedService instance = SudokuSeedService();

  final AppDatabase _appDatabase;
  final Future<Database> Function()? _databaseProvider;
  final AssetBundle _assetBundle;
  final ValueNotifier<SudokuSeedProgress> _progressNotifier =
      ValueNotifier<SudokuSeedProgress>(const SudokuSeedProgress.idle());

  Future<bool>? _seedFuture;

  ValueListenable<SudokuSeedProgress> get progressListenable =>
      _progressNotifier;

  Future<bool> ensureSeeded() async {
    final Future<bool>? existingFuture = _seedFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final Future<bool> seedFuture = _seedIfNeeded();
    _seedFuture = seedFuture;
    try {
      return await seedFuture;
    } catch (_) {
      _seedFuture = null;
      rethrow;
    }
  }

  Future<bool> _seedIfNeeded() async {
    final Database db = await _openDatabase();
    _publish(
      progress: 0.05,
      message: 'Bereite Datenbank vor',
      showSplash: false,
    );

    final int existingCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sudoku'),
        ) ??
        0;
    if (existingCount > 0) {
      _publish(progress: 1, message: 'App bereit', showSplash: false);
      return false;
    }

    _publish(
      progress: 0.10,
      message: 'Initialisierung wird vorbereitet',
      showSplash: true,
    );

    await db.transaction((Transaction txn) async {
      for (int index = 0; index < SudokuDifficulty.values.length; index++) {
        final SudokuDifficulty difficulty = SudokuDifficulty.values[index];
        final _DifficultyProgressState progressState = _progressStateForIndex(
          index,
        );

        _publish(
          progress: progressState.loadProgress,
          message: 'Lade ${_difficultyLabel(difficulty)} Sudokus',
          showSplash: true,
        );
        final String fileContent = await _assetBundle.loadString(
          _assetPathForDifficulty(difficulty),
        );
        final List<String> puzzles = parseSudokuLines(fileContent);

        _publish(
          progress: progressState.importProgress,
          message: 'Importiere ${_difficultyLabel(difficulty)} Sudokus',
          showSplash: true,
        );
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

    _publish(
      progress: 0.95,
      message: 'Schliesse Initialisierung ab',
      showSplash: true,
    );
    _publish(progress: 1, message: 'App bereit', showSplash: true);
    return true;
  }

  Future<Database> _openDatabase() async {
    final Future<Database> Function()? databaseProvider = _databaseProvider;
    if (databaseProvider != null) {
      return databaseProvider();
    }
    return _appDatabase.database;
  }

  _DifficultyProgressState _progressStateForIndex(int index) {
    const List<_DifficultyProgressState> states = <_DifficultyProgressState>[
      _DifficultyProgressState(loadProgress: 0.20, importProgress: 0.30),
      _DifficultyProgressState(loadProgress: 0.40, importProgress: 0.50),
      _DifficultyProgressState(loadProgress: 0.60, importProgress: 0.70),
      _DifficultyProgressState(loadProgress: 0.80, importProgress: 0.90),
    ];
    return states[index];
  }

  void _publish({
    required double progress,
    required String message,
    required bool showSplash,
  }) {
    _progressNotifier.value = SudokuSeedProgress(
      progress: progress,
      message: message,
      showSplash: showSplash,
    );
  }

  String _assetPathForDifficulty(SudokuDifficulty difficulty) {
    return 'assets/sudoku/${difficulty.storageValue}.txt';
  }

  String _difficultyLabel(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return 'leichte';
      case SudokuDifficulty.medium:
        return 'mittlere';
      case SudokuDifficulty.hard:
        return 'schwere';
      case SudokuDifficulty.extreme:
        return 'extreme';
    }
  }
}

class _DifficultyProgressState {
  const _DifficultyProgressState({
    required this.loadProgress,
    required this.importProgress,
  });

  final double loadProgress;
  final double importProgress;
}
