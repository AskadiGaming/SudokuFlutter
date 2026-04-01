import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/presentation/widgets/sudoku_split_math.dart';

void main() {
  group('splitProgressForControllerValue', () {
    test('is zero at the beginning and at the end', () {
      expect(splitProgressForControllerValue(0), 0);
      expect(splitProgressForControllerValue(1), closeTo(0, 0.000001));
    });

    test('peaks in the middle', () {
      expect(splitProgressForControllerValue(0.5), closeTo(1, 0.000001));
    });
  });

  group('splitOffsetForIndex', () {
    test('returns representative offsets for corner, edge, center, corner', () {
      final cornerTopLeft = splitOffsetForIndex(
        index: 0,
        splitProgress: 1,
        maxOffsetPx: 24,
      );
      final topCenter = splitOffsetForIndex(
        index: 4,
        splitProgress: 1,
        maxOffsetPx: 24,
      );
      final center = splitOffsetForIndex(
        index: 40,
        splitProgress: 1,
        maxOffsetPx: 24,
      );
      final cornerBottomRight = splitOffsetForIndex(
        index: 80,
        splitProgress: 1,
        maxOffsetPx: 24,
      );

      expect(cornerTopLeft.dx, lessThan(0));
      expect(cornerTopLeft.dy, lessThan(0));
      expect(topCenter.dx, closeTo(0, 0.000001));
      expect(topCenter.dy, lessThan(0));
      expect(center.dx, 0);
      expect(center.dy, 0);
      expect(cornerBottomRight.dx, greaterThan(0));
      expect(cornerBottomRight.dy, greaterThan(0));
    });
  });
}
