import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_number_availability.dart';

void main() {
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
}
