import '../domain/admin_test_sudoku_config.dart';

/// Entwicklungs-Override fuer feste Sudoku-Puzzles.
///
/// Nutzung:
/// 1) `enabled` auf `true` setzen
/// 2) `sudokuString` mit genau 81 Zeichen (nur 0-9) fuellen
/// 3) App neu starten
const AdminTestSudokuConfig adminTestSudokuOverrideConfig =
    AdminTestSudokuConfig(
      enabled: false,
      sudokuString: '534678912672195348198342567859761423426853791713924856961537284287419635345286170',
      // Beispiel:
      // sudokuString:
      //   '530070000'
      //   '600195000'
      //   '098000060'
      //   '800060003'
      //   '400803001'
      //   '700020006'
      //   '060000280'
      //   '000419005'
      //   '000080079',
    );
