import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';

void main() {
  test('maps difficulty enum to storage value', () {
    expect(SudokuDifficulty.easy.storageValue, 'easy');
    expect(SudokuDifficulty.medium.storageValue, 'medium');
    expect(SudokuDifficulty.hard.storageValue, 'hard');
    expect(SudokuDifficulty.extreme.storageValue, 'extreme');
  });

  test('maps storage value to difficulty enum', () {
    expect(
      SudokuDifficultyStorageMapper.fromStorageValue('easy'),
      SudokuDifficulty.easy,
    );
    expect(
      SudokuDifficultyStorageMapper.fromStorageValue('medium'),
      SudokuDifficulty.medium,
    );
    expect(
      SudokuDifficultyStorageMapper.fromStorageValue('hard'),
      SudokuDifficulty.hard,
    );
    expect(
      SudokuDifficultyStorageMapper.fromStorageValue('extreme'),
      SudokuDifficulty.extreme,
    );
  });

  test('throws for unknown storage values', () {
    expect(
      () => SudokuDifficultyStorageMapper.fromStorageValue('unknown'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
