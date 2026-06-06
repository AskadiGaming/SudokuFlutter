class SudokuReplayMove {
  const SudokuReplayMove({
    required this.id,
    required this.replayId,
    required this.sequence,
    required this.cellRow,
    required this.cellCol,
    required this.previousValue,
    required this.nextValue,
    required this.elapsedMillis,
  });

  final int id;
  final int replayId;
  final int sequence;
  final int cellRow;
  final int cellCol;
  final int previousValue;
  final int nextValue;
  final int elapsedMillis;
}
