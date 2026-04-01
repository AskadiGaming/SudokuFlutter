class SudokuGridData {
  SudokuGridData({
    required this.initialGrid,
    required this.currentGrid,
    required this.solutionGrid,
    required this.isFixed,
  });

  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<int>> solutionGrid;
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
  final List<List<int>> solutionGrid = _cloneGrid(initialGrid);
  final bool solved = _solveSudoku(solutionGrid);
  if (!solved) {
    throw const FormatException('Sudoku puzzle could not be solved.');
  }

  return SudokuGridData(
    initialGrid: initialGrid,
    currentGrid: currentGrid,
    solutionGrid: solutionGrid,
    isFixed: isFixed,
  );
}

List<List<int>> _cloneGrid(List<List<int>> source) {
  return source.map((List<int> row) => List<int>.from(row)).toList();
}

bool _solveSudoku(List<List<int>> grid) {
  final int emptyCell = _findEmptyCell(grid);
  if (emptyCell == -1) {
    return true;
  }

  final int row = emptyCell ~/ 9;
  final int col = emptyCell % 9;

  for (int candidate = 1; candidate <= 9; candidate++) {
    if (!_isValidCandidate(grid, row, col, candidate)) {
      continue;
    }
    grid[row][col] = candidate;
    if (_solveSudoku(grid)) {
      return true;
    }
    grid[row][col] = 0;
  }

  return false;
}

int _findEmptyCell(List<List<int>> grid) {
  for (int row = 0; row < 9; row++) {
    for (int col = 0; col < 9; col++) {
      if (grid[row][col] == 0) {
        return (row * 9) + col;
      }
    }
  }
  return -1;
}

bool _isValidCandidate(List<List<int>> grid, int row, int col, int candidate) {
  for (int i = 0; i < 9; i++) {
    if (grid[row][i] == candidate || grid[i][col] == candidate) {
      return false;
    }
  }

  final int boxRowStart = (row ~/ 3) * 3;
  final int boxColStart = (col ~/ 3) * 3;
  for (int boxRow = boxRowStart; boxRow < boxRowStart + 3; boxRow++) {
    for (int boxCol = boxColStart; boxCol < boxColStart + 3; boxCol++) {
      if (grid[boxRow][boxCol] == candidate) {
        return false;
      }
    }
  }

  return true;
}
