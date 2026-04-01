import 'dart:math';

import '../../domain/sudoku_modifier_config.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class TextRotationModifier extends SudokuModifier {
  TextRotationModifier({required TextRotationModifierConfig config})
    : _config = config;

  final TextRotationModifierConfig _config;

  @override
  SudokuModifierType get type => SudokuModifierType.textRotation;

  int get _durationSeconds => max(1, _config.duration);

  @override
  int durationSeconds(SudokuModifierContext context) => _durationSeconds;

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

    final int duration = _durationSeconds;
    context.textRotationController
      ..stop()
      ..duration = Duration(seconds: duration)
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
