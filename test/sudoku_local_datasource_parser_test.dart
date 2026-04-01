import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/datasources/sudoku_local_datasource.dart';

void main() {
  test('parseSudokuLines ignores empty lines and returns valid puzzles', () {
    const String content =
        '\n'
        '530070000600195000098000060800060003400803001700020006060000280000419005000080079\n'
        '\n'
        '000260701680070090190004500820100040004602900050003028009300074040050036703018000\n';

    final List<String> puzzles = parseSudokuLines(content);

    expect(puzzles.length, 2);
    expect(puzzles.every((String puzzle) => puzzle.length == 81), isTrue);
  });

  test('parseSudokuLines throws on invalid line length', () {
    expect(() => parseSudokuLines('123\n'), throwsA(isA<FormatException>()));
  });

  test('parseSudokuLines throws on invalid characters', () {
    const String invalid =
        '53007000060019500009800006080006000340080300170002000606000028000041900500008007A';

    expect(() => parseSudokuLines(invalid), throwsA(isA<FormatException>()));
  });
}
