import 'dart:async';

import '../../../domain/sudoku_modifier_type.dart';
import 'sudoku_modifier.dart';
import 'sudoku_modifier_context.dart';
import 'sudoku_modifier_registry.dart';

class SudokuModifierScheduler {
  SudokuModifierScheduler({
    required SudokuModifierRegistry registry,
    required SudokuModifierContext context,
    required void Function(SudokuModifierType? modifier) onModifierChanged,
    this.spawnMinSeconds = 8,
    this.spawnMaxSeconds = 20,
  }) : _registry = registry,
       _context = context,
       _onModifierChanged = onModifierChanged;

  final SudokuModifierRegistry _registry;
  final SudokuModifierContext _context;
  final void Function(SudokuModifierType? modifier) _onModifierChanged;
  final int spawnMinSeconds;
  final int spawnMaxSeconds;

  Timer? _spawnTimer;
  Timer? _endTimer;
  SudokuModifier? _activeModifier;

  SudokuModifierType? get activeModifierType => _activeModifier?.type;

  void start() {
    _scheduleNextActivation();
  }

  void stop() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _endTimer?.cancel();
    _endTimer = null;
    _stopActiveModifier();
  }

  void deactivateCurrentModifier() {
    _endTimer?.cancel();
    _endTimer = null;
    _stopActiveModifier();

    if (!_context.mounted) {
      return;
    }

    _context.safeSetState(() {
      _onModifierChanged(null);
    });

    _scheduleNextActivation();
  }

  void _scheduleNextActivation() {
    _spawnTimer?.cancel();
    if (!_context.mounted) {
      return;
    }

    final int delaySeconds = _context.randomBetweenInclusive(
      spawnMinSeconds,
      spawnMaxSeconds,
    );
    _spawnTimer = Timer(
      Duration(seconds: delaySeconds),
      _activateRandomModifier,
    );
  }

  void _activateRandomModifier() {
    if (!_context.mounted || _activeModifier != null) {
      return;
    }

    final List<SudokuModifier> modifiers = _registry.modifiers;
    if (modifiers.isEmpty) {
      return;
    }

    final SudokuModifier nextModifier =
        modifiers[_context.random.nextInt(modifiers.length)];
    final int durationSeconds = nextModifier.durationSeconds(_context);

    _activeModifier = nextModifier;
    _context.safeSetState(() {
      _onModifierChanged(nextModifier.type);
    });

    nextModifier.onStart(_context);

    _endTimer?.cancel();
    if (!nextModifier.controlsOwnDeactivation) {
      _endTimer = Timer(
        Duration(seconds: durationSeconds),
        deactivateCurrentModifier,
      );
    }
  }

  void _stopActiveModifier() {
    final SudokuModifier? activeModifier = _activeModifier;
    if (activeModifier == null) {
      return;
    }
    activeModifier.onStop(_context);
    _activeModifier = null;
  }

  void dispose() {
    stop();
    for (final SudokuModifier modifier in _registry.modifiers) {
      modifier.dispose();
    }
  }
}
