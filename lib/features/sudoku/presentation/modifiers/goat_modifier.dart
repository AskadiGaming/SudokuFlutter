import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';
import 'models/flying_goat.dart';

class GoatModifier extends SudokuModifier {
  static const int durationMinSeconds = 3;
  static const int durationMaxSeconds = 6;
  static const int spawnMinMilliseconds = 320;
  static const int spawnMaxMilliseconds = 900;
  static const double minSizePx = 64;
  static const double maxSizePx = 128;
  static const double minSpeedPxPerSecond = 85;
  static const double maxSpeedPxPerSecond = 185;
  static const int maxVisibleGoats = 8;

  Timer? _goatSpawnTimer;
  Timer? _goatMovementTimer;

  @override
  SudokuModifierType get type => SudokuModifierType.goat;

  @override
  int durationSeconds(SudokuModifierContext context) {
    return context.randomBetweenInclusive(
      durationMinSeconds,
      durationMaxSeconds,
    );
  }

  @override
  void onStart(SudokuModifierContext context) {
    _stopGoatModifier(context: context, clearGoats: true);
    context.lastGoatUpdate = DateTime.now();
    _goatMovementTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateGoats(context),
    );
    _scheduleNextGoatSpawn(context);
  }

  @override
  void onStop(SudokuModifierContext context) {
    _stopGoatModifier(context: context, clearGoats: true);
  }

  void _scheduleNextGoatSpawn(SudokuModifierContext context) {
    _goatSpawnTimer?.cancel();
    if (!context.mounted) {
      return;
    }

    final int delayMs = context.randomBetweenInclusive(
      spawnMinMilliseconds,
      spawnMaxMilliseconds,
    );
    _goatSpawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!context.mounted) {
        return;
      }
      _spawnGoat(context);
      _scheduleNextGoatSpawn(context);
    });
  }

  void _spawnGoat(SudokuModifierContext context) {
    final Size viewport = context.goatViewportSize;
    if (viewport.height <= 0 || viewport.width <= 0) {
      return;
    }

    final GoatDirection direction =
        context.random.nextBool()
            ? GoatDirection.leftToRight
            : GoatDirection.rightToLeft;
    final double size = context.randomDoubleBetween(minSizePx, maxSizePx);
    final double maxY = max(0, viewport.height - size);
    final double y = context.randomDoubleBetween(0, maxY);
    final double speed = context.randomDoubleBetween(
      minSpeedPxPerSecond,
      maxSpeedPxPerSecond,
    );
    final double startX =
        direction == GoatDirection.leftToRight
            ? -(size * 0.6)
            : viewport.width - (size * 0.4);

    context.safeSetState(() {
      final List<FlyingGoat> goats = context.flyingGoats;
      if (goats.length >= maxVisibleGoats) {
        goats.removeAt(0);
      }
      goats.add(
        FlyingGoat(
          id: context.consumeNextGoatId(),
          direction: direction,
          sizePx: size,
          startY: y,
          speedPxPerSecond: speed,
          spawnTime: DateTime.now(),
          x: startX,
        ),
      );
    });
  }

  void _updateGoats(SudokuModifierContext context) {
    final DateTime now = DateTime.now();
    final DateTime? lastTick = context.lastGoatUpdate;
    context.lastGoatUpdate = now;
    if (!context.mounted || context.flyingGoats.isEmpty || lastTick == null) {
      return;
    }

    final double deltaSeconds =
        now.difference(lastTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0) {
      return;
    }

    final double viewportWidth = context.goatViewportSize.width;
    if (viewportWidth <= 0) {
      return;
    }

    context.safeSetState(() {
      final List<FlyingGoat> goats = context.flyingGoats;
      for (int i = 0; i < goats.length; i++) {
        final FlyingGoat goat = goats[i];
        final double distance = goat.speedPxPerSecond * deltaSeconds;
        final double nextX =
            goat.direction == GoatDirection.leftToRight
                ? goat.x + distance
                : goat.x - distance;
        goats[i] = goat.copyWith(x: nextX);
      }

      goats.removeWhere((FlyingGoat goat) {
        if (goat.direction == GoatDirection.leftToRight) {
          return goat.x > viewportWidth + goat.sizePx;
        }
        return goat.x + goat.sizePx < -goat.sizePx;
      });
    });
  }

  void _stopGoatModifier({
    required SudokuModifierContext context,
    required bool clearGoats,
  }) {
    _goatSpawnTimer?.cancel();
    _goatSpawnTimer = null;
    _goatMovementTimer?.cancel();
    _goatMovementTimer = null;
    context.lastGoatUpdate = null;

    if (!clearGoats) {
      return;
    }

    if (context.flyingGoats.isNotEmpty && context.mounted) {
      context.safeSetState(() {
        context.flyingGoats.clear();
      });
      return;
    }
    context.flyingGoats.clear();
  }

  @override
  void dispose() {
    _goatSpawnTimer?.cancel();
    _goatMovementTimer?.cancel();
  }
}
