import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku_replay/application/sudoku_replay_speed.dart';

void main() {
  test('speed levels rotate in the required order', () {
    double speed = sudokuReplaySpeeds.first;

    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 2);
    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 4);
    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 8);
    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 16);
    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 32);
    speed = nextSudokuReplaySpeed(speed);
    expect(speed, 1);
  });
}
