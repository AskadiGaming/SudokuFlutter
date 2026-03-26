import '../domain/sudoku_difficulty.dart';
import 'sudoku_puzzle_repository.dart';

class LocalSudokuPuzzleRepository implements SudokuPuzzleRepository {
  static const Map<SudokuDifficulty, String>
  _puzzles = <SudokuDifficulty, String>{
    SudokuDifficulty.easy:
        '530070000600195000098000060800060003400803001700020006060000280000419005000080079',
    SudokuDifficulty.medium:
        '000260701680070090190004500820100040004602900050003028009300074040050036703018000',
    SudokuDifficulty.hard:
        '005300000800000020070010500400005300010070006003200080060500009004000030000009700',
    SudokuDifficulty.extreme:
        '000000907000420180000705026100904000050000040000507009920108000034059000507000000',
  };

  @override
  Future<String> loadPuzzle(SudokuDifficulty difficulty) async {
    final String? puzzle = _puzzles[difficulty];
    if (puzzle == null) {
      throw StateError('No puzzle found for difficulty: $difficulty');
    }
    _validatePuzzleString(puzzle);
    return puzzle;
  }

  void _validatePuzzleString(String puzzle) {
    if (puzzle.length != 81) {
      throw FormatException(
        'Sudoku puzzle must contain exactly 81 characters, got ${puzzle.length}.',
      );
    }
    if (!RegExp(r'^[0-9]{81}$').hasMatch(puzzle)) {
      throw const FormatException('Sudoku puzzle may only contain digits 0-9.');
    }
  }
}
