import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class TextRotationModifier extends SudokuModifier {
  static const int duration = 6;

  @override
  SudokuModifierType get type => SudokuModifierType.textRotation;

  @override
  int durationSeconds(SudokuModifierContext context) => duration;

  @override
  void onStart(SudokuModifierContext context) {
    context.textRotationDirections.clear();

    final gridData = context.gridData;
    if (gridData != null) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (gridData.currentGrid[row][col] == 0) {
            continue;
          }
          final int index = (row * 9) + col;
          context.textRotationDirections[index] =
              context.random.nextBool() ? 1 : -1;
        }
      }
    }

    context.textRotationController
      ..stop()
      ..duration = const Duration(seconds: duration)
      ..reset()
      ..forward();
  }

  @override
  void onStop(SudokuModifierContext context) {
    context.textRotationController
      ..stop()
      ..reset();
    context.textRotationDirections.clear();
  }
}
