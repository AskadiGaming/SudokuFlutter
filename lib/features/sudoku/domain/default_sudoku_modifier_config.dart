import 'sudoku_modifier_config.dart';

final SudokuModifierGlobalConfig defaultSudokuModifierGlobalConfig =
    SudokuModifierGlobalConfig(
      scheduler: SudokuSchedulerConfig(spawnMinSeconds: 8, spawnMaxSeconds: 20),
      shaking: ShakingModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: DurationRangeConfig(minSeconds: 3, maxSeconds: 6),
        tickMilliseconds: 55,
        minOffsetPx: -4,
        maxOffsetPx: 4,
      ),
      rotation360: Rotation360ModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: 10,
      ),
      rotation90: Rotation90ModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: 4,
      ),
      goat: GoatModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: DurationRangeConfig(minSeconds: 3, maxSeconds: 6),
        spawnMinMilliseconds: 320,
        spawnMaxMilliseconds: 900,
        minSizePx: 64,
        maxSizePx: 128,
        minSpeedPxPerSecond: 85,
        maxSpeedPxPerSecond: 185,
        maxVisibleGoats: 8,
        movementTickMilliseconds: 16,
        leftStartFactor: 0.6,
        rightStartFactor: 0.4,
      ),
      textRotation: TextRotationModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
        duration: 6,
      ),
      split: SplitModifierConfig(
        runtime: ModifierRuntimeConfig(enabled: true, weight: 100),
        duration: 4,
        maxOffsetPx: 48,
      ),
    );
