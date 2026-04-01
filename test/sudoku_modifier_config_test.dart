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
  });
}
