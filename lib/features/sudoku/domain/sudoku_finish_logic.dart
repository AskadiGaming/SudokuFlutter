import 'sudoku_grid_parser.dart';

List<int> buildSpiralOrder9x9() {
  final List<int> order = <int>[];
  int top = 0;
  int bottom = 8;
  int left = 0;
  int right = 8;

  while (top <= bottom && left <= right) {
    for (int col = left; col <= right; col++) {
      order.add((top * 9) + col);
    }
    top++;

    for (int row = top; row <= bottom; row++) {
      order.add((row * 9) + right);
    }
    right--;

    if (top <= bottom) {
      for (int col = right; col >= left; col--) {
        order.add((bottom * 9) + col);
      }
      bottom--;
    }

    if (left <= right) {
      for (int row = bottom; row >= top; row--) {
        order.add((row * 9) + left);
      }
      left++;
    }
  }

  return order;
}

bool isGridSolved(SudokuGridData gridData) {
  for (int row = 0; row < 9; row++) {
    for (int col = 0; col < 9; col++) {
      final int value = gridData.currentGrid[row][col];
      if (value == 0 || value != gridData.solutionGrid[row][col]) {
        return false;
      }
    }
  }
  return true;
}
