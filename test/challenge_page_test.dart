import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/challenge/data/challenge_repository.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_day_entry.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_day_status.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_month_data.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_round_data.dart';
import 'package:hello_world_app/features/challenge/presentation/challenge_page.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';

void main() {
  testWidgets(
    'challenge page shows play and resume CTA based on selected day',
    (WidgetTester tester) async {
      final _ChallengePageRepository repository = _ChallengePageRepository();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengePage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);

      await tester.tap(find.byKey(const Key('challenge-day-2026-6-2')));
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);
    },
  );
}

class _ChallengePageRepository implements ChallengeRepository {
  @override
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  }) async {
    final DateTime normalizedMonth = DateTime(2026, 6);
    final DateTime displayStart = normalizedMonth.subtract(
      Duration(days: normalizedMonth.weekday - DateTime.monday),
    );
    return ChallengeMonthData(
      month: normalizedMonth,
      entries: List<ChallengeDayEntry>.generate(42, (int index) {
        final DateTime date = displayStart.add(Duration(days: index));
        return ChallengeDayEntry(
          date: date,
          isInCurrentMonth: date.month == normalizedMonth.month,
          status:
              date.day == 2
                  ? ChallengeDayStatus.inProgress
                  : ChallengeDayStatus.notStarted,
        );
      }),
    );
  }

  @override
  Future<DateTime?> loadLastPlayedMonth() async => DateTime(2026, 6);

  @override
  Future<ChallengeRoundData> loadOrCreateRoundData({
    required DateTime date,
    required SudokuDifficulty difficulty,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveChallengeProgress({
    required DateTime date,
    required SudokuDifficulty difficulty,
    required int sudokuId,
    required String currentGrid,
    required bool isCompleted,
  }) async {}

  @override
  Future<void> saveLastPlayedMonth(DateTime month) async {}
}
