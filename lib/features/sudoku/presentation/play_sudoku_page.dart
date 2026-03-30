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
  static const int _goatSpawnMinMilliseconds = 320;
  static const int _goatSpawnMaxMilliseconds = 900;
  static const double _goatMinSizePx = 64;
  static const double _goatMaxSizePx = 128;
  static const double _goatMinSpeedPxPerSecond = 85;
  static const double _goatMaxSpeedPxPerSecond = 185;
  static const int _maxVisibleGoats = 8;
  static const String _goatAssetPath = 'assets/images/modifiers/goat.png';

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
  Timer? _goatSpawnTimer;
  Timer? _goatMovementTimer;
  Offset _gridShakeOffset = Offset.zero;
  Size _goatViewportSize = Size.zero;
  DateTime? _lastGoatUpdate;
  final List<_FlyingGoat> _flyingGoats = <_FlyingGoat>[];
  int _nextGoatId = 0;
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
      SudokuModifierType.goat,
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
      case SudokuModifierType.goat:
        return _randomBetweenInclusive(
          _modifierDurationMinSeconds,
          _modifierDurationMaxSeconds,
        );
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
      case SudokuModifierType.goat:
        _startGoatModifier();
        break;
    }
  }

  void _stopModifierVisualEffects() {
    _stopGridShaking();
    _stopGridRotation();
    _stopGridRotation90();
    _stopGoatModifier(clearGoats: true);
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

  void _startGoatModifier() {
    _stopGoatModifier(clearGoats: true);
    _lastGoatUpdate = DateTime.now();
    _goatMovementTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateGoats(),
    );
    _scheduleNextGoatSpawn();
  }

  void _scheduleNextGoatSpawn() {
    _goatSpawnTimer?.cancel();
    if (_activeModifier != SudokuModifierType.goat || !mounted) {
      return;
    }

    final int delayMs = _randomBetweenInclusive(
      _goatSpawnMinMilliseconds,
      _goatSpawnMaxMilliseconds,
    );
    _goatSpawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || _activeModifier != SudokuModifierType.goat) {
        return;
      }
      _spawnGoat();
      _scheduleNextGoatSpawn();
    });
  }

  void _spawnGoat() {
    final Size viewport = _goatViewportSize;
    if (viewport.height <= 0 || viewport.width <= 0) {
      return;
    }

    final _GoatDirection direction =
        _random.nextBool()
            ? _GoatDirection.leftToRight
            : _GoatDirection.rightToLeft;
    final double size = _randomDoubleBetween(_goatMinSizePx, _goatMaxSizePx);
    final double maxY = max(0, viewport.height - size);
    final double y = _randomDoubleBetween(0, maxY);
    final double speed = _randomDoubleBetween(
      _goatMinSpeedPxPerSecond,
      _goatMaxSpeedPxPerSecond,
    );
    final double startX =
        direction == _GoatDirection.leftToRight
            ? -(size * 0.6)
            : viewport.width - (size * 0.4);

    setState(() {
      if (_flyingGoats.length >= _maxVisibleGoats) {
        _flyingGoats.removeAt(0);
      }
      _flyingGoats.add(
        _FlyingGoat(
          id: _nextGoatId++,
          direction: direction,
          sizePx: size,
          startY: y,
          speedPxPerSecond: speed,
          spawnTime: DateTime.now(),
          x: startX,
        ),
      );
    });
  }

  void _updateGoats() {
    final DateTime now = DateTime.now();
    final DateTime? lastTick = _lastGoatUpdate;
    _lastGoatUpdate = now;
    if (!mounted || _flyingGoats.isEmpty || lastTick == null) {
      return;
    }

    final double deltaSeconds =
        now.difference(lastTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0) {
      return;
    }

    final double viewportWidth = _goatViewportSize.width;
    if (viewportWidth <= 0) {
      return;
    }

    setState(() {
      for (int i = 0; i < _flyingGoats.length; i++) {
        final _FlyingGoat goat = _flyingGoats[i];
        final double distance = goat.speedPxPerSecond * deltaSeconds;
        final double nextX =
            goat.direction == _GoatDirection.leftToRight
                ? goat.x + distance
                : goat.x - distance;
        _flyingGoats[i] = goat.copyWith(x: nextX);
      }

      _flyingGoats.removeWhere((_FlyingGoat goat) {
        if (goat.direction == _GoatDirection.leftToRight) {
          return goat.x > viewportWidth + goat.sizePx;
        }
        return goat.x + goat.sizePx < -goat.sizePx;
      });
    });
  }

  void _stopGoatModifier({required bool clearGoats}) {
    _goatSpawnTimer?.cancel();
    _goatSpawnTimer = null;
    _goatMovementTimer?.cancel();
    _goatMovementTimer = null;
    _lastGoatUpdate = null;
    if (clearGoats && _flyingGoats.isNotEmpty && mounted) {
      setState(() {
        _flyingGoats.clear();
      });
      return;
    }
    if (clearGoats) {
      _flyingGoats.clear();
    }
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
    _goatSpawnTimer?.cancel();
    _goatMovementTimer?.cancel();
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
      case SudokuModifierType.goat:
        label = l10n?.modifierGoatTitle ?? 'Goat Modifier';
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
    final bool showGoatOverlay =
        _activeModifier == SudokuModifierType.goat || _flyingGoats.isNotEmpty;

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
                            fontWeight:
                                isFixed ? FontWeight.bold : FontWeight.w500,
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

    Widget gridLayer() {
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _goatViewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            gridLayer(),
            if (showGoatOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    key: const Key('goat-overlay'),
                    children:
                        _flyingGoats.map((_FlyingGoat goat) {
                          final bool flipHorizontally =
                              goat.direction == _GoatDirection.rightToLeft;
                          return Positioned(
                            left: goat.x,
                            top: goat.startY,
                            child: SizedBox(
                              key: Key(
                                'goat-${goat.id}-${goat.direction.name}',
                              ),
                              width: goat.sizePx,
                              height: goat.sizePx,
                              child: Transform(
                                alignment: Alignment.center,
                                transform:
                                    flipHorizontally
                                        ? Matrix4.diagonal3Values(-1, 1, 1)
                                        : Matrix4.identity(),
                                child: Image.asset(
                                  _goatAssetPath,
                                  key: Key('goat-image-${goat.id}'),
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        debugPrint(
                                          'Failed to load $_goatAssetPath: $error',
                                        );
                                        return const ColoredBox(
                                          color: Color(0x44FF7043),
                                          child: Center(
                                            child: Icon(
                                              Icons.pets,
                                              color: Colors.brown,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
          ],
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

enum _GoatDirection { leftToRight, rightToLeft }

class _FlyingGoat {
  const _FlyingGoat({
    required this.id,
    required this.direction,
    required this.sizePx,
    required this.startY,
    required this.speedPxPerSecond,
    required this.spawnTime,
    required this.x,
  });

  final int id;
  final _GoatDirection direction;
  final double sizePx;
  final double startY;
  final double speedPxPerSecond;
  final DateTime spawnTime;
  final double x;

  _FlyingGoat copyWith({double? x}) {
    return _FlyingGoat(
      id: id,
      direction: direction,
      sizePx: sizePx,
      startY: startY,
      speedPxPerSecond: speedPxPerSecond,
      spawnTime: spawnTime,
      x: x ?? this.x,
    );
  }
}
