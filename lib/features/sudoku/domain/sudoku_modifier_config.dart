import 'package:flutter/foundation.dart';

import 'sudoku_modifier_type.dart';

class SudokuModifierGlobalConfig {
  SudokuModifierGlobalConfig({
    required this.scheduler,
    required this.shaking,
    required this.rotation360,
    required this.rotation90,
    required this.goat,
    required this.rain,
    required this.textRotation,
    required this.split,
  });

  final SudokuSchedulerConfig scheduler;
  final ShakingModifierConfig shaking;
  final Rotation360ModifierConfig rotation360;
  final Rotation90ModifierConfig rotation90;
  final GoatModifierConfig goat;
  final RainModifierConfig rain;
  final TextRotationModifierConfig textRotation;
  final SplitModifierConfig split;

  ModifierRuntimeConfig runtimeFor(SudokuModifierType type) {
    switch (type) {
      case SudokuModifierType.shaking:
        return shaking.runtime;
      case SudokuModifierType.rotation360:
        return rotation360.runtime;
      case SudokuModifierType.rotation90:
        return rotation90.runtime;
      case SudokuModifierType.goat:
        return goat.runtime;
      case SudokuModifierType.rain:
        return rain.runtime;
      case SudokuModifierType.textRotation:
        return textRotation.runtime;
      case SudokuModifierType.split:
        return split.runtime;
    }
  }
}

class SudokuSchedulerConfig {
  SudokuSchedulerConfig({
    required this.spawnMinSeconds,
    required this.spawnMaxSeconds,
  }) {
    if (spawnMinSeconds < 0 || spawnMaxSeconds < 0) {
      throw ArgumentError(
        'Spawn interval must be >= 0 seconds, got $spawnMinSeconds/$spawnMaxSeconds.',
      );
    }
    if (spawnMinSeconds > spawnMaxSeconds) {
      throw ArgumentError(
        'spawnMinSeconds must be <= spawnMaxSeconds, got '
        '$spawnMinSeconds/$spawnMaxSeconds.',
      );
    }
  }

  final int spawnMinSeconds;
  final int spawnMaxSeconds;
}

class ModifierRuntimeConfig {
  ModifierRuntimeConfig({required this.enabled, required this.weight}) {
    if (weight < 0) {
      throw ArgumentError('Modifier weight must be >= 0, got $weight.');
    }
  }

  final bool enabled;
  final int weight;
}

class DurationRangeConfig {
  DurationRangeConfig({
    required this.minSeconds,
    required this.maxSeconds,
    this.allowZero = false,
  }) {
    final int lowerBound = allowZero ? 0 : 1;
    if (minSeconds < lowerBound || maxSeconds < lowerBound) {
      throw ArgumentError(
        'Duration seconds must be >= $lowerBound, got $minSeconds/$maxSeconds.',
      );
    }
    if (minSeconds > maxSeconds) {
      throw ArgumentError(
        'minSeconds must be <= maxSeconds, got $minSeconds/$maxSeconds.',
      );
    }
  }

  final int minSeconds;
  final int maxSeconds;
  final bool allowZero;
}

