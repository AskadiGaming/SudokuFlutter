import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_number_availability.dart';

void main() {
  test('count sudoku digits returns occurrences for values 1 to 9', () {
    final List<List<int>> grid = <List<int>>[
      <int>[1, 1, 1, 0, 0, 0, 0, 0, 0],
      <int>[2, 2, 2, 2, 0, 0, 0, 0, 0],
      <int>[9, 9, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    expect(countSudokuDigits(grid)[1], 3);
    expect(countSudokuDigits(grid)[2], 4);
    expect(countSudokuDigits(grid)[9], 2);
    expect(countSudokuDigits(grid)[5], 0);
  });

  test('fully used sudoku digits returns numbers with nine occurrences', () {
    final List<List<int>> grid = <List<int>>[
      <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
      <int>[2, 2, 2, 2, 2, 2, 2, 2, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    expect(fullyUsedSudokuDigits(grid), <int>{1});
  });

  test('zeros are ignored and digits below nine stay visible', () {
    final List<List<int>> grid = <List<int>>[
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[3, 3, 3, 3, 3, 3, 3, 3, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    expect(fullyUsedSudokuDigits(grid), isEmpty);
  });

  test('remaining digit usages returns 9 minus current occurrences', () {
    final List<List<int>> grid = <List<int>>[
      <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
      <int>[2, 2, 2, 0, 0, 0, 0, 0, 0],
      <int>[3, 3, 3, 3, 3, 3, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    final Map<int, int> remaining = remainingSudokuDigitUsages(grid);

    expect(remaining[1], 0);
    expect(remaining[2], 6);
    expect(remaining[3], 3);
    expect(remaining[4], 9);
  });
}
