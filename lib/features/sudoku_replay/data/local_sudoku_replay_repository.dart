import '../domain/sudoku_replay.dart';
import '../domain/sudoku_replay_details.dart';
import '../domain/sudoku_replay_draft.dart';
import '../domain/sudoku_replay_round_key.dart';
import 'sudoku_replay_local_data_source.dart';
import 'sudoku_replay_repository.dart';

class LocalSudokuReplayRepository implements SudokuReplayRepository {
  LocalSudokuReplayRepository({
    SudokuReplayLocalDataSource? localDataSource,
  }) : _localDataSource = localDataSource ?? SudokuReplayLocalDataSource();

  final SudokuReplayLocalDataSource _localDataSource;

  @override
  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  }) {
    return _localDataSource.addMove(
      replayId: replayId,
      sequence: sequence,
      cellRow: cellRow,
      cellCol: cellCol,
      previousValue: previousValue,
      nextValue: nextValue,
      elapsedMillis: elapsedMillis,
    );
  }

  @override
  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  }) {
    return _localDataSource.completeReplay(
      replayId: replayId,
      finalGridString: finalGridString,
      playedDurationMillis: playedDurationMillis,
      completedAt: completedAt,
    );
  }

  @override
  Future<SudokuReplay> createReplay(SudokuReplayDraft draft) {
    return _localDataSource.createReplay(draft);
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  }) {
    return _localDataSource.endSession(
      sessionId: sessionId,
      endedAt: endedAt,
      activeDurationMillis: activeDurationMillis,
    );
  }

  @override
  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key) {
    return _localDataSource.findOpenReplay(key);
  }

  @override
  Future<SudokuReplayDetails?> getReplayDetails(int replayId) {
    return _localDataSource.getReplayDetails(replayId);
  }

  @override
  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  }) {
    return _localDataSource.startSession(
      replayId: replayId,
      sessionIndex: sessionIndex,
      startedAt: startedAt,
    );
  }
}
