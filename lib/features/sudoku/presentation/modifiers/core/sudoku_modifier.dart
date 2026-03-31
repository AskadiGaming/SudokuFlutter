import '../../../domain/sudoku_modifier_type.dart';
import 'sudoku_modifier_context.dart';

abstract class SudokuModifier {
  const SudokuModifier();

  SudokuModifierType get type;

  bool get controlsOwnDeactivation => false;

  int durationSeconds(SudokuModifierContext context);

  void onStart(SudokuModifierContext context);

  void onStop(SudokuModifierContext context);

  void dispose() {}
}
