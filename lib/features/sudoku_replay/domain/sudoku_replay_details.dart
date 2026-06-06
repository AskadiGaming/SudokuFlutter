import 'sudoku_play_session.dart';
import 'sudoku_replay.dart';
import 'sudoku_replay_move.dart';

class SudokuReplayDetails {
  const SudokuReplayDetails({
    required this.replay,
    required this.moves,
    required this.sessions,
  });

  final SudokuReplay replay;
  final List<SudokuReplayMove> moves;
  final List<SudokuPlaySession> sessions;
}
