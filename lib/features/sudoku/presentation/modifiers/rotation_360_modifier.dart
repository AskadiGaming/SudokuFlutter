import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class Rotation360Modifier extends SudokuModifier {
  static const int duration = 10;

  @override
  SudokuModifierType get type => SudokuModifierType.rotation360;

  @override
  int durationSeconds(SudokuModifierContext context) => duration;

  @override
  void onStart(SudokuModifierContext context) {
    context.rotationController
      ..stop()
      ..duration = const Duration(seconds: duration)
      ..reset()
      ..forward();
  }

  @override
  void onStop(SudokuModifierContext context) {
    context.rotationController
      ..stop()
      ..reset();
  }
}
