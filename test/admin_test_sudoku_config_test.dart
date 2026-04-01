import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/admin_test_sudoku_config.dart';

void main() {
  test(
    'hasValidOverride is true only when enabled and value has 81 digits',
    () {
      const String valid =
          '123456789'
          '123456789'
          '123456789'
          '123456789'
          '123456789'
          '123456789'
          '123456789'
          '123456789'
          '123456789';

      const AdminTestSudokuConfig enabledValid = AdminTestSudokuConfig(
        enabled: true,
        sudokuString: valid,
      );
      const AdminTestSudokuConfig disabledValid = AdminTestSudokuConfig(
        enabled: false,
        sudokuString: valid,
      );
      const AdminTestSudokuConfig enabledTooShort = AdminTestSudokuConfig(
        enabled: true,
        sudokuString: '123',
      );
      const AdminTestSudokuConfig enabledInvalidChars = AdminTestSudokuConfig(
        enabled: true,
        sudokuString:
            '123456789'
            '123456789'
            '123456789'
            '123456789'
            '123456789'
            '123456789'
            '123456789'
            '123456789'
            '12345678X',
      );

      expect(enabledValid.hasValidOverride, isTrue);
      expect(disabledValid.hasValidOverride, isFalse);
      expect(enabledTooShort.hasValidOverride, isFalse);
      expect(enabledInvalidChars.hasValidOverride, isFalse);
    },
  );
}
