import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/challenge/application/challenge_controller.dart';
import 'package:hello_world_app/features/challenge/data/challenge_repository.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_day_entry.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_day_status.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_month_data.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_round_data.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';

void main() {
  test(
    'initialize uses last played month and loads matching selection',
    () async {
      final _FakeChallengeRepository repository = _FakeChallengeRepository(
        lastPlayedMonth: DateTime(2026, 4),
      );
      final ChallengeController controller = ChallengeController(
        repository: repository,
        today: DateTime(2026, 6, 4),
      );

      await controller.initialize();

      expect(controller.visibleMonth, DateTime(2026, 4));
      expect(controller.selectedDate, DateTime(2026, 4, 1));
      expect(repository.loadedMonths, <DateTime>[DateTime(2026, 4)]);
    },
  );

  test('selectDifficulty refreshes month data with new difficulty', () async {
    final _FakeChallengeRepository repository = _FakeChallengeRepository();
    final ChallengeController controller = ChallengeController(
      repository: repository,
      today: DateTime(2026, 6, 4),
    );

    await controller.initialize();
    await controller.selectDifficulty(SudokuDifficulty.hard);

    expect(controller.selectedDifficulty, SudokuDifficulty.hard);
    expect(repository.loadedDifficulties.last, SudokuDifficulty.hard);
  });
}

class _FakeChallengeRepository implements ChallengeRepository {
  _FakeChallengeRepository({this.lastPlayedMonth});

  final DateTime? lastPlayedMonth;
  final List<DateTime> loadedMonths = <DateTime>[];
  final List<SudokuDifficulty> loadedDifficulties = <SudokuDifficulty>[];

  @override
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  }) async {
    loadedMonths.add(DateTime(month.year, month.month));
    loadedDifficulties.add(difficulty);

    final DateTime displayStart = month.subtract(
      Duration(days: month.weekday - DateTime.monday),
    );
    final List<ChallengeDayEntry> entries = List<ChallengeDayEntry>.generate(
      42,
      (int index) {
        final DateTime date = displayStart.add(Duration(days: index));
        final ChallengeDayStatus status =
            date.day == 2
                ? ChallengeDayStatus.inProgress
                : ChallengeDayStatus.notStarted;
        return ChallengeDayEntry(
          date: date,
          isInCurrentMonth: date.month == month.month,
          status: status,
        );
      },
    );

    return ChallengeMonthData(month: month, entries: entries);
  }

  @override
  Future<DateTime?> loadLastPlayedMonth() async => lastPlayedMonth;

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
