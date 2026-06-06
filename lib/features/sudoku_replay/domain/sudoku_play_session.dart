class SudokuPlaySession {
  const SudokuPlaySession({
    required this.id,
    required this.replayId,
    required this.sessionIndex,
    required this.startedAt,
    required this.activeDurationMillis,
    this.endedAt,
  });

  final int id;
  final int replayId;
  final int sessionIndex;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int activeDurationMillis;
}
