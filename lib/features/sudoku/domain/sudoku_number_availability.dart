Set<int> fullyUsedSudokuDigits(List<List<int>> grid) {
  final List<int> counts = List<int>.filled(10, 0);

  for (final List<int> row in grid) {
    for (final int value in row) {
      if (value >= 1 && value <= 9) {
        counts[value] += 1;
      }
    }
  }

  final Set<int> hiddenDigits = <int>{};
  for (int value = 1; value <= 9; value++) {
    if (counts[value] >= 9) {
      hiddenDigits.add(value);
    }
  }
  return hiddenDigits;
}
