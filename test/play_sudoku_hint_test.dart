import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/ads/application/ad_service.dart';
import 'package:hello_world_app/features/ads/application/analytics_service.dart';
import 'package:hello_world_app/features/ads/application/show_ad_for_hint_use_case.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';

void main() {
  testWidgets('hint fills first incorrect editable cell and highlights it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '004678912672195348198342567859761423426853791713924856961537284287419635345286179',
          ),
          showAdForHintUseCase: ShowAdForHintUseCase(
            adService: _FakeAdService(
              supportsCurrentPlatform: true,
              showResult: AdShowResult.shown,
            ),
            analyticsService: _FakeAnalyticsService(),
          ),
          adminTestOverrideEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sudoku-hint-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sudoku-hint-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-1')),
        matching: find.text('3'),
      ),
      findsNothing,
    );

    final Container highlightedCell = tester.widget<Container>(
      find.byKey(const Key('sudoku-cell-0-0')).first,
    );
    final BoxDecoration highlightedDecoration =
        highlightedCell.decoration! as BoxDecoration;
    final ThemeData theme = Theme.of(
      tester.element(find.byType(PlaySudokuPage)),
    );
    expect(highlightedDecoration.color, theme.colorScheme.errorContainer);
    expect(highlightedDecoration.border, isNotNull);
    expect(
      (highlightedDecoration.border! as Border).top.color,
      theme.colorScheme.error,
    );

    final Text highlightedText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('5'),
      ),
    );
    expect(highlightedText.style?.color, theme.colorScheme.error);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    final Container normalCell = tester.widget<Container>(
      find.byKey(const Key('sudoku-cell-0-0')).first,
    );
    final BoxDecoration normalDecoration =
        normalCell.decoration! as BoxDecoration;
    expect(normalDecoration.color, isNot(theme.colorScheme.errorContainer));
  });

  testWidgets('hint does not change grid when ad is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '004678912672195348198342567859761423426853791713924856961537284287419635345286179',
          ),
          showAdForHintUseCase: ShowAdForHintUseCase(
            adService: _FakeAdService(
              supportsCurrentPlatform: true,
              showResult: AdShowResult.skipped,
            ),
            analyticsService: _FakeAnalyticsService(),
          ),
          adminTestOverrideEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sudoku-hint-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('5'),
      ),
      findsNothing,
    );
    expect(
      find.text('Gerade ist kein Hinweis-Werbespot verfuegbar.'),
      findsOneWidget,
    );
  });

  testWidgets('grid stays interactive while hint highlight is visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '004678912672195348198342567859761423426853791713924856961537284287419635345286179',
          ),
          showAdForHintUseCase: ShowAdForHintUseCase(
            adService: _FakeAdService(
              supportsCurrentPlatform: true,
              showResult: AdShowResult.shown,
            ),
            analyticsService: _FakeAnalyticsService(),
          ),
          adminTestOverrideEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sudoku-hint-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('number-button-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    final ToggleButtons buttons = tester.widget<ToggleButtons>(
      find.byKey(const Key('number-toggle-buttons')),
    );
    expect(buttons.onPressed, isNotNull);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
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

class _FakeAdService implements AdService {
  _FakeAdService({
    required this.supportsCurrentPlatform,
    required this.showResult,
  });

  @override
  final bool supportsCurrentPlatform;
  final AdShowResult showResult;

  @override
  Future<void> initialize() async {}

  @override
  Future<AdShowResult> showInterstitialAndWait({
    required Duration loadTimeout,
  }) async {
    return showResult;
  }
}

class _FakeAnalyticsService implements AnalyticsService {
  @override
  void logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) {}
}
