import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/sudoku_modifier_config.dart';
import '../../domain/sudoku_modifier_type.dart';
import 'core/sudoku_modifier.dart';
import 'core/sudoku_modifier_context.dart';
import 'models/rain_drop.dart';

class RainModifier extends SudokuModifier {
  RainModifier({required RainModifierConfig config}) : _config = config;

  final RainModifierConfig _config;

  Timer? _rainSpawnTimer;
  Timer? _rainMovementTimer;

  @override
  SudokuModifierType get type => SudokuModifierType.rain;

  @override
  int durationSeconds(SudokuModifierContext context) {
    final int minSeconds = max(1, _config.duration.minSeconds);
    final int maxSeconds = max(minSeconds, _config.duration.maxSeconds);
    return context.randomBetweenInclusive(minSeconds, maxSeconds);
  }

  @override
  void onStart(SudokuModifierContext context) {
    _stopRainModifier(context: context, clearDrops: true);
    context.lastRainUpdate = DateTime.now();

    final int movementTickMs = max(1, _config.movementTickMilliseconds);
    _rainMovementTimer = Timer.periodic(
      Duration(milliseconds: movementTickMs),
      (_) => _updateRain(context),
    );
    _scheduleNextRainSpawn(context);
  }

  @override
  void onStop(SudokuModifierContext context) {
    _stopRainModifier(context: context, clearDrops: true);
  }

  void _scheduleNextRainSpawn(SudokuModifierContext context) {
    _rainSpawnTimer?.cancel();
    if (!context.mounted) {
      return;
    }

    final int minSpawnMs = max(1, _config.spawnMinMilliseconds);
    final int maxSpawnMs = max(minSpawnMs, _config.spawnMaxMilliseconds);
    final int delayMs = context.randomBetweenInclusive(minSpawnMs, maxSpawnMs);
    _rainSpawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!context.mounted) {
        return;
      }
      _spawnRainDrop(context);
      _scheduleNextRainSpawn(context);
    });
  }

  void _spawnRainDrop(SudokuModifierContext context) {
    final Size viewport = context.rainViewportSize;
    if (viewport.height <= 0 || viewport.width <= 0) {
      return;
    }

    final double minLength = min(
      _config.minDropLengthPx,
      _config.maxDropLengthPx,
    );
    final double maxLength = max(
      _config.minDropLengthPx,
      _config.maxDropLengthPx,
    );
    final double length = context.randomDoubleBetween(minLength, maxLength);

    final double minSpeed = min(
      _config.minSpeedPxPerSecond,
      _config.maxSpeedPxPerSecond,
    );
    final double maxSpeed = max(
      _config.minSpeedPxPerSecond,
      _config.maxSpeedPxPerSecond,
    );
    final double speed = context.randomDoubleBetween(minSpeed, maxSpeed);

    final double minOpacity = min(_config.minOpacity, _config.maxOpacity);
    final double maxOpacity = max(_config.minOpacity, _config.maxOpacity);
    final double opacity = context.randomDoubleBetween(minOpacity, maxOpacity);

    final double minThickness = min(
      _config.minThicknessPx,
      _config.maxThicknessPx,
    );
    final double maxThickness = max(
      _config.minThicknessPx,
      _config.maxThicknessPx,
    );
    final double thickness = context.randomDoubleBetween(
      minThickness,
      maxThickness,
    );

    final double x = context.randomDoubleBetween(0, viewport.width);
    final double y = -length;

    context.safeSetState(() {
      final List<RainDrop> drops = context.rainDrops;
      final int maxVisible = max(1, _config.maxVisibleDrops);
      if (drops.length >= maxVisible) {
        drops.removeAt(0);
      }
      drops.add(
        RainDrop(
          id: context.consumeNextRainDropId(),
          x: x,
          y: y,
          lengthPx: length,
          speedPxPerSecond: speed,
          opacity: opacity,
          thicknessPx: thickness,
        ),
      );
    });
  }

  void _updateRain(SudokuModifierContext context) {
    final DateTime now = DateTime.now();
    final DateTime? lastTick = context.lastRainUpdate;
    context.lastRainUpdate = now;
    if (!context.mounted || context.rainDrops.isEmpty || lastTick == null) {
      return;
    }

    final double deltaSeconds =
        now.difference(lastTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0) {
      return;
    }

    final Size viewport = context.rainViewportSize;
    if (viewport.width <= 0 || viewport.height <= 0) {
      return;
    }

    context.safeSetState(() {
      final List<RainDrop> drops = context.rainDrops;
      for (int i = 0; i < drops.length; i++) {
        final RainDrop drop = drops[i];
        final double distance = drop.speedPxPerSecond * deltaSeconds;
        final double nextY = drop.y + distance;
        final double nextX = drop.x + (_config.slantDxPerLength * distance);
        drops[i] = drop.copyWith(x: nextX, y: nextY);
      }

      drops.removeWhere((RainDrop drop) {
        final bool isBelowViewport = drop.y - drop.lengthPx > viewport.height;
        final bool isOffLeft = drop.x < -drop.lengthPx;
        final bool isOffRight = drop.x > viewport.width + drop.lengthPx;
        return isBelowViewport || isOffLeft || isOffRight;
      });
    });
  }

  void _stopRainModifier({
    required SudokuModifierContext context,
    required bool clearDrops,
  }) {
    _rainSpawnTimer?.cancel();
    _rainSpawnTimer = null;
    _rainMovementTimer?.cancel();
    _rainMovementTimer = null;
    context.lastRainUpdate = null;

    if (!clearDrops) {
      return;
    }

    if (context.rainDrops.isNotEmpty && context.mounted) {
      context.safeSetState(() {
        context.rainDrops.clear();
      });
      return;
    }
    context.rainDrops.clear();
  }

  @override
  void dispose() {
    _rainSpawnTimer?.cancel();
    _rainMovementTimer?.cancel();
  }
}
