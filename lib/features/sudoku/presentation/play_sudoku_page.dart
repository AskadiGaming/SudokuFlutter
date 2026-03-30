import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/local_sudoku_puzzle_repository.dart';
import '../data/sudoku_puzzle_repository.dart';
import '../domain/sudoku_grid_parser.dart';
import '../domain/sudoku_matrix_rotation.dart';
import '../domain/sudoku_modifier_type.dart';
import '../domain/sudoku_round_config.dart';

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
  static const int _modifierSpawnMinSeconds = 8;
  static const int _modifierSpawnMaxSeconds = 20;
  static const int _modifierDurationMinSeconds = 3;
  static const int _modifierDurationMaxSeconds = 6;
  static const int _rotationDurationSeconds = 10;
  static const int _rotation90DurationSeconds = 8;

  late final SudokuPuzzleRepository _repository =
      widget.repository ?? LocalSudokuPuzzleRepository();
  late final Random _random = widget.random ?? Random();

  SudokuGridData? _gridData;
  Object? _loadingError;
  int _activeValue = 1;
  SudokuModifierType? _activeModifier;
  Timer? _modifierSpawnTimer;
  Timer? _modifierEndTimer;
  Timer? _shakingTimer;
  Offset _gridShakeOffset = Offset.zero;
  int _quarterTurns = 0;
  bool _isApplying90Commit = false;
  late final AnimationController _rotationController;
  late final AnimationController _rotation90Controller;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this);
    _rotation90Controller = AnimationController(vsync: this)
      ..addStatusListener(_onRotation90StatusChanged);
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
    });
  }

  void _startModifierLifecycleIfNeeded() {
    if (!widget.roundConfig.crazyModeEnabled || _gridData == null) {
      return;
    }
    _scheduleNextModifierActivation();
  }

  void _scheduleNextModifierActivation() {
    _modifierSpawnTimer?.cancel();
    if (!widget.roundConfig.crazyModeEnabled || !mounted) {
      return;
    }

    final int delaySeconds = _randomBetweenInclusive(
      _modifierSpawnMinSeconds,
      _modifierSpawnMaxSeconds,
    );

    _modifierSpawnTimer = Timer(
      Duration(seconds: delaySeconds),
      _activateRandomModifier,
    );
  }

  void _activateRandomModifier() {
    if (!mounted ||
        !widget.roundConfig.crazyModeEnabled ||
        _activeModifier != null) {
      return;
    }

    final List<SudokuModifierType> availableModifiers = <SudokuModifierType>[
      SudokuModifierType.shaking,
      SudokuModifierType.rotation360,
      SudokuModifierType.rotation90,
    ];
    final SudokuModifierType nextModifier =
        availableModifiers[_random.nextInt(availableModifiers.length)];
    final int durationSeconds = _durationSecondsForModifier(nextModifier);

    setState(() {
      _activeModifier = nextModifier;
    });

    _startModifierVisualEffect(nextModifier);
    _modifierEndTimer?.cancel();
    if (nextModifier != SudokuModifierType.rotation90) {
      _modifierEndTimer = Timer(
        Duration(seconds: durationSeconds),
        _deactivateCurrentModifier,
      );
    }
  }

  void _deactivateCurrentModifier() {
    _modifierEndTimer?.cancel();
    _stopModifierVisualEffects();
    if (!mounted) {
      return;
    }

    setState(() {
      _activeModifier = null;
      _gridShakeOffset = Offset.zero;
    });

    _scheduleNextModifierActivation();
  }

  int _durationSecondsForModifier(SudokuModifierType modifier) {
    switch (modifier) {
      case SudokuModifierType.shaking:
        return _randomBetweenInclusive(
          _modifierDurationMinSeconds,
          _modifierDurationMaxSeconds,
        );
      case SudokuModifierType.rotation360:
        return _rotationDurationSeconds;
      case SudokuModifierType.rotation90:
        return _rotation90DurationSeconds;
    }
  }

  void _startModifierVisualEffect(SudokuModifierType modifier) {
    switch (modifier) {
      case SudokuModifierType.shaking:
        _startGridShaking();
        break;
      case SudokuModifierType.rotation360:
        _startGridRotation();
        break;
      case SudokuModifierType.rotation90:
        _startGridRotation90();
        break;
    }
  }

  void _stopModifierVisualEffects() {
    _stopGridShaking();
    _stopGridRotation();
    _stopGridRotation90();
  }

  void _startGridShaking() {
    _shakingTimer?.cancel();
    _shakingTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted || _activeModifier != SudokuModifierType.shaking) {
        return;
      }

      setState(() {
        _gridShakeOffset = Offset(
          _randomDoubleBetween(-4.0, 4.0),
          _randomDoubleBetween(-4.0, 4.0),
        );
      });
    });
  }

  void _stopGridShaking() {
    _shakingTimer?.cancel();
    _shakingTimer = null;
  }

  void _startGridRotation() {
    _rotationController
      ..stop()
      ..duration = const Duration(seconds: _rotationDurationSeconds)
      ..reset()
      ..forward();
  }

  void _stopGridRotation() {
    _rotationController
      ..stop()
      ..reset();
  }

  void _startGridRotation90() {
    _isApplying90Commit = false;
    _rotation90Controller
      ..stop()
      ..duration = const Duration(seconds: _rotation90DurationSeconds)
      ..reset()
      ..forward();
  }

  void _stopGridRotation90() {
    _isApplying90Commit = false;
    _rotation90Controller
      ..stop()
      ..reset();
  }

  void _onRotation90StatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _activeModifier != SudokuModifierType.rotation90 ||
        _isApplying90Commit ||
        !mounted) {
      return;
    }

    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      _deactivateCurrentModifier();
      return;
    }

    _isApplying90Commit = true;
    setState(() {
      final List<List<int>> rotatedGrid = rotateMatrixClockwise90<int>(
        gridData.currentGrid,
      );
      final List<List<bool>> rotatedFixed = rotateMatrixClockwise90<bool>(
        gridData.isFixed,
      );
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          gridData.currentGrid[row][col] = rotatedGrid[row][col];
          gridData.isFixed[row][col] = rotatedFixed[row][col];
        }
      }
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
    _isApplying90Commit = false;
    _deactivateCurrentModifier();
  }

  int _randomBetweenInclusive(int min, int max) {
    if (min == max) {
      return min;
    }
    return min + _random.nextInt(max - min + 1);
  }

  double _randomDoubleBetween(double min, double max) {
    if (min == max) {
      return min;
    }
    return min + (_random.nextDouble() * (max - min));
  }

  @override
  void dispose() {
    _modifierSpawnTimer?.cancel();
    _modifierEndTimer?.cancel();
    _shakingTimer?.cancel();
    _rotation90Controller.removeStatusListener(_onRotation90StatusChanged);
    _rotationController.dispose();
    _rotation90Controller.dispose();
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
    final AppLocalizations? l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

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
        if (widget.roundConfig.crazyModeEnabled) _buildModifierBanner(l10n),
        if (widget.roundConfig.crazyModeEnabled) const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildGrid(context, gridData),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNumberButtons(),
      ],
    );
  }

  Widget _buildModifierBanner(AppLocalizations? l10n) {
    String label = l10n?.modifierNone ?? 'No modifier active';
    switch (_activeModifier) {
      case SudokuModifierType.shaking:
        label = l10n?.modifierShakingTitle ?? 'Shaking Modifier';
        break;
      case SudokuModifierType.rotation360:
        label = l10n?.modifier360Title ?? '360 Modifier';
        break;
      case SudokuModifierType.rotation90:
        label = l10n?.modifier90Title ?? '90° Modifier';
        break;
      case null:
        break;
    }

    return Card(
      key: const Key('modifier-banner'),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.bolt),
        title: Text(label),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, SudokuGridData gridData) {
    final ThemeData theme = Theme.of(context);
    final bool isShaking = _activeModifier == SudokuModifierType.shaking;
    final bool isRotating360 =
        _activeModifier == SudokuModifierType.rotation360;
    final bool isRotating90 = _activeModifier == SudokuModifierType.rotation90;

    Widget buildGridContent() {
      final double rotation90Angle = _rotation90Controller.value * (pi / 2);
      final Widget grid = GridView.builder(
        key: Key('sudoku-grid-orientation-$_quarterTurns'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 81,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemBuilder: (BuildContext context, int index) {
          final int row = index ~/ 9;
          final int col = index % 9;
          final int value = gridData.currentGrid[row][col];
          final bool isFixed = gridData.isFixed[row][col];
          final bool isHighlighted = value != 0 && value == _activeValue;

          final Color baseColor =
              isFixed
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface;
          final Color backgroundColor =
              isHighlighted ? theme.colorScheme.secondaryContainer : baseColor;

          return InkWell(
            onTap: () => _writeActiveNumberToCell(row, col),
            child: Container(
              key: Key('sudoku-cell-$row-$col'),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: _buildCellBorder(context, row, col),
              ),
              child:
                  value == 0
                      ? const SizedBox.shrink()
                      : Transform.rotate(
                        angle: isRotating90 ? -rotation90Angle : 0,
                        child: Text(
                          '$value',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
                            color:
                                isFixed
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
            ),
          );
        },
      );

      return Transform.translate(
        offset: isShaking ? _gridShakeOffset : Offset.zero,
        child: grid,
      );
    }

    if (!isRotating360 && !isRotating90) {
      return buildGridContent();
    }

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _rotationController,
        _rotation90Controller,
      ]),
      builder: (BuildContext context, Widget? child) {
        final double angle =
            isRotating360
                ? _rotationController.value * (2 * pi)
                : _rotation90Controller.value * (pi / 2);
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.center,
          transformHitTests: true,
          child: buildGridContent(),
        );
      },
    );
  }

  Border _buildCellBorder(BuildContext context, int row, int col) {
    final Color color = Theme.of(context).dividerColor;
    final bool thickTop = row % 3 == 0;
    final bool thickLeft = col % 3 == 0;
    final bool thickBottom = row == 8;
    final bool thickRight = col == 8;

    return Border(
      top: BorderSide(width: thickTop ? 2 : 0.5, color: color),
      left: BorderSide(width: thickLeft ? 2 : 0.5, color: color),
      right: BorderSide(width: thickRight ? 2 : 0.5, color: color),
      bottom: BorderSide(width: thickBottom ? 2 : 0.5, color: color),
    );
  }

  Widget _buildNumberButtons() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double buttonWidth = (constraints.maxWidth - 18) / 10;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            key: const Key('number-toggle-buttons'),
            borderRadius: BorderRadius.circular(8),
            constraints: BoxConstraints.tightFor(
              width: buttonWidth.clamp(34, 60),
              height: 42,
            ),
            isSelected: List<bool>.generate(
              10,
              (int index) => _activeValue == _valueForButtonIndex(index),
            ),
            onPressed:
                (int index) => _setActiveValue(_valueForButtonIndex(index)),
            children: List<Widget>.generate(
              10,
              (int index) => _buildButtonLabel(index),
            ),
          ),
        );
      },
    );
  }

  int _valueForButtonIndex(int index) => index == 9 ? 0 : index + 1;

  Widget _buildButtonLabel(int index) {
    if (index == 9) {
      return const Center(
        child: Icon(Icons.backspace_outlined, key: Key('number-button-delete')),
      );
    }
    return Center(
      child: Text('${index + 1}', key: Key('number-button-${index + 1}')),
    );
  }
}
