import 'dart:async';

import 'package:flutter/material.dart';

import '../../sudoku/domain/sudoku_grid_parser.dart';
import '../../sudoku/presentation/modifiers/models/flying_goat.dart';
import '../../sudoku/presentation/widgets/sudoku_grid.dart';
import '../application/sudoku_replay_speed.dart';
import '../data/local_sudoku_replay_repository.dart';
import '../data/sudoku_replay_repository.dart';
import '../domain/sudoku_replay_details.dart';
import '../domain/sudoku_replay_move.dart';

class CompletedSudokuReplayPage extends StatefulWidget {
  const CompletedSudokuReplayPage({
    required this.replayId,
    this.repository,
    super.key,
  });

  final int replayId;
  final SudokuReplayRepository? repository;

  @override
  State<CompletedSudokuReplayPage> createState() =>
      _CompletedSudokuReplayPageState();
}

class _CompletedSudokuReplayPageState extends State<CompletedSudokuReplayPage>
    with TickerProviderStateMixin {
  static final List<List<int?>> _emptyCellNotes = List<List<int?>>.generate(
    9,
    (_) => List<int?>.filled(9, null),
    growable: false,
  );

  late final SudokuReplayRepository _repository =
      widget.repository ?? LocalSudokuReplayRepository();
  late final AnimationController _rotationController = AnimationController(
    vsync: this,
  );
  late final AnimationController _rotation90Controller = AnimationController(
    vsync: this,
  );
  late final AnimationController _textRotationController = AnimationController(
    vsync: this,
  );
  late final AnimationController _splitController = AnimationController(
    vsync: this,
  );

  SudokuReplayDetails? _details;
  SudokuGridData? _gridData;
  Object? _error;
  bool _isPlaying = false;
  bool _resumeAfterDrag = false;
  double _speed = sudokuReplaySpeeds.first;
  int _playheadMillis = 0;
  Timer? _timer;
  DateTime? _lastTickAt;

  @override
  void initState() {
    super.initState();
    _loadReplay();
  }

  Future<void> _loadReplay() async {
    try {
      final SudokuReplayDetails? details = await _repository.getReplayDetails(
        widget.replayId,
      );
      if (!mounted) {
        return;
      }
      if (details == null) {
        setState(() {
          _error = StateError('Replay not found.');
        });
        return;
      }
      final SudokuGridData gridData = parsePuzzle(details.replay.puzzleString);
      _applyMovesToGrid(
        gridData: gridData,
        moves: details.moves,
        playheadMillis: 0,
      );
      setState(() {
        _details = details;
        _gridData = gridData;
        _playheadMillis = 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    _rotation90Controller.dispose();
    _textRotationController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SudokuReplayDetails? details = _details;
    final SudokuGridData? gridData = _gridData;

    return Scaffold(
      appBar: AppBar(title: const Text('Replay')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (BuildContext context) {
              if (_error != null) {
                return Center(
                  child: Text(
                    'Replay konnte nicht geladen werden: $_error',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (details == null || gridData == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final int totalMillis = details.replay.playedDurationMillis;
              return Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: SudokuGrid(
                            gridData: gridData,
                            cellNotes: _emptyCellNotes,
                            activeValue: 0,
                            activeModifier: null,
                            gridShakeOffset: Offset.zero,
                            quarterTurns: 0,
                            rotationController: _rotationController,
                            rotation90Controller: _rotation90Controller,
                            textRotationController: _textRotationController,
                            splitController: _splitController,
                            splitMaxOffsetPx: 0,
                            textRotationDirections: const <int, int>{},
                            flyingGoats: const <FlyingGoat>[],
                            goatAssetPath: '',
                            onCellTapped: (_, _) {},
                            onViewportChanged: (_) {},
                            interactionEnabled: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_formatDuration(_playheadMillis)} / ${_formatDuration(totalMillis)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value:
                        totalMillis == 0
                            ? 0
                            : _playheadMillis.clamp(0, totalMillis).toDouble(),
                    max: totalMillis == 0 ? 1 : totalMillis.toDouble(),
                    onChangeStart: (_) {
                      _resumeAfterDrag = _isPlaying;
                      _setPlaying(false);
                    },
                    onChanged: (double value) {
                      _seekTo(value.round());
                    },
                    onChangeEnd: (_) {
                      if (_resumeAfterDrag) {
                        _setPlaying(true);
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _setPlaying(!_isPlaying),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Pause' : 'Play'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _speed = nextSudokuReplaySpeed(_speed);
                          });
                        },
                        child: Text('${_speed.toInt()}x'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _setPlaying(bool value) {
    final SudokuReplayDetails? details = _details;
    if (details == null) {
      return;
    }
    final bool shouldPlay =
        value && details.replay.playedDurationMillis > _playheadMillis;
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
    setState(() {
      _isPlaying = shouldPlay;
    });
    if (!shouldPlay) {
      return;
    }
    _lastTickAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final DateTime now = DateTime.now();
      final DateTime? lastTickAt = _lastTickAt;
      _lastTickAt = now;
      if (lastTickAt == null) {
        return;
      }
      final int deltaMillis =
          (now.difference(lastTickAt).inMilliseconds * _speed).round();
      _seekTo(_playheadMillis + deltaMillis, keepPlaying: true);
    });
  }

  void _seekTo(int playheadMillis, {bool keepPlaying = false}) {
    final SudokuReplayDetails? details = _details;
    final SudokuGridData? gridData = _gridData;
    if (details == null || gridData == null) {
      return;
    }
    final int totalMillis = details.replay.playedDurationMillis;
    final int nextPlayhead = playheadMillis.clamp(0, totalMillis);
    _applyMovesToGrid(
      gridData: gridData,
      moves: details.moves,
      playheadMillis: nextPlayhead,
    );
    final bool reachedEnd = nextPlayhead >= totalMillis;
    setState(() {
      _playheadMillis = nextPlayhead;
      _isPlaying = keepPlaying && !reachedEnd;
    });
    if (reachedEnd) {
      _timer?.cancel();
      _timer = null;
      _lastTickAt = null;
    }
  }

  void _applyMovesToGrid({
    required SudokuGridData gridData,
    required List<SudokuReplayMove> moves,
    required int playheadMillis,
  }) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        gridData.currentGrid[row][col] = gridData.initialGrid[row][col];
      }
    }
    for (final SudokuReplayMove move in moves) {
      if (move.elapsedMillis > playheadMillis) {
        break;
      }
      gridData.currentGrid[move.cellRow][move.cellCol] = move.nextValue;
    }
  }

  String _formatDuration(int millis) {
    final Duration duration = Duration(milliseconds: millis);
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
