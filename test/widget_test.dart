import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/admin_test_sudoku_config.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';

void main() {
  testWidgets('number selector keeps exactly one active button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    ToggleButtons buttons = tester.widget(find.byType(ToggleButtons));
    expect(buttons.isSelected.where((bool item) => item).length, 1);
    expect(buttons.isSelected[0], isTrue);

    await tester.tap(find.byKey(const Key('number-button-3')));
    await tester.pumpAndSettle();

    buttons = tester.widget(find.byType(ToggleButtons));
    expect(buttons.isSelected.where((bool item) => item).length, 1);
    expect(buttons.isSelected[2], isTrue);

    await tester.tap(find.byKey(const Key('number-button-delete')));
    await tester.pumpAndSettle();

    buttons = tester.widget(find.byType(ToggleButtons));
    expect(buttons.isSelected.where((bool item) => item).length, 1);
    expect(buttons.isSelected[9], isTrue);
  });

  testWidgets(
    'select number and tap editable cell writes value and highlights',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlaySudokuPage(
            roundConfig: const SudokuRoundConfig(
              difficulty: SudokuDifficulty.easy,
            ),
            repository: _FakeRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('number-button-3')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
      await tester.pumpAndSettle();

      final Container editableCell = tester.widget<Container>(
        find.byKey(const Key('sudoku-cell-0-1')).first,
      );
      final Container fixedHighlightedCell = tester.widget<Container>(
        find.byKey(const Key('sudoku-cell-0-6')).first,
      );

      final BoxDecoration editableDecoration =
          editableCell.decoration! as BoxDecoration;
      final BoxDecoration fixedDecoration =
          fixedHighlightedCell.decoration! as BoxDecoration;

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-0-1')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-0-6')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(editableDecoration.color, fixedDecoration.color);

      await tester.tap(find.byKey(const Key('sudoku-cell-0-0')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-0-0')),
          matching: find.text('5'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('delete button clears editable cell but not fixed cell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('number-button-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-1')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('number-button-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-1')),
        matching: find.text('3'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('sudoku-cell-0-0')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows modifier banner when crazy mode is enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            crazyModeEnabled: true,
          ),
          repository: _FakeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('modifier-banner')), findsOneWidget);
  });

  testWidgets('provides localization for 90 modifier title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return Text(l10n.modifier90Title);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('90'), findsOneWidget);
  });

  testWidgets('provides localization for goat modifier title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return Text(l10n.modifierGoatTitle);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goat Modifier'), findsOneWidget);
  });

  testWidgets('provides localization for text rotation modifier title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return Text(l10n.modifierTextRotationTitle);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Text Rotation Modifier'), findsOneWidget);
  });

  testWidgets(
    '90 modifier keeps input interactive and commits rotated values',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaySudokuPage(
            roundConfig: const SudokuRoundConfig(
              difficulty: SudokuDifficulty.easy,
              crazyModeEnabled: true,
            ),
            repository: _FakeRepository(),
            random: _PredictableRandom(<int>[0, 2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.textContaining('90'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-0-1')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 8));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-1-8')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('goat modifier renders overlay and clears after end', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            crazyModeEnabled: true,
          ),
          repository: _FakeRepository(),
          random: _PredictableRandom(<int>[0, 3, 0, 0, 1, 500000, 0, 500000]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Goat Modifier'), findsOneWidget);
    expect(find.byKey(const Key('goat-overlay')), findsOneWidget);
    expect(find.byKey(const Key('goat-0-leftToRight')), findsOneWidget);
    expect(find.byKey(const Key('goat-image-0')), findsOneWidget);

    final SizedBox goatBox = tester.widget<SizedBox>(
      find.byKey(const Key('goat-0-leftToRight')),
    );
    expect(goatBox.width, isNotNull);
    expect(goatBox.width!, greaterThanOrEqualTo(64));
    expect(goatBox.width!, lessThanOrEqualTo(128));

    final Image goatImage = tester.widget<Image>(
      find.byKey(const Key('goat-image-0')),
    );
    final AssetImage provider = goatImage.image as AssetImage;
    expect(provider.assetName, 'assets/images/modifiers/goat.png');

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Goat Modifier'), findsNothing);
    expect(find.byKey(const Key('goat-image-0')), findsNothing);
  });

  testWidgets('text rotation modifier keeps input interactive', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            crazyModeEnabled: true,
          ),
          repository: _FakeRepository(),
          random: _PredictableRandom(<int>[0, 4, 1, 0]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.text('Text Rotation Modifier'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('active and valid admin override is used before repository', (
    WidgetTester tester,
  ) async {
    final _TrackingRepository repository = _TrackingRepository(
      randomPuzzle: _FakeRepository._puzzle,
      dailyPuzzle: _FakeRepository._puzzle,
    );
    const AdminTestSudokuConfig config = AdminTestSudokuConfig(
      enabled: true,
      sudokuString:
          '100000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: repository,
          adminTestOverrideConfig: config,
          adminTestOverrideEnabled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.randomCalls, 0);
    expect(repository.dailyCalls, 0);
    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('invalid active admin override falls back to repository', (
    WidgetTester tester,
  ) async {
    final _TrackingRepository repository = _TrackingRepository(
      randomPuzzle: _FakeRepository._puzzle,
      dailyPuzzle: _FakeRepository._puzzle,
    );
    const AdminTestSudokuConfig config = AdminTestSudokuConfig(
      enabled: true,
      sudokuString: '123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: repository,
          adminTestOverrideConfig: config,
          adminTestOverrideEnabled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.randomCalls, 1);
    expect(repository.dailyCalls, 0);
    expect(
      find.descendant(
        of: find.byKey(const Key('sudoku-cell-0-0')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('inactive admin override keeps normal repository behavior', (
    WidgetTester tester,
  ) async {
    final _TrackingRepository repository = _TrackingRepository(
      randomPuzzle: _FakeRepository._puzzle,
      dailyPuzzle: _FakeRepository._puzzle,
    );
    const AdminTestSudokuConfig config = AdminTestSudokuConfig(
      enabled: false,
      sudokuString:
          '100000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000'
          '000000000',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: repository,
          adminTestOverrideConfig: config,
          adminTestOverrideEnabled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.randomCalls, 1);
    expect(repository.dailyCalls, 0);
  });
}

class _FakeRepository implements SudokuPuzzleRepository {
  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async {
    return _puzzle;
  }

  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async {
    return _puzzle;
  }

  static const String _puzzle =
      '500000307'
      '000000000'
      '000000000'
      '000000000'
      '000000000'
      '000000000'
      '000000000'
      '000000000'
      '000000000';
}

class _PredictableRandom implements Random {
  _PredictableRandom(this.values);

  final List<int> values;
  int _index = 0;

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1000000) / 1000000;

  @override
  int nextInt(int max) {
    final int raw = _index < values.length ? values[_index++] : 0;
    return raw % max;
  }
}

class _TrackingRepository implements SudokuPuzzleRepository {
  _TrackingRepository({required this.randomPuzzle, required this.dailyPuzzle});

  final String randomPuzzle;
  final String dailyPuzzle;
  int randomCalls = 0;
  int dailyCalls = 0;

  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async {
    dailyCalls += 1;
    return dailyPuzzle;
  }

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async {
    randomCalls += 1;
    return randomPuzzle;
  }
}
