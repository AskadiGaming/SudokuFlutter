import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/local_sudoku_puzzle_repository.dart';
import '../data/sudoku_puzzle_repository.dart';
import '../dev/admin_test_sudoku_override.dart';
import '../domain/admin_test_sudoku_config.dart';
import '../domain/default_sudoku_modifier_config.dart';
import '../domain/sudoku_finish_logic.dart';
import '../domain/sudoku_grid_parser.dart';
import '../domain/sudoku_modifier_config.dart';
import '../domain/sudoku_modifier_type.dart';
import '../domain/sudoku_round_config.dart';
import '../domain/sudoku_round_mode.dart';
import 'modifiers/core/sudoku_modifier_context.dart';
import 'modifiers/core/sudoku_modifier_factory.dart';
import 'modifiers/core/sudoku_modifier_registry.dart';
import 'modifiers/core/sudoku_modifier_scheduler.dart';
import 'modifiers/models/flying_goat.dart';
import 'widgets/modifier_banner.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_grid.dart';

class PlaySudokuPage extends StatefulWidget {
  const PlaySudokuPage({
    required this.roundConfig,
    this.onReplayRoundRequested,
    this.repository,
    this.adminTestOverrideConfig,
    this.adminTestOverrideEnabled,
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
  final AdminTestSudokuConfig? adminTestOverrideConfig;
  final bool? adminTestOverrideEnabled;
  final Random? random;

  @override
  State<PlaySudokuPage> createState() => _PlaySudokuPageState();
}

class _PlaySudokuPageState extends State<PlaySudokuPage>
    with TickerProviderStateMixin {
  static const String _goatAssetPath = 'assets/images/modifiers/goat.png';
  static const Duration _finishStepDelay = Duration(milliseconds: 45);
  static final List<int> _spiralOrder = buildSpiralOrder9x9();

  late final SudokuPuzzleRepository _repository =
      widget.repository ?? LocalSudokuPuzzleRepository();
  late final Random _random = widget.random ?? Random();

  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;
  late final AnimationController _textRotationController;
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
  DateTime? _lastGoatUpdate;
  final List<FlyingGoat> _flyingGoats = <FlyingGoat>[];
  int _nextGoatId = 0;
  int _quarterTurns = 0;
  final Map<int, int> _textRotationDirections = <int, int>{};
  bool _modifierLifecycleStarted = false;
  bool _isSolved = false;
  bool _isFinishSequenceRunning = false;
  bool _showSolvedOverlay = false;
  bool _isReplayStarting = false;
  final Set<int> _hiddenCellIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this);
    _rotation90Controller = AnimationController(vsync: this);
    _textRotationController = AnimationController(vsync: this);

    _modifierContext = SudokuModifierContext(
      random: _random,
      tickerProvider: this,
      isMounted: () => mounted,
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
      rotationController: _rotationController,
      rotation90Controller: _rotation90Controller,
      textRotationController: _textRotationController,
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
      final String puzzle = await _resolvePuzzleString();
      final SudokuGridData parsed = parsePuzzle(puzzle);
      if (!mounted) {
        return;
      }
      setState(() {
        _gridData = parsed;
        _isSolved = false;
        _isFinishSequenceRunning = false;
        _showSolvedOverlay = false;
        _isReplayStarting = false;
        _hiddenCellIndices.clear();
      });
      _startModifierLifecycleIfNeeded();
      _checkSolvedAndMaybeStartFinishSequence();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingError = error;
      });
    }
  }

  Future<String> _resolvePuzzleString() async {
    final AdminTestSudokuConfig? adminOverrideConfig =
        _readAdminOverrideConfig();
    final String? overridePuzzle = adminOverrideConfig?.normalizedSudokuString;
    if (overridePuzzle != null) {
      debugPrint('Admin test sudoku override applied.');
      return overridePuzzle;
    }

    if (widget.roundConfig.mode == SudokuRoundMode.daily) {
      return _repository.getOrCreateDailyPuzzle(DateTime.now());
    }
    return _repository.getRandomByDifficulty(widget.roundConfig.difficulty);
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
      _activeValue = value;
    });
  }

  void _writeActiveNumberToCell(int row, int col) {
    final SudokuGridData? gridData = _gridData;
    if (_isInteractionLocked ||
        gridData == null ||
        gridData.isFixed[row][col]) {
      return;
    }

    setState(() {
      gridData.currentGrid[row][col] = _activeValue;
      if (_activeModifier == SudokuModifierType.textRotation &&
          _activeValue != 0) {
        final int index = (row * 9) + col;
        _textRotationDirections.putIfAbsent(
          index,
          () => _random.nextBool() ? 1 : -1,
        );
      }
    });
    _checkSolvedAndMaybeStartFinishSequence();
  }

  void _updateGoatViewport(Size viewportSize) {
    _goatViewportSize = viewportSize;
  }

  bool get _isInteractionLocked =>
      _isFinishSequenceRunning || _showSolvedOverlay || _isReplayStarting;

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

  Future<void> _runFinishSequence() async {
    if (_isFinishSequenceRunning || _showSolvedOverlay) {
      return;
    }

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
                adminTestOverrideConfig: widget.adminTestOverrideConfig,
                adminTestOverrideEnabled: widget.adminTestOverrideEnabled,
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
    _modifierScheduler.dispose();
    _rotationController.dispose();
    _rotation90Controller.dispose();
    _textRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(context),
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
                      textRotationDirections: _textRotationDirections,
                      flyingGoats: _flyingGoats,
                      goatAssetPath: _goatAssetPath,
                      onCellTapped: _writeActiveNumberToCell,
                      onViewportChanged: _updateGoatViewport,
                      hiddenCellIndices: _hiddenCellIndices,
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
        SudokuNumberPad(
          activeValue: _activeValue,
          enabled: !_isInteractionLocked,
          onValueSelected: _setActiveValue,
        ),
      ],
    );
  }

  Widget _buildSolvedOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations? l10n = AppLocalizations.of(context);
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
                        : Text(l10n?.sudokuPlayAgain ?? 'Play again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
