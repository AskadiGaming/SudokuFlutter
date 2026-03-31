import 'package:flutter/animation.dart';

import '../../domain/sudoku_matrix_rotation.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class Rotation90Modifier extends SudokuModifier {
  static const int duration = 4;

  bool _isApplyingCommit = false;
  bool _isRunning = false;
  SudokuModifierContext? _activeContext;

  @override
  SudokuModifierType get type => SudokuModifierType.rotation90;

  @override
  bool get controlsOwnDeactivation => true;

  @override
  int durationSeconds(SudokuModifierContext context) => duration;

  @override
  void onStart(SudokuModifierContext context) {
    _isApplyingCommit = false;
    _isRunning = true;
    _activeContext = context;
    context.rotation90Controller
      ..removeStatusListener(_onStatusChanged)
      ..addStatusListener(_onStatusChanged)
      ..stop()
      ..duration = const Duration(seconds: duration)
      ..reset()
      ..forward();
  }

  @override
  void onStop(SudokuModifierContext context) {
    _isApplyingCommit = false;
    _isRunning = false;
    _activeContext = null;
    context.rotation90Controller
      ..removeStatusListener(_onStatusChanged)
      ..stop()
      ..reset();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (!_isRunning ||
        status != AnimationStatus.completed ||
        _isApplyingCommit) {
      return;
    }
    final SudokuModifierContext? context = _activeContext;
    if (context == null || !context.mounted) {
      return;
    }

    final gridData = context.gridData;
    if (gridData == null) {
      context.deactivateCurrentModifier();
      return;
    }

    _isApplyingCommit = true;
    context.safeSetState(() {
      final rotatedGrid = rotateMatrixClockwise90<int>(gridData.currentGrid);
      final rotatedFixed = rotateMatrixClockwise90<bool>(gridData.isFixed);
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          gridData.currentGrid[row][col] = rotatedGrid[row][col];
          gridData.isFixed[row][col] = rotatedFixed[row][col];
        }
      }
      context.quarterTurns = (context.quarterTurns + 1) % 4;
    });
    _isApplyingCommit = false;
    context.deactivateCurrentModifier();
  }
}
