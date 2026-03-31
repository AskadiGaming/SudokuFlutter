import 'sudoku_modifier.dart';

class SudokuModifierRegistry {
  SudokuModifierRegistry({required List<SudokuModifier> modifiers})
    : _modifiers = List<SudokuModifier>.unmodifiable(modifiers);

  final List<SudokuModifier> _modifiers;

  List<SudokuModifier> get modifiers => _modifiers;
}
