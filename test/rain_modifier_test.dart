import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_modifier_config.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/models/flying_goat.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/models/rain_drop.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/rain_modifier.dart';

void main() {
  test('rain modifier updates drops and cleans up on stop', () async {
    final List<RainDrop> rainDrops = <RainDrop>[];
    final _RainHarness harness = _RainHarness(rainDrops: rainDrops);

    final RainModifier modifier = RainModifier(
      config: RainModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: DurationRangeConfig(minSeconds: 1, maxSeconds: 1),
        spawnMinMilliseconds: 1,
        spawnMaxMilliseconds: 1,
        movementTickMilliseconds: 5,
        minDropLengthPx: 10,
        maxDropLengthPx: 10,
        minSpeedPxPerSecond: 3000,
        maxSpeedPxPerSecond: 3000,
        maxVisibleDrops: 8,
        minOpacity: 0.3,
        maxOpacity: 0.3,
      ),
    );

    modifier.onStart(harness.context);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(rainDrops, isNotEmpty);
    expect(
      rainDrops.any(
        (RainDrop drop) => drop.y - drop.lengthPx > harness.rainViewport.height,
      ),
      isFalse,
    );

    modifier.onStop(harness.context);
    expect(rainDrops, isEmpty);

    modifier.dispose();
    harness.dispose();
  });
}

class _RainHarness {
  _RainHarness({required List<RainDrop> rainDrops}) : _rainDrops = rainDrops {
    const TestVSync vsync = TestVSync();
    _rotationController = AnimationController(vsync: vsync);
    _rotation90Controller = AnimationController(vsync: vsync);
    _textRotationController = AnimationController(vsync: vsync);
    _splitController = AnimationController(vsync: vsync);

    context = SudokuModifierContext(
      random: Random(42),
      tickerProvider: vsync,
      isMounted: () => true,
      scheduleSetState: (VoidCallback callback) => callback(),
      deactivateModifier: () {},
      readGridData: () => null,
      readGridShakeOffset: () => Offset.zero,
      writeGridShakeOffset: (_) {},
      readQuarterTurns: () => 0,
      writeQuarterTurns: (_) {},
      readGoatViewportSize: () => Size.zero,
      readFlyingGoats: () => <FlyingGoat>[],
      readAndIncrementNextGoatId: () => 0,
      readLastGoatUpdate: () => null,
      writeLastGoatUpdate: (_) {},
      readRainViewportSize: () => rainViewport,
      readRainDrops: () => _rainDrops,
      readAndIncrementNextRainDropId: () => _nextRainDropId++,
      readLastRainUpdate: () => _lastRainUpdate,
      writeLastRainUpdate: (DateTime? value) {
        _lastRainUpdate = value;
      },
      rotationController: _rotationController,
      rotation90Controller: _rotation90Controller,
      textRotationController: _textRotationController,
      splitController: _splitController,
      textRotationDirections: <int, int>{},
    );
  }

  final Size rainViewport = const Size(200, 200);
  final List<RainDrop> _rainDrops;
  DateTime? _lastRainUpdate;
  int _nextRainDropId = 0;

  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;
  late final AnimationController _textRotationController;
  late final AnimationController _splitController;
  late final SudokuModifierContext context;

  void dispose() {
    _rotationController.dispose();
    _rotation90Controller.dispose();
    _textRotationController.dispose();
    _splitController.dispose();
  }
}
