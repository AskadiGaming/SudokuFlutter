import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/challenge/data/challenge_repository.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_month_data.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_round_data.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_mode.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';

void main() {
  testWidgets('challenge round loads saved progress and autosaves edits', (
    WidgetTester tester,
  ) async {
    final _TrackingChallengeRepository repository =
        _TrackingChallengeRepository(
          roundData: ChallengeRoundData(
            date: DateTime(2026, 6, 4),
            difficulty: SudokuDifficulty.easy,
            sudokuId: 7,
            puzzleString:
                '500000307'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000',
            currentGridString:
                '500000307'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000'
                '000000000',
            isCompleted: false,
            startedAt: DateTime(2026, 6, 4, 9),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            mode: SudokuRoundMode.challenge,
            challengeDate: DateTime(2026, 6, 4),
          ),
          repository: _UnusedSudokuRepository(),
          challengeRepository: repository,
          adminTestOverrideEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('number-button-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sudoku-cell-0-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(repository.saveCalls, 1);
    expect(repository.lastSavedGrid![1], '3');
    expect(repository.lastCompletedFlag, isFalse);
  });

  testWidgets('completed challenge shows back to calendar CTA', (
    WidgetTester tester,
  ) async {
    final _TrackingChallengeRepository repository =
        _TrackingChallengeRepository(
          roundData: ChallengeRoundData(
            date: DateTime(2026, 6, 4),
            difficulty: SudokuDifficulty.easy,
            sudokuId: 7,
            puzzleString:
                '534678912'
                '672195348'
                '198342567'
                '859761423'
                '426853791'
                '713924856'
                '961537284'
                '287419635'
                '345286179',
            currentGridString:
                '534678912'
                '672195348'
                '198342567'
                '859761423'
                '426853791'
                '713924856'
                '961537284'
                '287419635'
                '345286179',
            isCompleted: true,
            startedAt: DateTime(2026, 6, 4, 9),
            completedAt: DateTime(2026, 6, 4, 9, 12),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            mode: SudokuRoundMode.challenge,
            challengeDate: DateTime(2026, 6, 4),
          ),
          repository: _UnusedSudokuRepository(),
          challengeRepository: repository,
          adminTestOverrideEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Back to calendar'), findsOneWidget);
  });
}

class _TrackingChallengeRepository implements ChallengeRepository {
  _TrackingChallengeRepository({required this.roundData});

  final ChallengeRoundData roundData;
  int saveCalls = 0;
  String? lastSavedGrid;
  bool? lastCompletedFlag;

  @override
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> loadLastPlayedMonth() async => null;

  @override
  Future<ChallengeRoundData> loadOrCreateRoundData({
    required DateTime date,
    required SudokuDifficulty difficulty,
  }) async {
    return roundData;
  }

  @override
  Future<void> saveChallengeProgress({
    required DateTime date,
    required SudokuDifficulty difficulty,
    required int sudokuId,
    required String currentGrid,
    required bool isCompleted,
  }) async {
    saveCalls++;
    lastSavedGrid = currentGrid;
    lastCompletedFlag = isCompleted;
  }

  @override
  Future<void> saveLastPlayedMonth(DateTime month) async {}
}

class _UnusedSudokuRepository implements SudokuPuzzleRepository {
  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) {
    throw UnimplementedError();
  }

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) {
    throw UnimplementedError();
  }
}
