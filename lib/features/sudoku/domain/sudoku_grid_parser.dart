class SudokuGridData {
  SudokuGridData({
    required this.initialGrid,
    required this.currentGrid,
    required this.isFixed,
  });

  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<bool>> isFixed;
}

SudokuGridData parsePuzzle(String puzzle) {
  if (puzzle.length != 81) {
    throw FormatException(
      'Sudoku puzzle must contain exactly 81 characters, got ${puzzle.length}.',
    );
  }

  if (!RegExp(r'^[0-9]{81}$').hasMatch(puzzle)) {
    throw const FormatException('Sudoku puzzle may only contain digits 0-9.');
  }

  final List<List<int>> initialGrid = List<List<int>>.generate(
    9,
    (int row) => List<int>.filled(9, 0),
  );
  final List<List<bool>> isFixed = List<List<bool>>.generate(
    9,
    (int row) => List<bool>.filled(9, false),
  );

  for (int index = 0; index < puzzle.length; index++) {
    final int row = index ~/ 9;
    final int col = index % 9;
    final int value = int.parse(puzzle[index]);
    initialGrid[row][col] = value;
    isFixed[row][col] = value != 0;
  }

  final List<List<int>> currentGrid =
      initialGrid.map((List<int> row) => List<int>.from(row)).toList();

  return SudokuGridData(
    initialGrid: initialGrid,
    currentGrid: currentGrid,
    isFixed: isFixed,
  );
}
