import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_matrix_rotation.dart';

void main() {
  List<List<int>> sampleMatrix() {
    int value = 1;
    return List<List<int>>.generate(9, (_) {
      return List<int>.generate(9, (_) => value++);
    });
  }

  test('rotateMatrixClockwise90 rotates matrix clockwise once', () {
    final List<List<int>> source = sampleMatrix();

    final List<List<int>> rotated = rotateMatrixClockwise90<int>(source);

    expect(rotated[0][0], 73);
    expect(rotated[0][8], 1);
    expect(rotated[8][0], 81);
    expect(rotated[8][8], 9);
  });

  test('rotateMatrixClockwise90 is stable over repeated rotations', () {
    final List<List<int>> source = sampleMatrix();

    final List<List<int>> once = rotateMatrixClockwise90<int>(source);
    final List<List<int>> twice = rotateMatrixClockwise90<int>(once);
    final List<List<int>> thrice = rotateMatrixClockwise90<int>(twice);
    final List<List<int>> fourTimes = rotateMatrixClockwise90<int>(thrice);

    expect(twice[0][0], 81);
    expect(thrice[0][0], 9);
    expect(fourTimes, source);
  });
}
