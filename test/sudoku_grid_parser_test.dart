import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_grid_parser.dart';

void main() {
  test('parsePuzzle creates 9x9 grid with fixed markers', () {
    const String puzzle =
        '530070000600195000098000060800060003400803001700020006060000280000419005000080079';

    final SudokuGridData gridData = parsePuzzle(puzzle);

    expect(gridData.initialGrid.length, 9);
    expect(gridData.initialGrid.first.length, 9);
    expect(gridData.currentGrid[0][0], 5);
    expect(gridData.currentGrid[0][2], 0);
    expect(gridData.solutionGrid[0][2], 4);
    expect(gridData.solutionGrid[8][8], 9);
    expect(gridData.isFixed[0][0], isTrue);
    expect(gridData.isFixed[0][2], isFalse);
  });

  test('parsePuzzle throws on invalid length', () {
    expect(() => parsePuzzle('123'), throwsFormatException);
  });

  test('parsePuzzle throws on invalid characters', () {
    final String invalid =
        '53007000060019500009800006080006000340080300170002000606000028000041900500008007A';
    expect(() => parsePuzzle(invalid), throwsFormatException);
  });
}
