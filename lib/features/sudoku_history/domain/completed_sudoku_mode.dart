enum CompletedSudokuMode { normal, daily, challenge }

extension CompletedSudokuModeStorageMapper on CompletedSudokuMode {
  String get storageValue {
    switch (this) {
      case CompletedSudokuMode.normal:
        return 'normal';
      case CompletedSudokuMode.daily:
        return 'daily';
      case CompletedSudokuMode.challenge:
        return 'challenge';
    }
  }

  static CompletedSudokuMode fromStorageValue(String value) {
    switch (value) {
      case 'normal':
        return CompletedSudokuMode.normal;
      case 'daily':
        return CompletedSudokuMode.daily;
      case 'challenge':
        return CompletedSudokuMode.challenge;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unknown completed sudoku mode storage value.',
        );
    }
  }
}
