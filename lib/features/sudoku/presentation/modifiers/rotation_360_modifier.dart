import 'dart:math';

import '../../domain/sudoku_modifier_config.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class Rotation360Modifier extends SudokuModifier {
  Rotation360Modifier({required Rotation360ModifierConfig config})
    : _config = config;

  final Rotation360ModifierConfig _config;

  @override
  SudokuModifierType get type => SudokuModifierType.rotation360;

  int get _durationSeconds => max(1, _config.duration);

  @override
  int durationSeconds(SudokuModifierContext context) => _durationSeconds;

  @override
  void onStart(SudokuModifierContext context) {
    final int duration = _durationSeconds;
    context.rotationController
      ..stop()
      ..duration = Duration(seconds: duration)
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
