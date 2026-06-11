import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';
import 'package:hello_world_app/features/sudoku/presentation/widgets/number_pad.dart';

void main() {
  testWidgets('number pad keeps slot positions when a value is hidden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SudokuNumberPad(
              activeValue: 1,
              hiddenValues: const <int>{3},
              onValueSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('number-button-3')), findsNothing);
    expect(find.byKey(const Key('number-button-gap-3')), findsOneWidget);
    expect(find.byKey(const Key('number-button-slot-3')), findsOneWidget);

    final double slot2X =
        tester.getTopLeft(find.byKey(const Key('number-button-slot-2'))).dx;
    final double slot3X =
        tester.getTopLeft(find.byKey(const Key('number-button-slot-3'))).dx;
    final double slot4X =
        tester.getTopLeft(find.byKey(const Key('number-button-slot-4'))).dx;

    expect(slot2X, lessThan(slot3X));
    expect(slot3X, lessThan(slot4X));
  });

  testWidgets('button hides at nine occurrences and reappears after delete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _NineSameNumbersRepository(),
          adminTestOverrideEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('number-button-1')), findsOneWidget);
    expect(find.byKey(const Key('number-button-1-selected')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sudoku-cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('number-button-1')), findsNothing);
    expect(find.byKey(const Key('number-button-gap-1')), findsOneWidget);
    expect(find.byKey(const Key('number-button-2-selected')), findsOneWidget);

    await tester.tap(find.byKey(const Key('number-button-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sudoku-cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('number-button-1')), findsOneWidget);
    expect(find.byKey(const Key('number-button-gap-1')), findsNothing);
  });
}

class _NineSameNumbersRepository implements SudokuPuzzleRepository {
  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async => _puzzle;

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async =>
      _puzzle;

  static const String _puzzle =
      '023456789'
      '456789103'
      '789123456'
      '214365897'
      '365897214'
      '897214365'
      '531642978'
      '642978531'
      '978531642';
}
