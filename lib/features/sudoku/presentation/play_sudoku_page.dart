import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../ads/application/show_ad_for_hint_use_case.dart';
import '../../ads/infrastructure/debug_analytics_service.dart';
import '../../ads/infrastructure/unity_ads_config.dart';
import '../../ads/infrastructure/unity_ads_service.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../challenge/data/local_challenge_repository.dart';
import '../../challenge/domain/challenge_round_data.dart';
import '../../sudoku_history/data/completed_sudoku_log_repository.dart';
import '../../sudoku_history/data/local_completed_sudoku_log_repository.dart';
import '../../sudoku_history/domain/completed_sudoku_entry.dart';
import '../../sudoku_history/domain/completed_sudoku_mode.dart';
import '../../sudoku_replay/application/sudoku_replay_logging_controller.dart';
import '../../sudoku_replay/data/local_sudoku_replay_repository.dart';
import '../../sudoku_replay/data/sudoku_replay_repository.dart';
import '../../sudoku_replay/domain/sudoku_play_session.dart';
import '../../sudoku_replay/domain/sudoku_replay.dart';
import '../../sudoku_replay/domain/sudoku_replay_draft.dart';
import '../../sudoku_replay/domain/sudoku_replay_details.dart';
import '../../sudoku_replay/domain/sudoku_replay_move.dart';
import '../../sudoku_replay/domain/sudoku_replay_round_key.dart';
import '../data/local_sudoku_puzzle_repository.dart';
import '../data/sudoku_puzzle_repository.dart';
import '../dev/admin_sudoku_flags.dart';
import '../dev/admin_test_sudoku_override.dart';
import '../domain/admin_test_sudoku_config.dart';
import '../domain/default_sudoku_modifier_config.dart';
import '../domain/sudoku_difficulty.dart';
import '../domain/sudoku_finish_logic.dart';
import '../domain/sudoku_grid_parser.dart';
import '../domain/sudoku_modifier_config.dart';
import '../domain/sudoku_number_availability.dart';
import '../domain/sudoku_modifier_type.dart';
import '../domain/sudoku_round_config.dart';
import '../domain/sudoku_round_mode.dart';
import 'modifiers/core/sudoku_modifier_context.dart';
import 'modifiers/core/sudoku_modifier_factory.dart';
import 'modifiers/core/sudoku_modifier_registry.dart';
import 'modifiers/core/sudoku_modifier_scheduler.dart';
import 'modifiers/models/flying_goat.dart';
import 'modifiers/models/rain_drop.dart';
import 'modifiers/widgets/rain_overlay.dart';
import 'widgets/modifier_banner.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_round_timer.dart';
import 'widgets/sudoku_grid.dart';

class PlaySudokuPage extends StatefulWidget {
  const PlaySudokuPage({
    required this.roundConfig,
    this.onReplayRoundRequested,
    this.repository,
    this.challengeRepository,
    this.completedSudokuLogRepository,
    this.replayRepository,
    this.adminTestOverrideConfig,
    this.adminTestOverrideEnabled,
    this.adminSolveButtonEnabled,
    this.showAdForHintUseCase,
    this.random,
    super.key,
  });

  final SudokuRoundConfig roundConfig;
  final Future<void> Function(
    BuildContext context,
    SudokuRoundConfig roundConfig,
  )?
  onReplayRoundRequested;
  final SudokuPuzzleRepository? repository;
  final ChallengeRepository? challengeRepository;
  final CompletedSudokuLogRepository? completedSudokuLogRepository;
  final SudokuReplayRepository? replayRepository;
  final AdminTestSudokuConfig? adminTestOverrideConfig;
  final bool? adminTestOverrideEnabled;
  final bool? adminSolveButtonEnabled;
  final ShowAdForHintUseCase? showAdForHintUseCase;
  final Random? random;

  @override
  State<PlaySudokuPage> createState() => _PlaySudokuPageState();
}

