import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/models/startup_progress.dart';
import 'package:hello_world_app/features/sudoku/data/services/sudoku_seed_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('seeds all difficulties once and reports visible progress', () async {
    final Database db = await _openSeedDatabase();
    final _MutableAssetBundle assetBundle = _MutableAssetBundle(_validAssets());
    final SudokuSeedService service = SudokuSeedService(
      databaseProvider: () async => db,
      assetBundle: assetBundle,
    );
    final List<SudokuSeedProgress> progressEvents = <SudokuSeedProgress>[];
    service.progressListenable.addListener(() {
      progressEvents.add(service.progressListenable.value);
    });

    final bool didSeed = await service.ensureSeeded();

    expect(didSeed, isTrue);
    expect(
      progressEvents.any((SudokuSeedProgress event) => event.showSplash),
      isTrue,
    );
    expect(progressEvents.last.progress, 1);

    final int puzzleCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sudoku'),
        ) ??
        0;
    expect(puzzleCount, 8);

    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT difficulty, COUNT(*) AS amount FROM sudoku GROUP BY difficulty',
    );
    expect(rows, hasLength(4));
    for (final Map<String, Object?> row in rows) {
      expect(row['amount'], 2);
    }

    await db.close();
  });

  test('skips seeding when sudoku table already contains data', () async {
    final Database db = await _openSeedDatabase();
    await db.insert('sudoku', <String, Object?>{
      'level': 1,
      'difficulty': 'easy',
      'sudoku_string': _puzzle(1),
      'daily': null,
    });

    final SudokuSeedService service = SudokuSeedService(
      databaseProvider: () async => db,
      assetBundle: _MutableAssetBundle(_validAssets()),
    );

    final bool didSeed = await service.ensureSeeded();

    expect(didSeed, isFalse);
    final int puzzleCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sudoku'),
        ) ??
        0;
    expect(puzzleCount, 1);

    await db.close();
  });

  test('allows retry after parsing failure', () async {
    final Database db = await _openSeedDatabase();
    final _MutableAssetBundle assetBundle = _MutableAssetBundle(_validAssets())
      ..assets['assets/sudoku/easy.txt'] = 'invalid';
    final SudokuSeedService service = SudokuSeedService(
      databaseProvider: () async => db,
      assetBundle: assetBundle,
    );

    await expectLater(service.ensureSeeded(), throwsFormatException);

    assetBundle.assets['assets/sudoku/easy.txt'] =
        '${_puzzle(1)}\n${_puzzle(2)}\n';

    final bool didSeed = await service.ensureSeeded();

    expect(didSeed, isTrue);
    final int puzzleCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sudoku'),
        ) ??
        0;
    expect(puzzleCount, 8);

    await db.close();
  });
}

Future<Database> _openSeedDatabase() {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE sudoku (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          level INTEGER NOT NULL,
          difficulty TEXT NOT NULL,
          sudoku_string TEXT NOT NULL,
          daily TEXT NULL
        )
      ''');
    },
  );
}

Map<String, String> _validAssets() {
  return <String, String>{
    'assets/sudoku/easy.txt': '${_puzzle(1)}\n${_puzzle(2)}\n',
    'assets/sudoku/medium.txt': '${_puzzle(3)}\n${_puzzle(4)}\n',
    'assets/sudoku/hard.txt': '${_puzzle(5)}\n${_puzzle(6)}\n',
    'assets/sudoku/extreme.txt': '${_puzzle(7)}\n${_puzzle(8)}\n',
  };
}

String _puzzle(int digit) => List<String>.filled(81, '$digit').join();

class _MutableAssetBundle extends CachingAssetBundle {
  _MutableAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final String? value = assets[key];
    if (value == null) {
      throw FlutterError('Missing asset: $key');
    }
    final Uint8List bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final String? value = assets[key];
    if (value == null) {
      throw FlutterError('Missing asset: $key');
    }
    return value;
  }
}
