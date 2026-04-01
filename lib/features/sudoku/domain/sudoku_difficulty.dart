enum SudokuDifficulty { easy, medium, hard, extreme }

extension SudokuDifficultyStorageMapper on SudokuDifficulty {
  String get storageValue {
    switch (this) {
      case SudokuDifficulty.easy:
        return 'easy';
      case SudokuDifficulty.medium:
        return 'medium';
      case SudokuDifficulty.hard:
        return 'hard';
      case SudokuDifficulty.extreme:
        return 'extreme';
    }
  }

  static SudokuDifficulty fromStorageValue(String value) {
    switch (value) {
      case 'easy':
        return SudokuDifficulty.easy;
      case 'medium':
        return SudokuDifficulty.medium;
      case 'hard':
        return SudokuDifficulty.hard;
      case 'extreme':
        return SudokuDifficulty.extreme;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unknown Sudoku difficulty storage value.',
        );
    }
  }
}
