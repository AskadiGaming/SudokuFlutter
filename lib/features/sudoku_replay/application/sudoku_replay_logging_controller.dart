import '../data/sudoku_replay_repository.dart';
import '../domain/sudoku_replay.dart';
import '../domain/sudoku_replay_draft.dart';
import '../domain/sudoku_replay_round_key.dart';

class SudokuReplayLoggingController {
  SudokuReplayLoggingController({required SudokuReplayRepository repository})
    : _repository = repository;

  final SudokuReplayRepository _repository;

  SudokuReplay? _replay;
  int? _activeSessionId;
  int _nextMoveSequence = 0;
  int _nextSessionIndex = 0;
  int _completedSessionMillis = 0;
  DateTime? _activeSessionStartedAt;
  Future<void> _writeQueue = Future<void>.value();

  int? get replayId => _replay?.id;

  Future<void> initialize({
    required SudokuReplayDraft draft,
    required bool allowResume,
    required SudokuReplayRoundKey roundKey,
  }) async {
    final SudokuReplay? existingReplay =
        allowResume ? await _repository.findOpenReplay(roundKey) : null;
    _replay = existingReplay ?? await _repository.createReplay(draft);
    final replay = _replay!;
    final details = await _repository.getReplayDetails(replay.id);
    _nextMoveSequence = details?.moves.length ?? 0;
    _nextSessionIndex = details?.sessions.length ?? 0;
    _completedSessionMillis =
        details?.sessions.fold<int>(
          0,
          (int sum, session) => sum + session.activeDurationMillis,
        ) ??
        replay.playedDurationMillis;
  }

  Future<void> startSession(DateTime startedAt) async {
    final SudokuReplay? replay = _replay;
    if (replay == null || _activeSessionId != null) {
      return;
    }
    _activeSessionStartedAt = startedAt;
    final int sessionIndex = _nextSessionIndex++;
    _activeSessionId = await _repository.startSession(
      replayId: replay.id,
      sessionIndex: sessionIndex,
      startedAt: startedAt,
    );
  }

  Future<void> pauseSession(DateTime endedAt) async {
    final int? sessionId = _activeSessionId;
    final DateTime? startedAt = _activeSessionStartedAt;
    if (sessionId == null || startedAt == null) {
      return;
    }
    final int durationMillis = endedAt
        .difference(startedAt)
        .inMilliseconds
        .clamp(0, 1 << 31);
    _activeSessionId = null;
    _activeSessionStartedAt = null;
    _completedSessionMillis += durationMillis;
    await _enqueueWrite(
      () => _repository.endSession(
        sessionId: sessionId,
        endedAt: endedAt,
        activeDurationMillis: durationMillis,
      ),
    );
  }

  int currentElapsedMillis(DateTime now) {
    final DateTime? startedAt = _activeSessionStartedAt;
    if (startedAt == null) {
      return _completedSessionMillis;
    }
    return _completedSessionMillis +
        now.difference(startedAt).inMilliseconds.clamp(0, 1 << 31);
  }

  Future<void> logMove({
    required int row,
    required int col,
    required int previousValue,
    required int nextValue,
    required DateTime at,
  }) async {
    final SudokuReplay? replay = _replay;
    if (replay == null) {
      return;
    }
    final int sequence = _nextMoveSequence++;
    final int elapsedMillis = currentElapsedMillis(at);
    await _enqueueWrite(
      () => _repository.addMove(
        replayId: replay.id,
        sequence: sequence,
        cellRow: row,
        cellCol: col,
        previousValue: previousValue,
        nextValue: nextValue,
        elapsedMillis: elapsedMillis,
      ),
    );
  }

  Future<void> complete({
    required String finalGridString,
    required DateTime completedAt,
  }) async {
    final SudokuReplay? replay = _replay;
    if (replay == null) {
      return;
    }
    await pauseSession(completedAt);
    await _enqueueWrite(
      () => _repository.completeReplay(
        replayId: replay.id,
        finalGridString: finalGridString,
        playedDurationMillis: _completedSessionMillis,
        completedAt: completedAt,
      ),
    );
    await flush();
  }

  Future<void> flush() async {
    await _writeQueue;
  }

  Future<void> _enqueueWrite(Future<void> Function() operation) {
    _writeQueue = _writeQueue.then((_) => operation());
    return _writeQueue;
  }
}
