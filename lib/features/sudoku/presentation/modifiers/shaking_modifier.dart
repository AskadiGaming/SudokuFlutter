import 'dart:async';
import 'dart:math';
import 'dart:ui';

import '../../domain/sudoku_modifier_config.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class ShakingModifier extends SudokuModifier {
  ShakingModifier({required ShakingModifierConfig config}) : _config = config;

  final ShakingModifierConfig _config;

  Timer? _shakingTimer;

  @override
  SudokuModifierType get type => SudokuModifierType.shaking;

  @override
  int durationSeconds(SudokuModifierContext context) {
    final int minSeconds = max(1, _config.duration.minSeconds);
    final int maxSeconds = max(minSeconds, _config.duration.maxSeconds);
    return context.randomBetweenInclusive(minSeconds, maxSeconds);
  }

  @override
  void onStart(SudokuModifierContext context) {
    _shakingTimer?.cancel();
    final int tickMs = max(1, _config.tickMilliseconds);
    final double minOffset = min(_config.minOffsetPx, _config.maxOffsetPx);
    final double maxOffset = max(_config.minOffsetPx, _config.maxOffsetPx);
    _shakingTimer = Timer.periodic(Duration(milliseconds: tickMs), (_) {
      if (!context.mounted) {
        return;
      }
      context.safeSetState(() {
        context.gridShakeOffset = Offset(
          context.randomDoubleBetween(minOffset, maxOffset),
          context.randomDoubleBetween(minOffset, maxOffset),
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
