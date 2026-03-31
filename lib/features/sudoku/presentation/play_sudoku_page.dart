import 'dart:math';

import 'package:flutter/material.dart';

import '../data/local_sudoku_puzzle_repository.dart';
import '../data/sudoku_puzzle_repository.dart';
import '../domain/sudoku_grid_parser.dart';
import '../domain/sudoku_modifier_type.dart';
import '../domain/sudoku_round_config.dart';
import 'modifiers/core/sudoku_modifier_context.dart';
import 'modifiers/core/sudoku_modifier.dart';
import 'modifiers/core/sudoku_modifier_registry.dart';
import 'modifiers/core/sudoku_modifier_scheduler.dart';
import 'modifiers/goat_modifier.dart';
import 'modifiers/models/flying_goat.dart';
import 'modifiers/rotation_360_modifier.dart';
import 'modifiers/rotation_90_modifier.dart';
import 'modifiers/shaking_modifier.dart';
import 'modifiers/text_rotation_modifier.dart';
import 'widgets/modifier_banner.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_grid.dart';

class PlaySudokuPage extends StatefulWidget {
  const PlaySudokuPage({
    required this.roundConfig,
    this.repository,
    this.random,
    super.key,
  });

  final SudokuRoundConfig roundConfig;
  final SudokuPuzzleRepository? repository;
  final Random? random;

  @override
  State<PlaySudokuPage> createState() => _PlaySudokuPageState();
}

class _PlaySudokuPageState extends State<PlaySudokuPage>
    with TickerProviderStateMixin {
  static const String _goatAssetPath = 'assets/images/modifiers/goat.png';

  late final SudokuPuzzleRepository _repository =
      widget.repository ?? LocalSudokuPuzzleRepository();
  late final Random _random = widget.random ?? Random();

  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;
  late final AnimationController _textRotationController;
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

    _modifierRegistry = SudokuModifierRegistry(
      modifiers: <SudokuModifier>[
        ShakingModifier(),
        Rotation360Modifier(),
        Rotation90Modifier(),
        GoatModifier(),
        TextRotationModifier(),
      ],
    );

    _modifierScheduler = SudokuModifierScheduler(
      registry: _modifierRegistry,
      context: _modifierContext,
      onModifierChanged: (SudokuModifierType? modifier) {
        _activeModifier = modifier;
      },
    );

    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    try {
      final String puzzle = await _repository.loadPuzzle(
        widget.roundConfig.difficulty,
      );
      final SudokuGridData parsed = parsePuzzle(puzzle);
      if (!mounted) {
        return;
      }
      setState(() {
        _gridData = parsed;
      });
      _startModifierLifecycleIfNeeded();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingError = error;
      });
    }
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
    setState(() {
      _activeValue = value;
    });
  }

  void _writeActiveNumberToCell(int row, int col) {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null || gridData.isFixed[row][col]) {
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
  }

  void _updateGoatViewport(Size viewportSize) {
    _goatViewportSize = viewportSize;
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
                child: SudokuGrid(
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
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SudokuNumberPad(
          activeValue: _activeValue,
          onValueSelected: _setActiveValue,
        ),
      ],
    );
  }
}
