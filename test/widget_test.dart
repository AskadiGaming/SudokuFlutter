import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';

void main() {
  testWidgets('number selector keeps exactly one active button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          difficulty: SudokuDifficulty.easy,
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
            difficulty: SudokuDifficulty.easy,
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
          difficulty: SudokuDifficulty.easy,
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
