import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
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

    expect(find.text('90° Modifier'), findsOneWidget);
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
      await tester.pump();

      expect(find.text('90° Modifier'), findsOneWidget);

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
}

class _FakeRepository implements SudokuPuzzleRepository {
  @override
  Future<String> loadPuzzle(SudokuDifficulty difficulty) async {
    return '500000307'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000';
  }
}

class _PredictableRandom extends Random {
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