class _PlaySudokuPageState extends State<PlaySudokuPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _goatAssetPath = 'assets/images/modifiers/goat.png';
  static const Duration _finishStepDelay = Duration(milliseconds: 45);
  static const Duration _hintHighlightDuration = Duration(seconds: 5);
  static const Duration _roundClockTick = Duration(seconds: 1);
  static const double _roundTimerReservedHeight = 20;
  static final List<int> _spiralOrder = buildSpiralOrder9x9();

  late final SudokuPuzzleRepository _repository =
      widget.repository ?? LocalSudokuPuzzleRepository();
  late final ChallengeRepository _challengeRepository =
      widget.challengeRepository ?? LocalChallengeRepository();
  late final CompletedSudokuLogRepository _completedSudokuLogRepository =
      widget.completedSudokuLogRepository ??
      LocalCompletedSudokuLogRepository();
  late final SudokuReplayRepository _replayRepository =
      widget.replayRepository ??
      (_isRunningUnderTest
          ? _InMemorySudokuReplayRepository()
          : LocalSudokuReplayRepository());
  late final SudokuReplayLoggingController _replayLoggingController =
      SudokuReplayLoggingController(repository: _replayRepository);
  late final ShowAdForHintUseCase _showAdForHintUseCase =
      widget.showAdForHintUseCase ??
      ShowAdForHintUseCase(
        adService: UnityAdsService(config: UnityAdsConfig.fromEnvironment()),
        analyticsService: DebugAnalyticsService(),
      );
  late final Random _random = widget.random ?? Random();

  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;
  late final AnimationController _textRotationController;
  late final AnimationController _splitController;
  late final SudokuModifierGlobalConfig _modifierConfig =
      defaultSudokuModifierGlobalConfig;
  late final SudokuModifierContext _modifierContext;
  late final SudokuModifierRegistry _modifierRegistry;
  late final SudokuModifierScheduler _modifierScheduler;

  SudokuGridData? _gridData;
  Object? _loadingError;
  int _activeValue = 1;
  SudokuModifierType? _activeModifier;
  Offset _gridShakeOffset = Offset.zero;
  Size _goatViewportSize = Size.zero;
  Size _rainViewportSize = Size.zero;
  DateTime? _lastGoatUpdate;
  DateTime? _lastRainUpdate;
  final List<FlyingGoat> _flyingGoats = <FlyingGoat>[];
  final List<RainDrop> _rainDrops = <RainDrop>[];
  int _nextGoatId = 0;
  int _nextRainDropId = 0;
  int _quarterTurns = 0;
  final Map<int, int> _textRotationDirections = <int, int>{};
  bool _modifierLifecycleStarted = false;
  bool _isDisposing = false;
  bool _isSolved = false;
  bool _isFinishSequenceRunning = false;
  bool _showSolvedOverlay = false;
  bool _isReplayStarting = false;
  bool _isHintRequestInProgress = false;
  bool _isHintHighlightRunning = false;
  int? _hintHighlightCellIndex;
  final Set<int> _hiddenCellIndices = <int>{};
  ChallengeRoundData? _activeChallengeRound;
  Timer? _challengeAutosaveTimer;
  Timer? _roundClockTimer;
  DateTime? _roundStartedAt;
  bool _completedSudokuLogged = false;
  bool _isReplayReady = false;
  Duration _visibleElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rotationController = AnimationController(vsync: this);
    _rotation90Controller = AnimationController(vsync: this);
    _textRotationController = AnimationController(vsync: this);
    _splitController = AnimationController(vsync: this);

    _modifierContext = SudokuModifierContext(
      random: _random,
      tickerProvider: this,
      isMounted: () => mounted && !_isDisposing,
      scheduleSetState: (VoidCallback callback) => setState(callback),
      deactivateModifier: () => _modifierScheduler.deactivateCurrentModifier(),
      readGridData: () => _gridData,
      readGridShakeOffset: () => _gridShakeOffset,
      writeGridShakeOffset: (Offset value) {
        _gridShakeOffset = value;
      },
      readQuarterTurns: () => _quarterTurns,
      writeQuarterTurns: (int value) {
        _quarterTurns = value;
      },
      readGoatViewportSize: () => _goatViewportSize,
      readFlyingGoats: () => _flyingGoats,
      readAndIncrementNextGoatId: () => _nextGoatId++,
      readLastGoatUpdate: () => _lastGoatUpdate,
      writeLastGoatUpdate: (DateTime? value) {
        _lastGoatUpdate = value;
      },
      readRainViewportSize: () => _rainViewportSize,
      readRainDrops: () => _rainDrops,
      readAndIncrementNextRainDropId: () => _nextRainDropId++,
      readLastRainUpdate: () => _lastRainUpdate,
      writeLastRainUpdate: (DateTime? value) {
        _lastRainUpdate = value;
      },
      rotationController: _rotationController,
      rotation90Controller: _rotation90Controller,
      textRotationController: _textRotationController,
      splitController: _splitController,
      textRotationDirections: _textRotationDirections,
    );

    _modifierRegistry =
        SudokuModifierFactory(config: _modifierConfig).buildRegistry();

    _modifierScheduler = SudokuModifierScheduler(
      registry: _modifierRegistry,
      context: _modifierContext,
      config: _modifierConfig,
      onModifierChanged: (SudokuModifierType? modifier) {
        _activeModifier = modifier;
      },
    );

    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    try {
      final _LoadedPuzzleData loaded = await _resolvePuzzleData();
      if (!mounted) {
        return;
      }
      setState(() {
        _gridData = loaded.gridData;
        _activeChallengeRound = loaded.challengeRoundData;
        _activeValue = _resolveSelectableActiveValue(
          preferredValue: _activeValue,
          grid: loaded.gridData.currentGrid,
        );
        _roundStartedAt = loaded.startedAt;
        _isSolved = loaded.challengeRoundData?.isCompleted ?? false;
        _isFinishSequenceRunning = false;
        _showSolvedOverlay = loaded.challengeRoundData?.isCompleted ?? false;
        _isReplayStarting = false;
        _completedSudokuLogged =
            loaded.challengeRoundData?.isCompleted ?? false;
        _isReplayReady = false;
        _hiddenCellIndices.clear();
        _rainDrops.clear();
        _lastRainUpdate = null;
      });
      await _initializeReplayLogging(loaded);
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleElapsed = _elapsedDurationAt(DateTime.now());
        _isReplayReady = true;
      });
      _startRoundClockIfNeeded();
      _startModifierLifecycleIfNeeded();
      if (!(loaded.challengeRoundData?.isCompleted ?? false)) {
        _checkSolvedAndMaybeStartFinishSequence();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _stopRoundClock();
      setState(() {
        _loadingError = error;
      });
    }
  }

  Future<_LoadedPuzzleData> _resolvePuzzleData() async {
    final AdminTestSudokuConfig? adminOverrideConfig =
        _readAdminOverrideConfig();
    final String? overridePuzzle = adminOverrideConfig?.normalizedSudokuString;
    if (overridePuzzle != null) {
      debugPrint('Admin test sudoku override applied.');
      return _LoadedPuzzleData(
        gridData: parsePuzzle(overridePuzzle),
        startedAt: DateTime.now(),
      );
    }

    if (widget.roundConfig.mode == SudokuRoundMode.challenge) {
      final DateTime? challengeDate = widget.roundConfig.challengeDate;
      if (challengeDate == null) {
        throw StateError('Challenge round requires a challenge date.');
      }

      final ChallengeRoundData roundData = await _challengeRepository
          .loadOrCreateRoundData(
            date: challengeDate,
            difficulty: widget.roundConfig.difficulty,
          );
      return _LoadedPuzzleData(
        gridData: _buildChallengeGridData(roundData),
        challengeRoundData: roundData,
        startedAt: roundData.startedAt,
      );
    }

    if (widget.roundConfig.mode == SudokuRoundMode.daily) {
      final DateTime startedAt = DateTime.now();
      return _LoadedPuzzleData(
        gridData: parsePuzzle(
          await _repository.getOrCreateDailyPuzzle(DateTime.now()),
        ),
        startedAt: startedAt,
      );
    }
    final DateTime startedAt = DateTime.now();
    return _LoadedPuzzleData(
      gridData: parsePuzzle(
        await _repository.getRandomByDifficulty(widget.roundConfig.difficulty),
      ),
      startedAt: startedAt,
    );
  }

  AdminTestSudokuConfig? _readAdminOverrideConfig() {
    if (!_isAdminOverrideRuntimeEnabled) {
      return null;
    }

    final AdminTestSudokuConfig config =
        widget.adminTestOverrideConfig ?? adminTestSudokuOverrideConfig;
    if (config.hasValidOverride) {
      return config;
    }
    if (config.enabled && !config.hasValidOverride) {
      debugPrint(
        'Admin test sudoku override ignored because configured value is invalid.',
      );
    }
    return null;
  }

  bool get _isAdminOverrideRuntimeEnabled {
    final bool? overrideEnabled = widget.adminTestOverrideEnabled;
    if (overrideEnabled != null) {
      return overrideEnabled;
    }
    return kDebugMode && !_isRunningUnderTest;
  }

  bool get _isRunningUnderTest {
    final WidgetsBinding binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('Test');
  }

  void _startModifierLifecycleIfNeeded() {
    if (!widget.roundConfig.crazyModeEnabled || _gridData == null) {
      return;
    }
    if (_modifierLifecycleStarted) {
      return;
    }
    _modifierLifecycleStarted = true;
    _modifierScheduler.start();
  }

  void _setActiveValue(int value) {
    if (_isInteractionLocked) {
      return;
    }
    setState(() {
      _activeValue = _resolveSelectableActiveValue(
        preferredValue: value,
        grid: _gridData?.currentGrid,
      );
    });
  }

  void _writeActiveNumberToCell(int row, int col) {
    final SudokuGridData? gridData = _gridData;
    if (_isInteractionLocked ||
        gridData == null ||
        gridData.isFixed[row][col]) {
      return;
    }

    final _GridWriteResult? writeResult = _writeValueToCell(
      row: row,
      col: col,
      nextValue: _activeValue,
    );
    if (writeResult == null) {
      return;
    }
    _logReplayMove(writeResult: writeResult);
    _scheduleChallengeAutosave();
    _checkSolvedAndMaybeStartFinishSequence();
  }

  void _updateGoatViewport(Size viewportSize) {
    _goatViewportSize = viewportSize;
  }

  void _updateRainViewport(Size viewportSize) {
    _rainViewportSize = viewportSize;
  }

  bool get _isInteractionLocked =>
      _isFinishSequenceRunning ||
      _showSolvedOverlay ||
      _isReplayStarting ||
      _isHintRequestInProgress;

  Set<int> get _hiddenNumberValues {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      return const <int>{};
    }
    return fullyUsedSudokuDigits(gridData.currentGrid);
  }

  bool get _canRequestHint {
    return _showAdForHintUseCase.supportsCurrentPlatform &&
        _gridData != null &&
        !_isSolved &&
        !_isInteractionLocked &&
        _findHintTargetCell() != null;
  }

  bool get _isAdminSolveButtonEnabled {
    final bool? overrideEnabled = widget.adminSolveButtonEnabled;
    if (overrideEnabled != null) {
      return overrideEnabled;
    }
    return ADMIN_BUTTON_SUDOKU_SOLVE;
  }

  Future<void> _requestHint() async {
    final _HintTargetCell? targetCell = _findHintTargetCell();
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (targetCell == null || !_canRequestHint) {
      debugPrint(
        '[hint.flow] request aborted: '
        'targetCell=$targetCell, '
        'canRequestHint=$_canRequestHint, '
        'hasGrid=${_gridData != null}, '
        'isSolved=$_isSolved, '
        'isInteractionLocked=$_isInteractionLocked',
      );
      return;
    }

    debugPrint(
      '[hint.flow] request started: '
      'targetCell=row=${targetCell.row}, col=${targetCell.col}, index=${targetCell.index}',
    );

    setState(() {
      _isHintRequestInProgress = true;
    });

    try {
      final HintAdResult adResult = await _showAdForHintUseCase.execute();
      debugPrint('[hint.flow] ad result=$adResult');
      if (!mounted) {
        debugPrint('[hint.flow] widget unmounted after ad result');
        return;
      }
      if (adResult != HintAdResult.granted) {
        debugPrint('[hint.flow] hint not granted, showing snackbar');
        messenger?.showSnackBar(
          SnackBar(content: Text(_messageForHintAdResult(adResult))),
        );
        return;
      }

      final SudokuGridData? gridData = _gridData;
      if (gridData == null) {
        debugPrint('[hint.flow] gridData is null after granted ad');
        return;
      }

      debugPrint(
        '[hint.flow] applying hint: '
        'row=${targetCell.row}, col=${targetCell.col}, '
        'currentValue=${gridData.currentGrid[targetCell.row][targetCell.col]}, '
        'solutionValue=${gridData.solutionGrid[targetCell.row][targetCell.col]}',
      );
      final _GridWriteResult? writeResult = _writeValueToCell(
        row: targetCell.row,
        col: targetCell.col,
        nextValue: gridData.solutionGrid[targetCell.row][targetCell.col],
      );
      if (writeResult == null) {
        debugPrint('[hint.flow] writeResult is null, hint was not applied');
        return;
      }

      debugPrint(
        '[hint.flow] hint applied: '
        'previousValue=${writeResult.previousValue}, '
        'nextValue=${writeResult.nextValue}',
      );
      _logReplayMove(writeResult: writeResult);
      debugPrint('[hint.flow] replay move logged');
      _scheduleChallengeAutosave();
      debugPrint('[hint.flow] autosave scheduled');

      if (!mounted) {
        debugPrint('[hint.flow] widget unmounted before highlight start');
        return;
      }
      setState(() {
        _isHintRequestInProgress = false;
      });

      debugPrint('[hint.flow] starting hint highlight');
      await _showHintHighlight(targetCell.index);
      if (!mounted) {
        debugPrint('[hint.flow] widget unmounted after hint highlight');
        return;
      }
      debugPrint('[hint.flow] hint highlight completed, checking solved state');
      _checkSolvedAndMaybeStartFinishSequence();
      debugPrint('[hint.flow] request completed successfully');
      return;
    } catch (error, stackTrace) {
      debugPrint('[hint.flow] failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Hinweis konnte gerade nicht geladen werden.'),
          ),
        );
      }
      return;
    } finally {
      if (mounted && _isHintRequestInProgress) {
        setState(() {
          _isHintRequestInProgress = false;
        });
      }
    }
  }

  void _checkSolvedAndMaybeStartFinishSequence() {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null || _isSolved || _isFinishSequenceRunning) {
      return;
    }
    if (!isGridSolved(gridData)) {
      return;
    }
    unawaited(_runFinishSequence());
  }

  Future<void> _fillSudokuForAdminTestLeavingOneCellOpen() async {
    final SudokuGridData? gridData = _gridData;
    if (!_isAdminSolveButtonEnabled ||
        _isInteractionLocked ||
        _isSolved ||
        gridData == null) {
      return;
    }

    int? openCellIndex;
    for (int index = 80; index >= 0; index--) {
      final int row = index ~/ 9;
      final int col = index % 9;
      if (!gridData.isFixed[row][col]) {
        openCellIndex = index;
        break;
      }
    }

    if (openCellIndex == null) {
      return;
    }

    final List<_AdminReplayMove> adminMoves = <_AdminReplayMove>[];
    for (int index = 0; index < 81; index++) {
      final int row = index ~/ 9;
      final int col = index % 9;
      if (gridData.isFixed[row][col]) {
        continue;
      }
      final int previousValue = gridData.currentGrid[row][col];
      final int nextValue =
          index == openCellIndex ? 0 : gridData.solutionGrid[row][col];
      if (previousValue == nextValue) {
        continue;
      }
      adminMoves.add(
        _AdminReplayMove(
          row: row,
          col: col,
          previousValue: previousValue,
          nextValue: nextValue,
        ),
      );
    }

    if (adminMoves.isEmpty) {
      return;
    }

    setState(() {
      for (final _AdminReplayMove move in adminMoves) {
        gridData.currentGrid[move.row][move.col] = move.nextValue;
      }
      _activeValue = _resolveSelectableActiveValue(
        preferredValue: _activeValue,
        grid: gridData.currentGrid,
      );
    });

    _scheduleChallengeAutosave();
    final DateTime actionTime = DateTime.now();
    for (final _AdminReplayMove move in adminMoves) {
      await _replayLoggingController.logMove(
        row: move.row,
        col: move.col,
        previousValue: move.previousValue,
        nextValue: move.nextValue,
        at: actionTime,
      );
    }
  }

  _HintTargetCell? _findHintTargetCell() {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      return null;
    }

    for (int index = 0; index < 81; index++) {
      final int row = index ~/ 9;
      final int col = index % 9;
      if (gridData.isFixed[row][col]) {
        continue;
      }
      if (gridData.currentGrid[row][col] == gridData.solutionGrid[row][col]) {
        continue;
      }
      return _HintTargetCell(row: row, col: col);
    }

    return null;
  }

  _GridWriteResult? _writeValueToCell({
    required int row,
    required int col,
    required int nextValue,
  }) {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      return null;
    }

    final int previousValue = gridData.currentGrid[row][col];
    if (previousValue == nextValue) {
      return null;
    }

    setState(() {
      gridData.currentGrid[row][col] = nextValue;
      _activeValue = _resolveSelectableActiveValue(
        preferredValue: _activeValue,
        grid: gridData.currentGrid,
      );
      if (_activeModifier == SudokuModifierType.textRotation &&
          nextValue != 0) {
        final int index = (row * 9) + col;
        _textRotationDirections.putIfAbsent(
          index,
          () => _random.nextBool() ? 1 : -1,
        );
      }
    });

    return _GridWriteResult(
      row: row,
      col: col,
      previousValue: previousValue,
      nextValue: nextValue,
    );
  }

  void _logReplayMove({required _GridWriteResult writeResult}) {
    final DateTime moveTime = DateTime.now();
    unawaited(
      _replayLoggingController.logMove(
        row: writeResult.row,
        col: writeResult.col,
        previousValue: writeResult.previousValue,
        nextValue: writeResult.nextValue,
        at: moveTime,
      ),
    );
  }

  Future<void> _showHintHighlight(int cellIndex) async {
    if (!mounted) {
      debugPrint(
        '[hint.flow] hint highlight aborted before start: widget unmounted',
      );
      return;
    }

    debugPrint('[hint.flow] hint highlight setup: cellIndex=$cellIndex');
    setState(() {
      _isHintHighlightRunning = true;
      _hintHighlightCellIndex = cellIndex;
    });

    await Future<void>.delayed(_hintHighlightDuration);

    if (!mounted) {
      debugPrint(
        '[hint.flow] hint highlight cleanup skipped: widget unmounted',
      );
      return;
    }

    setState(() {
      _isHintHighlightRunning = false;
      _hintHighlightCellIndex = null;
    });
    debugPrint('[hint.flow] hint highlight cleanup complete');
  }

  String _messageForHintAdResult(HintAdResult adResult) {
    switch (adResult) {
      case HintAdResult.granted:
        return 'Hinweis freigeschaltet.';
      case HintAdResult.unavailable:
        return 'Gerade ist kein Hinweis-Werbespot verfuegbar.';
      case HintAdResult.failed:
        return 'Der Hinweis konnte nicht geladen werden.';
    }
  }

  Future<void> _runFinishSequence() async {
    if (_isFinishSequenceRunning || _showSolvedOverlay) {
      return;
    }

    final DateTime completedAt = DateTime.now();
    _stopRoundClock(syncAt: completedAt);
    await _replayLoggingController.complete(
      finalGridString: _gridToString(_gridData!.currentGrid),
      completedAt: completedAt,
    );
    await _flushChallengeAutosave(
      markCompleted: true,
      completedAt: completedAt,
    );
    await _logCompletedSudokuIfNeeded(completedAt);
    _modifierScheduler.stop();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSolved = true;
      _isFinishSequenceRunning = true;
      _activeModifier = null;
      _gridShakeOffset = Offset.zero;
      _hiddenCellIndices.clear();
      _flyingGoats.clear();
      _rainDrops.clear();
      _lastRainUpdate = null;
    });

    for (final int index in _spiralOrder) {
      await Future<void>.delayed(_finishStepDelay);
      if (!mounted) {
        return;
      }
      setState(() {
        _hiddenCellIndices.add(index);
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isFinishSequenceRunning = false;
      _showSolvedOverlay = true;
    });
  }

  Future<void> _startReplayRound() async {
    if (widget.roundConfig.mode == SudokuRoundMode.challenge) {
      await Navigator.of(context).maybePop();
      return;
    }
    if (_isReplayStarting) {
      return;
    }

    setState(() {
      _isReplayStarting = true;
    });

    try {
      final Future<void> Function(
        BuildContext context,
        SudokuRoundConfig roundConfig,
      )?
      replayStarter = widget.onReplayRoundRequested;
      if (replayStarter != null) {
        await replayStarter(context, widget.roundConfig);
        return;
      }

      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) => PlaySudokuPage(
                roundConfig: widget.roundConfig,
                onReplayRoundRequested: widget.onReplayRoundRequested,
                repository: widget.repository,
                challengeRepository: widget.challengeRepository,
                completedSudokuLogRepository:
                    widget.completedSudokuLogRepository,
                replayRepository: widget.replayRepository,
                adminTestOverrideConfig: widget.adminTestOverrideConfig,
                adminTestOverrideEnabled: widget.adminTestOverrideEnabled,
                adminSolveButtonEnabled: widget.adminSolveButtonEnabled,
                showAdForHintUseCase: widget.showAdForHintUseCase,
                random: widget.random,
              ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReplayStarting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopRoundClock();
    if (_challengeAutosaveTimer != null) {
      _challengeAutosaveTimer!.cancel();
      _challengeAutosaveTimer = null;
      unawaited(_flushChallengeAutosave());
    }
    unawaited(_replayLoggingController.pauseSession(DateTime.now()));
    unawaited(_replayLoggingController.flush());
    _modifierScheduler.dispose();
    _rotationController.dispose();
    _rotation90Controller.dispose();
    _textRotationController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isReplayReady || _isSolved) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      final DateTime pausedAt = DateTime.now();
      _stopRoundClock(syncAt: pausedAt);
      unawaited(_replayLoggingController.pauseSession(pausedAt));
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final DateTime resumedAt = DateTime.now();
      unawaited(_replayLoggingController.startSession(resumedAt));
      _syncVisibleElapsed(resumedAt);
      _startRoundClockIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showRainOverlay =
        widget.roundConfig.crazyModeEnabled &&
        (_activeModifier == SudokuModifierType.rain || _rainDrops.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            _updateRainViewport(
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(context),
                ),
                if (_shouldShowRoundTimer)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: SudokuRoundTimer(
                      key: const Key('sudoku-round-timer'),
                      elapsed: _visibleElapsed,
                    ),
                  ),
                if (showRainOverlay)
                  Positioned.fill(
                    child: RainOverlay(
                      drops: _rainDrops,
                      slantDxPerLength: _modifierConfig.rain.slantDxPerLength,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loadingError != null) {
      return Center(
        child: Text(
          'Fehler beim Laden: $_loadingError',
          textAlign: TextAlign.center,
        ),
      );
    }

    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        const SizedBox(height: _roundTimerReservedHeight),
        if (widget.roundConfig.crazyModeEnabled)
          ModifierBanner(activeModifier: _activeModifier),
        if (widget.roundConfig.crazyModeEnabled) const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    SudokuGrid(
                      gridData: gridData,
                      activeValue: _activeValue,
                      activeModifier: _activeModifier,
                      gridShakeOffset: _gridShakeOffset,
                      quarterTurns: _quarterTurns,
                      rotationController: _rotationController,
                      rotation90Controller: _rotation90Controller,
                      textRotationController: _textRotationController,
                      splitController: _splitController,
                      splitMaxOffsetPx: _modifierConfig.split.maxOffsetPx,
                      textRotationDirections: _textRotationDirections,
                      flyingGoats: _flyingGoats,
                      goatAssetPath: _goatAssetPath,
                      onCellTapped: _writeActiveNumberToCell,
                      onViewportChanged: _updateGoatViewport,
                      hiddenCellIndices: _hiddenCellIndices,
                      hintHighlightCellIndex: _hintHighlightCellIndex,
                      interactionEnabled: !_isInteractionLocked,
                    ),
                    if (_showSolvedOverlay) _buildSolvedOverlay(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            key: const Key('sudoku-hint-button'),
            onPressed: _canRequestHint ? _requestHint : null,
            child:
                _isHintRequestInProgress
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Hinweis'),
          ),
        ),
        const SizedBox(height: 12),
        if (_isAdminSolveButtonEnabled) ...<Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              key: const Key('admin-solve-sudoku-button'),
              onPressed:
                  (_gridData == null || _isInteractionLocked || _isSolved)
                      ? null
                      : _fillSudokuForAdminTestLeavingOneCellOpen,
              child: const Text('Admin: fast loesen'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SudokuNumberPad(
          activeValue: _activeValue,
          hiddenValues: _hiddenNumberValues,
          enabled: !_isInteractionLocked,
          onValueSelected: _setActiveValue,
        ),
      ],
    );
  }

  int _resolveSelectableActiveValue({
    required int preferredValue,
    required List<List<int>>? grid,
  }) {
    if (preferredValue == 0) {
      return 0;
    }
    if (grid == null) {
      return preferredValue;
    }

    final Set<int> hiddenDigits = fullyUsedSudokuDigits(grid);
    if (!hiddenDigits.contains(preferredValue)) {
      return preferredValue;
    }

    for (int value = 1; value <= 9; value++) {
      if (!hiddenDigits.contains(value)) {
        return value;
      }
    }

    return 0;
  }

  bool get _shouldShowRoundTimer =>
      _loadingError == null && _gridData != null && _isReplayReady;

  Duration _elapsedDurationAt(DateTime now) {
    return Duration(
      milliseconds: _replayLoggingController.currentElapsedMillis(now),
    );
  }

  void _startRoundClockIfNeeded() {
    if (!_isReplayReady || _isSolved || _showSolvedOverlay || _isDisposing) {
      return;
    }
    _roundClockTimer?.cancel();
    _roundClockTimer = Timer.periodic(_roundClockTick, (_) {
      _syncVisibleElapsed(DateTime.now());
    });
  }

  void _stopRoundClock({DateTime? syncAt}) {
    _roundClockTimer?.cancel();
    _roundClockTimer = null;
    if (syncAt != null) {
      _syncVisibleElapsed(syncAt);
    }
  }

  void _syncVisibleElapsed(DateTime now) {
    final Duration nextElapsed = _elapsedDurationAt(now);
    if (_visibleElapsed == nextElapsed) {
      return;
    }
    if (!mounted) {
      _visibleElapsed = nextElapsed;
      return;
    }
    setState(() {
      _visibleElapsed = nextElapsed;
    });
  }

  Widget _buildSolvedOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool isChallengeRound =
        widget.roundConfig.mode == SudokuRoundMode.challenge;
    return Positioned.fill(
      child: Container(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n?.sudokuSolvedTitle ?? 'Sudoku solved',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isReplayStarting ? null : _startReplayRound,
                child:
                    _isReplayStarting
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          isChallengeRound
                              ? l10n?.challengeBackToCalendar ??
                                  'Back to calendar'
                              : l10n?.sudokuPlayAgain ?? 'Play again',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SudokuGridData _buildChallengeGridData(ChallengeRoundData roundData) {
    final SudokuGridData gridData = parsePuzzle(roundData.puzzleString);
    final String currentGridString = roundData.currentGridString;
    if (currentGridString.length != 81 ||
        !RegExp(r'^[0-9]{81}$').hasMatch(currentGridString)) {
      throw const FormatException('Invalid challenge progress grid.');
    }

    for (int index = 0; index < currentGridString.length; index++) {
      final int row = index ~/ 9;
      final int col = index % 9;
      gridData.currentGrid[row][col] = int.parse(currentGridString[index]);
    }
    return gridData;
  }

  void _scheduleChallengeAutosave() {
    if (widget.roundConfig.mode != SudokuRoundMode.challenge ||
        _activeChallengeRound == null) {
      return;
    }
    _challengeAutosaveTimer?.cancel();
    _challengeAutosaveTimer = Timer(const Duration(milliseconds: 200), () {
      unawaited(_flushChallengeAutosave());
    });
  }

  Future<void> _flushChallengeAutosave({
    bool markCompleted = false,
    DateTime? completedAt,
  }) async {
    if (widget.roundConfig.mode != SudokuRoundMode.challenge) {
      return;
    }

    _challengeAutosaveTimer?.cancel();
    _challengeAutosaveTimer = null;
    try {
      await _persistChallengeProgress(
        isCompleted: markCompleted,
        completedAt: completedAt,
      );
    } catch (error, stackTrace) {
      debugPrint('Challenge autosave failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _persistChallengeProgress({
    required bool isCompleted,
    DateTime? completedAt,
  }) async {
    final ChallengeRoundData? roundData = _activeChallengeRound;
    final SudokuGridData? gridData = _gridData;
    if (roundData == null || gridData == null) {
      return;
    }

    final String currentGrid = _gridToString(gridData.currentGrid);
    final bool completed = roundData.isCompleted || isCompleted;
    await _challengeRepository.saveChallengeProgress(
      date: roundData.date,
      difficulty: roundData.difficulty,
      sudokuId: roundData.sudokuId,
      currentGrid: currentGrid,
      isCompleted: completed,
    );
    _activeChallengeRound = roundData.copyWith(
      currentGridString: currentGrid,
      isCompleted: completed,
      completedAt:
          completed
              ? (roundData.completedAt ?? completedAt)
              : roundData.completedAt,
    );
  }

  Future<void> _logCompletedSudokuIfNeeded(DateTime completedAt) async {
    if (_completedSudokuLogged) {
      return;
    }

    final DateTime startedAt = _roundStartedAt ?? completedAt;
    final ChallengeRoundData? challengeRoundData = _activeChallengeRound;
    final int durationSeconds =
        (_replayLoggingController.currentElapsedMillis(completedAt) ~/ 1000)
            .clamp(0, 1 << 31);

    await _completedSudokuLogRepository.addCompletedSudoku(
      CompletedSudokuEntry(
        difficulty: widget.roundConfig.difficulty,
        mode: _mapCompletedMode(widget.roundConfig.mode),
        startedAt: startedAt,
        completedAt: completedAt,
        durationSeconds: durationSeconds,
        challengeDate: challengeRoundData?.date,
        sourceSudokuId: challengeRoundData?.sudokuId,
        replayId: _replayLoggingController.replayId,
      ),
    );
    _completedSudokuLogged = true;
  }

  Future<void> _initializeReplayLogging(_LoadedPuzzleData loaded) async {
    final CompletedSudokuMode mode = _mapCompletedMode(widget.roundConfig.mode);
    final ChallengeRoundData? roundData = loaded.challengeRoundData;
    await _replayLoggingController.initialize(
      draft: SudokuReplayDraft(
        mode: mode,
        difficulty: widget.roundConfig.difficulty,
        challengeDate: roundData?.date,
        sourceSudokuId: roundData?.sudokuId,
        puzzleString: _gridToString(loaded.gridData.initialGrid),
        createdAt: loaded.startedAt,
      ),
      allowResume: widget.roundConfig.mode == SudokuRoundMode.challenge,
      roundKey: SudokuReplayRoundKey(
        mode: mode,
        difficulty: widget.roundConfig.difficulty,
        challengeDate: roundData?.date,
        sourceSudokuId: roundData?.sudokuId,
      ),
    );
    if (!(loaded.challengeRoundData?.isCompleted ?? false)) {
      await _replayLoggingController.startSession(DateTime.now());
    }
  }

  CompletedSudokuMode _mapCompletedMode(SudokuRoundMode mode) {
    switch (mode) {
      case SudokuRoundMode.normal:
        return CompletedSudokuMode.normal;
      case SudokuRoundMode.daily:
        return CompletedSudokuMode.daily;
      case SudokuRoundMode.challenge:
        return CompletedSudokuMode.challenge;
    }
  }

  String _gridToString(List<List<int>> grid) {
    final StringBuffer buffer = StringBuffer();
    for (final List<int> row in grid) {
      for (final int value in row) {
        buffer.write(value);
      }
    }
    return buffer.toString();
  }
}

class _LoadedPuzzleData {
  const _LoadedPuzzleData({
    required this.gridData,
    required this.startedAt,
    this.challengeRoundData,
  });

  final SudokuGridData gridData;
  final DateTime startedAt;
  final ChallengeRoundData? challengeRoundData;
}

class _AdminReplayMove {
  const _AdminReplayMove({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.nextValue,
  });

  final int row;
  final int col;
  final int previousValue;
  final int nextValue;
}

class _HintTargetCell {
  const _HintTargetCell({required this.row, required this.col});

  final int row;
  final int col;

  int get index => (row * 9) + col;
}

class _GridWriteResult {
  const _GridWriteResult({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.nextValue,
  });

  final int row;
  final int col;
  final int previousValue;
  final int nextValue;
}

class _InMemorySudokuReplayRepository implements SudokuReplayRepository {
  SudokuReplayRoundKey? _openReplayKey;
  _InMemorySudokuReplay? _replay;
  final List<_InMemoryReplayMove> _moves = <_InMemoryReplayMove>[];
  final List<_InMemoryReplaySession> _sessions = <_InMemoryReplaySession>[];

  @override
  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  }) async {
    _moves.add(
      _InMemoryReplayMove(
        replayId: replayId,
        sequence: sequence,
        cellRow: cellRow,
        cellCol: cellCol,
        previousValue: previousValue,
        nextValue: nextValue,
        elapsedMillis: elapsedMillis,
      ),
    );
  }

  @override
  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  }) async {
    final _InMemorySudokuReplay? replay = _replay;
    if (replay == null || replay.id != replayId) {
      return;
    }
    _replay = replay.copyWith(
      finalGridString: finalGridString,
      playedDurationMillis: playedDurationMillis,
      updatedAt: completedAt,
      completedAt: completedAt,
    );
  }

  @override
  Future<SudokuReplay> createReplay(SudokuReplayDraft draft) async {
    final SudokuReplay replay = SudokuReplay(
      id: 1,
      mode: draft.mode,
      difficulty: draft.difficulty,
      challengeDate: draft.challengeDate,
      sourceSudokuId: draft.sourceSudokuId,
      puzzleString: draft.puzzleString,
      finalGridString: draft.puzzleString,
      playedDurationMillis: 0,
      createdAt: draft.createdAt,
      updatedAt: draft.createdAt,
    );
    _replay = _InMemorySudokuReplay.fromBase(replay);
    _openReplayKey = SudokuReplayRoundKey(
      mode: draft.mode,
      difficulty: draft.difficulty,
      challengeDate: draft.challengeDate,
      sourceSudokuId: draft.sourceSudokuId,
    );
    return replay;
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  }) async {
    final int index = _sessions.indexWhere(
      (_InMemoryReplaySession session) => session.id == sessionId,
    );
    if (index == -1) {
      return;
    }
    _sessions[index] = _sessions[index].copyWith(
      endedAt: endedAt,
      activeDurationMillis: activeDurationMillis,
    );
  }

  @override
  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key) async {
    final _InMemorySudokuReplay? replay = _replay;
    if (replay == null || replay.completedAt != null || !_matches(key)) {
      return null;
    }
    return replay.toBase();
  }

  @override
  Future<SudokuReplayDetails?> getReplayDetails(int replayId) async {
    final _InMemorySudokuReplay? replay = _replay;
    if (replay == null || replay.id != replayId) {
      return null;
    }
    return SudokuReplayDetails(
      replay: replay.toBase(),
      moves:
          _moves
              .where((_InMemoryReplayMove move) => move.replayId == replayId)
              .map((_InMemoryReplayMove move) => move.toBase())
              .toList(),
      sessions:
          _sessions
              .where(
                (_InMemoryReplaySession session) =>
                    session.replayId == replayId,
              )
              .map((_InMemoryReplaySession session) => session.toBase())
              .toList(),
    );
  }

  @override
  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  }) async {
    final int id = _sessions.length + 1;
    _sessions.add(
      _InMemoryReplaySession(
        id: id,
        replayId: replayId,
        sessionIndex: sessionIndex,
        startedAt: startedAt,
      ),
    );
    return id;
  }

  bool _matches(SudokuReplayRoundKey key) {
    final SudokuReplayRoundKey? openReplayKey = _openReplayKey;
    if (openReplayKey == null) {
      return false;
    }
    return openReplayKey.mode == key.mode &&
        openReplayKey.difficulty == key.difficulty &&
        openReplayKey.challengeDate == key.challengeDate &&
        openReplayKey.sourceSudokuId == key.sourceSudokuId;
  }
}

