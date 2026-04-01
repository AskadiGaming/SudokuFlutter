import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_modifier_config.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_modifier_type.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/core/sudoku_modifier.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/core/sudoku_modifier_registry.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/core/sudoku_modifier_scheduler.dart';
import 'package:hello_world_app/features/sudoku/presentation/modifiers/models/flying_goat.dart';

void main() {
  group('SudokuModifierScheduler', () {
    test('never selects disabled modifiers', () async {
      final _SchedulerHarness harness = _SchedulerHarness(
        registry: SudokuModifierRegistry(
          modifiers: <SudokuModifier>[
            _FakeModifier(SudokuModifierType.shaking),
            _FakeModifier(SudokuModifierType.goat),
          ],
        ),
        config: _buildConfig(
          shakingRuntime: ModifierRuntimeConfig(enabled: true, weight: 1),
          goatRuntime: ModifierRuntimeConfig(enabled: false, weight: 50),
        ),
      );

      harness.scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(harness.activeModifier, SudokuModifierType.shaking);
      harness.dispose();
    });

    test('respects weight by excluding weight=0 candidates', () async {
      final _SchedulerHarness harness = _SchedulerHarness(
        registry: SudokuModifierRegistry(
          modifiers: <SudokuModifier>[
            _FakeModifier(SudokuModifierType.shaking),
            _FakeModifier(SudokuModifierType.goat),
          ],
        ),
        config: _buildConfig(
          shakingRuntime: ModifierRuntimeConfig(enabled: true, weight: 0),
          goatRuntime: ModifierRuntimeConfig(enabled: true, weight: 1),
        ),
      );

      harness.scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(harness.activeModifier, SudokuModifierType.goat);
      harness.dispose();
    });

    test('handles empty active modifier set without crashing', () async {
      final _SchedulerHarness harness = _SchedulerHarness(
        registry: SudokuModifierRegistry(
          modifiers: <SudokuModifier>[
            _FakeModifier(SudokuModifierType.shaking),
            _FakeModifier(SudokuModifierType.goat),
          ],
        ),
        config: _buildConfig(
          shakingRuntime: ModifierRuntimeConfig(enabled: false, weight: 1),
          goatRuntime: ModifierRuntimeConfig(enabled: false, weight: 1),
        ),
      );

      harness.scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.activeModifier, isNull);
      harness.dispose();
    });
  });
}

class _SchedulerHarness {
  _SchedulerHarness({
    required SudokuModifierRegistry registry,
    required SudokuModifierGlobalConfig config,
  }) {
    final TestVSync vsync = TestVSync();
    _rotationController = AnimationController(vsync: vsync);
    _rotation90Controller = AnimationController(vsync: vsync);
    _textRotationController = AnimationController(vsync: vsync);

    _context = SudokuModifierContext(
      random: Random(42),
      tickerProvider: vsync,
      isMounted: () => true,
      scheduleSetState: (VoidCallback callback) => callback(),
      deactivateModifier: () => scheduler.deactivateCurrentModifier(),
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
      rotationController: _rotationController,
      rotation90Controller: _rotation90Controller,
      textRotationController: _textRotationController,
      textRotationDirections: <int, int>{},
    );

    scheduler = SudokuModifierScheduler(
      registry: registry,
      context: _context,
      config: config,
      onModifierChanged: (SudokuModifierType? modifier) {
        activeModifier = modifier;
      },
    );
  }

  late final SudokuModifierContext _context;
  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;
  late final AnimationController _textRotationController;
  late final SudokuModifierScheduler scheduler;

  SudokuModifierType? activeModifier;

  void dispose() {
    scheduler.dispose();
    _rotationController.dispose();
    _rotation90Controller.dispose();
    _textRotationController.dispose();
  }
}

SudokuModifierGlobalConfig _buildConfig({
  ModifierRuntimeConfig? shakingRuntime,
  ModifierRuntimeConfig? goatRuntime,
}) {
  return SudokuModifierGlobalConfig(
    scheduler: SudokuSchedulerConfig(spawnMinSeconds: 0, spawnMaxSeconds: 0),
    shaking: ShakingModifierConfig(
      runtime:
          shakingRuntime ?? ModifierRuntimeConfig(enabled: true, weight: 1),
      duration: DurationRangeConfig(minSeconds: 3, maxSeconds: 6),
      tickMilliseconds: 55,
      minOffsetPx: -4,
      maxOffsetPx: 4,
    ),
    rotation360: Rotation360ModifierConfig(
      runtime: ModifierRuntimeConfig(enabled: false, weight: 0),
      duration: 10,
    ),
    rotation90: Rotation90ModifierConfig(
      runtime: ModifierRuntimeConfig(enabled: false, weight: 0),
      duration: 4,
    ),
    goat: GoatModifierConfig(
      runtime: goatRuntime ?? ModifierRuntimeConfig(enabled: true, weight: 1),
      duration: DurationRangeConfig(minSeconds: 3, maxSeconds: 6),
      spawnMinMilliseconds: 320,
      spawnMaxMilliseconds: 900,
      minSizePx: 64,
      maxSizePx: 128,
      minSpeedPxPerSecond: 85,
      maxSpeedPxPerSecond: 185,
      maxVisibleGoats: 8,
      movementTickMilliseconds: 16,
    ),
    textRotation: TextRotationModifierConfig(
      runtime: ModifierRuntimeConfig(enabled: false, weight: 0),
      duration: 6,
    ),
  );
}

class _FakeModifier extends SudokuModifier {
  _FakeModifier(this._type);

  final SudokuModifierType _type;

  @override
  SudokuModifierType get type => _type;

  @override
  int durationSeconds(SudokuModifierContext context) => 30;

  @override
  void onStart(SudokuModifierContext context) {}

  @override
  void onStop(SudokuModifierContext context) {}
}
