const List<double> sudokuReplaySpeeds = <double>[1, 2, 4, 8, 16, 32];

double nextSudokuReplaySpeed(double current) {
  final int currentIndex = sudokuReplaySpeeds.indexOf(current);
  if (currentIndex == -1 || currentIndex == sudokuReplaySpeeds.length - 1) {
    return sudokuReplaySpeeds.first;
  }
  return sudokuReplaySpeeds[currentIndex + 1];
}
