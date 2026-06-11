Map<int, int> countSudokuDigits(List<List<int>> grid) {
  final List<int> counts = List<int>.filled(10, 0);

  for (final List<int> row in grid) {
    for (final int value in row) {
      if (value >= 1 && value <= 9) {
        counts[value] += 1;
      }
    }
  }

  return <int, int>{
    for (int value = 1; value <= 9; value++) value: counts[value],
  };
}

Map<int, int> remainingSudokuDigitUsages(List<List<int>> grid) {
  final Map<int, int> counts = countSudokuDigits(grid);
  return <int, int>{
    for (int value = 1; value <= 9; value++)
      value: (9 - (counts[value] ?? 0)).clamp(0, 9),
  };
}

Set<int> fullyUsedSudokuDigits(List<List<int>> grid) {
  final Map<int, int> counts = countSudokuDigits(grid);
  final Set<int> hiddenDigits = <int>{};
  for (int value = 1; value <= 9; value++) {
    if ((counts[value] ?? 0) >= 9) {
      hiddenDigits.add(value);
    }
  }
  return hiddenDigits;
}
