import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_modifier_config.dart';

void main() {
  group('Sudoku modifier config validation', () {
    test('rejects negative weight', () {
      expect(
        () => ModifierRuntimeConfig(enabled: true, weight: -1),
        throwsArgumentError,
      );
    });

    test('rejects invalid duration range', () {
      expect(
        () => DurationRangeConfig(minSeconds: 7, maxSeconds: 6),
        throwsArgumentError,
      );
    });

    test('rejects invalid scheduler spawn range', () {
      expect(
        () => SudokuSchedulerConfig(spawnMinSeconds: 10, spawnMaxSeconds: 3),
        throwsArgumentError,
      );
    });

    test('rejects invalid rain opacity range', () {
      expect(
        () => RainModifierConfig(
          runtime: ModifierRuntimeConfig(enabled: true, weight: 1),
          duration: DurationRangeConfig(minSeconds: 3, maxSeconds: 5),
          spawnMinMilliseconds: 30,
          spawnMaxMilliseconds: 70,
          movementTickMilliseconds: 16,
          minDropLengthPx: 10,
          maxDropLengthPx: 20,
          minSpeedPxPerSecond: 300,
          maxSpeedPxPerSecond: 500,
          maxVisibleDrops: 60,
          minOpacity: 0.7,
          maxOpacity: 0.5,
        ),
        throwsArgumentError,
      );
    });
  });
}
