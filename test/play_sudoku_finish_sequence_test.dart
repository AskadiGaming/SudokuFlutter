import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';
import 'package:hello_world_app/features/sudoku_history/data/completed_sudoku_log_repository.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_entry.dart';

void main() {
  testWidgets('hides admin solve button when feature flag is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '534678912672195348198342567859761423426853791713924856961537284287419635345286170',
          ),
          adminTestOverrideEnabled: false,
          adminSolveButtonEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-solve-sudoku-button')), findsNothing);
  });

  testWidgets(
    'admin solve button fills the sudoku except for one last editable cell',
    (WidgetTester tester) async {
      int replayCalls = 0;
      final _RecordingCompletedSudokuLogRepository historyRepository =
          _RecordingCompletedSudokuLogRepository();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaySudokuPage(
            roundConfig: const SudokuRoundConfig(
              difficulty: SudokuDifficulty.easy,
            ),
            repository: _FakeSudokuRepository(
              puzzle:
                  '534678912672195348198342567859761423426853791713924856961537284287419635345286100',
            ),
            completedSudokuLogRepository: historyRepository,
            adminTestOverrideEnabled: false,
            adminSolveButtonEnabled: true,
            onReplayRoundRequested: (
              BuildContext context,
              SudokuRoundConfig config,
            ) async {
              replayCalls++;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-solve-sudoku-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('admin-solve-sudoku-button')));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-7')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-8')),
          matching: find.text('9'),
        ),
        findsNothing,
      );
      expect(find.text('Sudoku geloest'), findsNothing);

      await tester.tap(find.byKey(const Key('number-button-9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sudoku-cell-8-8')));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-8')),
          matching: find.text('9'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(seconds: 5));

      final BuildContext context = tester.element(find.byType(PlaySudokuPage));
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.sudokuSolvedTitle), findsOneWidget);
      expect(historyRepository.entries, hasLength(1));

      await tester.tap(find.text(l10n.sudokuPlayAgain));
      await tester.pump();
      expect(replayCalls, 1);
    },
  );

  testWidgets('runs finish sequence, locks interaction and shows replay CTA', (
    WidgetTester tester,
  ) async {
    int replayCalls = 0;
    final _RecordingCompletedSudokuLogRepository historyRepository =
        _RecordingCompletedSudokuLogRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '534678912672195348198342567859761423426853791713924856961537284287419635345286170',
          ),
          completedSudokuLogRepository: historyRepository,
          adminTestOverrideEnabled: false,
          onReplayRoundRequested: (
            BuildContext context,
            SudokuRoundConfig config,
          ) async {
            replayCalls++;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('number-button-9')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sudoku-cell-8-8')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final Finder firstCellOpacity = find.ancestor(
      of: find.byKey(const Key('sudoku-cell-0-0')),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(firstCellOpacity).opacity, 0);

    final ToggleButtons numberPad = tester.widget<ToggleButtons>(
      find.byKey(const Key('number-toggle-buttons')),
    );
    expect(numberPad.onPressed, isNull);

    await tester.pump(const Duration(seconds: 5));

    final BuildContext context = tester.element(find.byType(PlaySudokuPage));
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.sudokuSolvedTitle), findsOneWidget);
    expect(find.text(l10n.sudokuPlayAgain), findsOneWidget);
    expect(historyRepository.entries, hasLength(1));
    expect(historyRepository.entries.single.difficulty, SudokuDifficulty.easy);
    expect(
      historyRepository.entries.single.durationSeconds,
      greaterThanOrEqualTo(0),
    );

    await tester.tap(find.text(l10n.sudokuPlayAgain));
    await tester.pump();
    expect(replayCalls, 1);
  });
}

class _FakeSudokuRepository implements SudokuPuzzleRepository {
  _FakeSudokuRepository({required this.puzzle});

  final String puzzle;

  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async => puzzle;

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async =>
      puzzle;
}

class _RecordingCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  final List<CompletedSudokuEntry> entries = <CompletedSudokuEntry>[];

  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async => entries;
}
