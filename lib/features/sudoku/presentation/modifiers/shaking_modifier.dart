import 'dart:async';
import 'dart:ui';

import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class ShakingModifier extends SudokuModifier {
  static const int durationMinSeconds = 3;
  static const int durationMaxSeconds = 6;

  Timer? _shakingTimer;

  @override
  SudokuModifierType get type => SudokuModifierType.shaking;

  @override
  int durationSeconds(SudokuModifierContext context) {
    return context.randomBetweenInclusive(
      durationMinSeconds,
      durationMaxSeconds,
    );
  }

  @override
  void onStart(SudokuModifierContext context) {
    _shakingTimer?.cancel();
    _shakingTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!context.mounted) {
        return;
      }
      context.safeSetState(() {
        context.gridShakeOffset = Offset(
          context.randomDoubleBetween(-4.0, 4.0),
          context.randomDoubleBetween(-4.0, 4.0),
        );
      });
    });
  }

  @override
  void onStop(SudokuModifierContext context) {
    _shakingTimer?.cancel();
    _shakingTimer = null;
    context.safeSetState(() {
      context.gridShakeOffset = Offset.zero;
    });
  }

  @override
  void dispose() {
    _shakingTimer?.cancel();
  }
}
