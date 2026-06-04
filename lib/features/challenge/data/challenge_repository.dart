import '../../sudoku/domain/sudoku_difficulty.dart';
import '../domain/challenge_month_data.dart';
import '../domain/challenge_round_data.dart';

abstract class ChallengeRepository {
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  });

  Future<ChallengeRoundData> loadOrCreateRoundData({
    required DateTime date,
    required SudokuDifficulty difficulty,
  });

  Future<void> saveChallengeProgress({
    required DateTime date,
    required SudokuDifficulty difficulty,
    required int sudokuId,
    required String currentGrid,
    required bool isCompleted,
  });

  Future<DateTime?> loadLastPlayedMonth();

  Future<void> saveLastPlayedMonth(DateTime month);
}
