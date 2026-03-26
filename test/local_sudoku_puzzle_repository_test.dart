import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/local_sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';

void main() {
  test('loads one valid puzzle per difficulty', () async {
    final LocalSudokuPuzzleRepository repository =
        LocalSudokuPuzzleRepository();

    final String easy = await repository.loadPuzzle(SudokuDifficulty.easy);
    final String medium = await repository.loadPuzzle(SudokuDifficulty.medium);
    final String hard = await repository.loadPuzzle(SudokuDifficulty.hard);
    final String extreme = await repository.loadPuzzle(
      SudokuDifficulty.extreme,
    );

    expect(easy.length, 81);
    expect(medium.length, 81);
    expect(hard.length, 81);
    expect(extreme.length, 81);

    expect(<String>{easy, medium, hard, extreme}.length, 4);
  });
}
