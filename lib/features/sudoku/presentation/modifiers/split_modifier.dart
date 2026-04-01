import 'dart:math';

import 'package:flutter/animation.dart';

import '../../domain/sudoku_modifier_config.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';

class SplitModifier extends SudokuModifier {
  SplitModifier({required SplitModifierConfig config}) : _config = config;

  final SplitModifierConfig _config;

  bool _isRunning = false;
  SudokuModifierContext? _activeContext;

  @override
  SudokuModifierType get type => SudokuModifierType.split;

  @override
  bool get controlsOwnDeactivation => true;

  int get _durationSeconds => max(1, _config.duration);

  @override
  int durationSeconds(SudokuModifierContext context) => _durationSeconds;

  @override
  void onStart(SudokuModifierContext context) {
    _isRunning = true;
    _activeContext = context;
    final int duration = _durationSeconds;
    context.splitController
      ..removeStatusListener(_onStatusChanged)
      ..addStatusListener(_onStatusChanged)
      ..stop()
      ..duration = Duration(seconds: duration)
      ..reset()
      ..forward();
  }

  @override
  void onStop(SudokuModifierContext context) {
    _isRunning = false;
    _activeContext = null;
    context.splitController
      ..removeStatusListener(_onStatusChanged)
      ..stop()
      ..reset();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (!_isRunning || status != AnimationStatus.completed) {
      return;
    }
    final SudokuModifierContext? context = _activeContext;
    if (context == null || !context.mounted) {
      return;
    }
    context.deactivateCurrentModifier();
  }
}
