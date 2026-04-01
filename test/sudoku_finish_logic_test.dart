import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_finish_logic.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_grid_parser.dart';

void main() {
  group('buildSpiralOrder9x9', () {
    test('starts at top-left and covers all cells exactly once', () {
      final List<int> order = buildSpiralOrder9x9();

      expect(order.length, 81);
      expect(order.first, 0);
      expect(order.toSet().length, 81);
      expect(order, everyElement(inInclusiveRange(0, 80)));
    });
  });

  group('isGridSolved', () {
    test('returns true when current grid equals solution grid and is full', () {
      final SudokuGridData gridData = _buildGridData(
        currentGrid: _fullGrid(seed: 1),
        solutionGrid: _fullGrid(seed: 1),
      );

      expect(isGridSolved(gridData), isTrue);
    });

    test('returns false when one value differs from solution', () {
      final List<List<int>> current = _fullGrid(seed: 1);
      final List<List<int>> solution = _fullGrid(seed: 1);
      current[2][7] = 9;
      solution[2][7] = 8;

      final SudokuGridData gridData = _buildGridData(
        currentGrid: current,
        solutionGrid: solution,
      );

      expect(isGridSolved(gridData), isFalse);
    });

    test('returns false when grid still has empty cells', () {
      final List<List<int>> current = _fullGrid(seed: 1);
      current[8][8] = 0;

      final SudokuGridData gridData = _buildGridData(
        currentGrid: current,
        solutionGrid: _fullGrid(seed: 1),
      );

      expect(isGridSolved(gridData), isFalse);
    });
  });
}

SudokuGridData _buildGridData({
  required List<List<int>> currentGrid,
  required List<List<int>> solutionGrid,
}) {
  return SudokuGridData(
    initialGrid: _fullGrid(seed: 2),
    currentGrid: currentGrid,
    solutionGrid: solutionGrid,
    isFixed: List<List<bool>>.generate(9, (_) => List<bool>.filled(9, false)),
  );
}

List<List<int>> _fullGrid({required int seed}) {
  return List<List<int>>.generate(9, (int row) {
    return List<int>.generate(9, (int col) => ((row + col + seed) % 9) + 1);
  });
}
