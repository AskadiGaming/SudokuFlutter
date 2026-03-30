List<List<T>> rotateMatrixClockwise90<T>(List<List<T>> source) {
  const int size = 9;
  return List<List<T>>.generate(size, (int newRow) {
    return List<T>.generate(size, (int newCol) {
      return source[8 - newCol][newRow];
    });
  });
}