class _InMemorySudokuReplay {
  const _InMemorySudokuReplay({
    required this.id,
    required this.mode,
    required this.difficulty,
    required this.puzzleString,
    required this.finalGridString,
    required this.playedDurationMillis,
    required this.createdAt,
    required this.updatedAt,
    this.challengeDate,
    this.sourceSudokuId,
    this.completedAt,
  });

  factory _InMemorySudokuReplay.fromBase(SudokuReplay replay) {
    return _InMemorySudokuReplay(
      id: replay.id,
      mode: replay.mode,
      difficulty: replay.difficulty,
      challengeDate: replay.challengeDate,
      sourceSudokuId: replay.sourceSudokuId,
      puzzleString: replay.puzzleString,
      finalGridString: replay.finalGridString,
      playedDurationMillis: replay.playedDurationMillis,
      createdAt: replay.createdAt,
      updatedAt: replay.updatedAt,
      completedAt: replay.completedAt,
    );
  }

  final int id;
  final CompletedSudokuMode mode;
  final SudokuDifficulty difficulty;
  final DateTime? challengeDate;
  final int? sourceSudokuId;
  final String puzzleString;
  final String finalGridString;
  final int playedDurationMillis;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  _InMemorySudokuReplay copyWith({
    String? finalGridString,
    int? playedDurationMillis,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return _InMemorySudokuReplay(
      id: id,
      mode: mode,
      difficulty: difficulty,
      challengeDate: challengeDate,
      sourceSudokuId: sourceSudokuId,
      puzzleString: puzzleString,
      finalGridString: finalGridString ?? this.finalGridString,
      playedDurationMillis: playedDurationMillis ?? this.playedDurationMillis,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  SudokuReplay toBase() {
    return SudokuReplay(
      id: id,
      mode: mode,
      difficulty: difficulty,
      challengeDate: challengeDate,
      sourceSudokuId: sourceSudokuId,
      puzzleString: puzzleString,
      finalGridString: finalGridString,
      playedDurationMillis: playedDurationMillis,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}

class _InMemoryReplayMove {
  const _InMemoryReplayMove({
    required this.replayId,
    required this.sequence,
    required this.cellRow,
    required this.cellCol,
    required this.previousValue,
    required this.nextValue,
    required this.elapsedMillis,
  });

  final int replayId;
  final int sequence;
  final int cellRow;
  final int cellCol;
  final int previousValue;
  final int nextValue;
  final int elapsedMillis;

  SudokuReplayMove toBase() {
    return SudokuReplayMove(
      id: sequence + 1,
      replayId: replayId,
      sequence: sequence,
      cellRow: cellRow,
      cellCol: cellCol,
      previousValue: previousValue,
      nextValue: nextValue,
      elapsedMillis: elapsedMillis,
    );
  }
}

class _InMemoryReplaySession {
  const _InMemoryReplaySession({
    required this.id,
    required this.replayId,
    required this.sessionIndex,
    required this.startedAt,
    this.endedAt,
    this.activeDurationMillis = 0,
  });

  final int id;
  final int replayId;
  final int sessionIndex;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int activeDurationMillis;

  _InMemoryReplaySession copyWith({
    DateTime? endedAt,
    int? activeDurationMillis,
  }) {
    return _InMemoryReplaySession(
      id: id,
      replayId: replayId,
      sessionIndex: sessionIndex,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      activeDurationMillis: activeDurationMillis ?? this.activeDurationMillis,
    );
  }

  SudokuPlaySession toBase() {
    return SudokuPlaySession(
      id: id,
      replayId: replayId,
      sessionIndex: sessionIndex,
      startedAt: startedAt,
      endedAt: endedAt,
      activeDurationMillis: activeDurationMillis,
    );
  }
}