class ShakingModifierConfig {
  ShakingModifierConfig({
    required this.runtime,
    required this.duration,
    required this.tickMilliseconds,
    required this.minOffsetPx,
    required this.maxOffsetPx,
  }) {
    if (tickMilliseconds <= 0) {
      throw ArgumentError(
        'Shaking tickMilliseconds must be > 0, got $tickMilliseconds.',
      );
    }
    if (minOffsetPx > maxOffsetPx) {
      throw ArgumentError(
        'Shaking minOffsetPx must be <= maxOffsetPx, got '
        '$minOffsetPx/$maxOffsetPx.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final DurationRangeConfig duration;
  final int tickMilliseconds;
  final double minOffsetPx;
  final double maxOffsetPx;
}

class Rotation360ModifierConfig {
  Rotation360ModifierConfig({required this.runtime, required this.duration}) {
    if (duration <= 0) {
      throw ArgumentError(
        'Rotation360 duration must be > 0 seconds, got $duration.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final int duration;
}

class Rotation90ModifierConfig {
  Rotation90ModifierConfig({required this.runtime, required this.duration}) {
    if (duration <= 0) {
      throw ArgumentError(
        'Rotation90 duration must be > 0 seconds, got $duration.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final int duration;
}

class TextRotationModifierConfig {
  TextRotationModifierConfig({required this.runtime, required this.duration}) {
    if (duration <= 0) {
      throw ArgumentError(
        'TextRotation duration must be > 0 seconds, got $duration.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final int duration;
}

class GoatModifierConfig {
  GoatModifierConfig({
    required this.runtime,
    required this.duration,
    required this.spawnMinMilliseconds,
    required this.spawnMaxMilliseconds,
    required this.minSizePx,
    required this.maxSizePx,
    required this.minSpeedPxPerSecond,
    required this.maxSpeedPxPerSecond,
    required this.maxVisibleGoats,
    required this.movementTickMilliseconds,
    this.leftStartFactor = 0.6,
    this.rightStartFactor = 0.4,
  }) {
    if (spawnMinMilliseconds <= 0 || spawnMaxMilliseconds <= 0) {
      throw ArgumentError(
        'Goat spawn interval must be > 0 ms, got '
        '$spawnMinMilliseconds/$spawnMaxMilliseconds.',
      );
    }
    if (spawnMinMilliseconds > spawnMaxMilliseconds) {
      throw ArgumentError(
        'Goat spawnMinMilliseconds must be <= spawnMaxMilliseconds, got '
        '$spawnMinMilliseconds/$spawnMaxMilliseconds.',
      );
    }
    if (minSizePx <= 0 || maxSizePx <= 0 || minSizePx > maxSizePx) {
      throw ArgumentError('Goat size range invalid: $minSizePx/$maxSizePx.');
    }
    if (minSpeedPxPerSecond <= 0 ||
        maxSpeedPxPerSecond <= 0 ||
        minSpeedPxPerSecond > maxSpeedPxPerSecond) {
      throw ArgumentError(
        'Goat speed range invalid: $minSpeedPxPerSecond/$maxSpeedPxPerSecond.',
      );
    }
    if (maxVisibleGoats <= 0) {
      throw ArgumentError(
        'Goat maxVisibleGoats must be > 0, got $maxVisibleGoats.',
      );
    }
    if (movementTickMilliseconds <= 0) {
      throw ArgumentError(
        'Goat movementTickMilliseconds must be > 0, got '
        '$movementTickMilliseconds.',
      );
    }
    if (leftStartFactor < 0 || rightStartFactor < 0) {
      throw ArgumentError(
        'Goat start factors must be >= 0, got '
        '$leftStartFactor/$rightStartFactor.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final DurationRangeConfig duration;
  final int spawnMinMilliseconds;
  final int spawnMaxMilliseconds;
  final double minSizePx;
  final double maxSizePx;
  final double minSpeedPxPerSecond;
  final double maxSpeedPxPerSecond;
  final int maxVisibleGoats;
  final int movementTickMilliseconds;
  final double leftStartFactor;
  final double rightStartFactor;

  @visibleForTesting
  bool get hasValidDurationRange =>
      duration.minSeconds <= duration.maxSeconds && duration.minSeconds > 0;
}

class RainModifierConfig {
  RainModifierConfig({
    required this.runtime,
    required this.duration,
    required this.spawnMinMilliseconds,
    required this.spawnMaxMilliseconds,
    required this.movementTickMilliseconds,
    required this.minDropLengthPx,
    required this.maxDropLengthPx,
    required this.minSpeedPxPerSecond,
    required this.maxSpeedPxPerSecond,
    required this.maxVisibleDrops,
    required this.minOpacity,
    required this.maxOpacity,
    this.minThicknessPx = 1,
    this.maxThicknessPx = 2,
    this.slantDxPerLength = -0.2,
  }) {
    if (spawnMinMilliseconds <= 0 || spawnMaxMilliseconds <= 0) {
      throw ArgumentError(
        'Rain spawn interval must be > 0 ms, got '
        '$spawnMinMilliseconds/$spawnMaxMilliseconds.',
      );
    }
    if (spawnMinMilliseconds > spawnMaxMilliseconds) {
      throw ArgumentError(
        'Rain spawnMinMilliseconds must be <= spawnMaxMilliseconds, got '
        '$spawnMinMilliseconds/$spawnMaxMilliseconds.',
      );
    }
    if (movementTickMilliseconds <= 0) {
      throw ArgumentError(
        'Rain movementTickMilliseconds must be > 0, got '
        '$movementTickMilliseconds.',
      );
    }
    if (minDropLengthPx <= 0 ||
        maxDropLengthPx <= 0 ||
        minDropLengthPx > maxDropLengthPx) {
      throw ArgumentError(
        'Rain drop length range invalid: $minDropLengthPx/$maxDropLengthPx.',
      );
    }
    if (minSpeedPxPerSecond <= 0 ||
        maxSpeedPxPerSecond <= 0 ||
        minSpeedPxPerSecond > maxSpeedPxPerSecond) {
      throw ArgumentError(
        'Rain speed range invalid: $minSpeedPxPerSecond/$maxSpeedPxPerSecond.',
      );
    }
    if (maxVisibleDrops <= 0) {
      throw ArgumentError(
        'Rain maxVisibleDrops must be > 0, got $maxVisibleDrops.',
      );
    }
    if (minOpacity <= 0 ||
        maxOpacity <= 0 ||
        minOpacity > maxOpacity ||
        maxOpacity > 1) {
      throw ArgumentError(
        'Rain opacity range invalid: $minOpacity/$maxOpacity.',
      );
    }
    if (minThicknessPx <= 0 ||
        maxThicknessPx <= 0 ||
        minThicknessPx > maxThicknessPx) {
      throw ArgumentError(
        'Rain thickness range invalid: $minThicknessPx/$maxThicknessPx.',
      );
    }
  }

  final ModifierRuntimeConfig runtime;
  final DurationRangeConfig duration;
  final int spawnMinMilliseconds;
  final int spawnMaxMilliseconds;
  final int movementTickMilliseconds;
  final double minDropLengthPx;
  final double maxDropLengthPx;
  final double minSpeedPxPerSecond;
  final double maxSpeedPxPerSecond;
  final int maxVisibleDrops;
  final double minOpacity;
  final double maxOpacity;
  final double minThicknessPx;
  final double maxThicknessPx;
  final double slantDxPerLength;
}

class SplitModifierConfig {
  SplitModifierConfig({
    required this.runtime,
    required this.duration,
    required this.maxOffsetPx,
  }) {
    if (duration <= 0) {
      throw ArgumentError('Split duration must be > 0 seconds, got $duration.');
    }
    if (maxOffsetPx < 0) {
      throw ArgumentError('Split maxOffsetPx must be >= 0, got $maxOffsetPx.');
    }
  }

  final ModifierRuntimeConfig runtime;
  final int duration;
  final double maxOffsetPx;
}
