import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/sudoku_grid_parser.dart';
import '../models/flying_goat.dart';
import '../models/rain_drop.dart';

class SudokuModifierContext {
  SudokuModifierContext({
    required this.random,
    required TickerProvider tickerProvider,
    required bool Function() isMounted,
    required void Function(VoidCallback callback) scheduleSetState,
    required void Function() deactivateModifier,
    required SudokuGridData? Function() readGridData,
    required Offset Function() readGridShakeOffset,
    required void Function(Offset value) writeGridShakeOffset,
    required int Function() readQuarterTurns,
    required void Function(int value) writeQuarterTurns,
    required Size Function() readGoatViewportSize,
    required List<FlyingGoat> Function() readFlyingGoats,
    required int Function() readAndIncrementNextGoatId,
    required DateTime? Function() readLastGoatUpdate,
    required void Function(DateTime? value) writeLastGoatUpdate,
    required Size Function() readRainViewportSize,
    required List<RainDrop> Function() readRainDrops,
    required int Function() readAndIncrementNextRainDropId,
    required DateTime? Function() readLastRainUpdate,
    required void Function(DateTime? value) writeLastRainUpdate,
    required this.rotationController,
    required this.rotation90Controller,
    required this.textRotationController,
    required this.splitController,
    required this.textRotationDirections,
  }) : _tickerProvider = tickerProvider,
       _isMounted = isMounted,
       _scheduleSetState = scheduleSetState,
       _deactivateModifier = deactivateModifier,
       _readGridData = readGridData,
       _readGridShakeOffset = readGridShakeOffset,
       _writeGridShakeOffset = writeGridShakeOffset,
       _readQuarterTurns = readQuarterTurns,
       _writeQuarterTurns = writeQuarterTurns,
       _readGoatViewportSize = readGoatViewportSize,
       _readFlyingGoats = readFlyingGoats,
       _readAndIncrementNextGoatId = readAndIncrementNextGoatId,
       _readLastGoatUpdate = readLastGoatUpdate,
       _writeLastGoatUpdate = writeLastGoatUpdate,
       _readRainViewportSize = readRainViewportSize,
       _readRainDrops = readRainDrops,
       _readAndIncrementNextRainDropId = readAndIncrementNextRainDropId,
       _readLastRainUpdate = readLastRainUpdate,
       _writeLastRainUpdate = writeLastRainUpdate;

  final Random random;
  final TickerProvider _tickerProvider;
  final bool Function() _isMounted;
  final void Function(VoidCallback callback) _scheduleSetState;
  final void Function() _deactivateModifier;
  final SudokuGridData? Function() _readGridData;
  final Offset Function() _readGridShakeOffset;
  final void Function(Offset value) _writeGridShakeOffset;
  final int Function() _readQuarterTurns;
  final void Function(int value) _writeQuarterTurns;
  final Size Function() _readGoatViewportSize;
  final List<FlyingGoat> Function() _readFlyingGoats;
  final int Function() _readAndIncrementNextGoatId;
  final DateTime? Function() _readLastGoatUpdate;
  final void Function(DateTime? value) _writeLastGoatUpdate;
  final Size Function() _readRainViewportSize;
  final List<RainDrop> Function() _readRainDrops;
  final int Function() _readAndIncrementNextRainDropId;
  final DateTime? Function() _readLastRainUpdate;
  final void Function(DateTime? value) _writeLastRainUpdate;

  final AnimationController rotationController;
  final AnimationController rotation90Controller;
  final AnimationController textRotationController;
  final AnimationController splitController;
  final Map<int, int> textRotationDirections;

  bool get mounted => _isMounted();

  TickerProvider get tickerProvider => _tickerProvider;

  SudokuGridData? get gridData => _readGridData();

  Offset get gridShakeOffset => _readGridShakeOffset();

  set gridShakeOffset(Offset value) => _writeGridShakeOffset(value);

  int get quarterTurns => _readQuarterTurns();

  set quarterTurns(int value) => _writeQuarterTurns(value);

  Size get goatViewportSize => _readGoatViewportSize();

  List<FlyingGoat> get flyingGoats => _readFlyingGoats();

  int consumeNextGoatId() => _readAndIncrementNextGoatId();

  DateTime? get lastGoatUpdate => _readLastGoatUpdate();

  set lastGoatUpdate(DateTime? value) => _writeLastGoatUpdate(value);

  Size get rainViewportSize => _readRainViewportSize();

  List<RainDrop> get rainDrops => _readRainDrops();

  int consumeNextRainDropId() => _readAndIncrementNextRainDropId();

  DateTime? get lastRainUpdate => _readLastRainUpdate();

  set lastRainUpdate(DateTime? value) => _writeLastRainUpdate(value);

  void safeSetState(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    _scheduleSetState(callback);
  }

  void deactivateCurrentModifier() => _deactivateModifier();

  int randomBetweenInclusive(int min, int max) {
    if (min == max) {
      return min;
    }
    return min + random.nextInt(max - min + 1);
  }

  double randomDoubleBetween(double min, double max) {
    if (min == max) {
      return min;
    }
    return min + (random.nextDouble() * (max - min));
  }
}
