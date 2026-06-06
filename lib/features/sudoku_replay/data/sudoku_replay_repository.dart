import '../domain/sudoku_replay.dart';
import '../domain/sudoku_replay_details.dart';
import '../domain/sudoku_replay_draft.dart';
import '../domain/sudoku_replay_round_key.dart';

abstract class SudokuReplayRepository {
  Future<SudokuReplay> createReplay(SudokuReplayDraft draft);

  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key);

  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  });

  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  });

  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  });

  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  });

  Future<SudokuReplayDetails?> getReplayDetails(int replayId);
}
