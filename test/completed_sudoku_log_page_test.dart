import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku_history/data/completed_sudoku_log_repository.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_entry.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_mode.dart';
import 'package:hello_world_app/features/sudoku_history/presentation/completed_sudoku_log_page.dart';

void main() {
  testWidgets('shows empty state when no completed sudokus exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompletedSudokuLogPage(
          repository: _FakeCompletedSudokuLogRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine abgeschlossenen Sudokus'), findsOneWidget);
  });

  testWidgets('renders difficulty, timestamp and duration for log entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompletedSudokuLogPage(
          repository: _FakeCompletedSudokuLogRepository(
            entries: <CompletedSudokuEntry>[
              CompletedSudokuEntry(
                id: 1,
                difficulty: SudokuDifficulty.hard,
                mode: CompletedSudokuMode.normal,
                startedAt: DateTime(2026, 6, 4, 8, 0),
                completedAt: DateTime(2026, 6, 4, 8, 12, 34),
                durationSeconds: 754,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Schwer'), findsOneWidget);
    expect(
      find.text('Abgeschlossen am: 04.06.2026 08:12'),
      findsOneWidget,
    );
    expect(find.text('Dauer: 12 min 34 s'), findsOneWidget);
  });
}

class _FakeCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  _FakeCompletedSudokuLogRepository({
    this.entries = const <CompletedSudokuEntry>[],
  });

  final List<CompletedSudokuEntry> entries;

  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {}

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async => entries;
}
