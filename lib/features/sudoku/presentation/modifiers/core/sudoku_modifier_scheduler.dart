import 'dart:async';
import 'dart:math';

import '../../../domain/sudoku_modifier_config.dart';
import '../../../domain/sudoku_modifier_type.dart';
import 'sudoku_modifier.dart';
import 'sudoku_modifier_context.dart';
import 'sudoku_modifier_registry.dart';

class SudokuModifierScheduler {
  SudokuModifierScheduler({
    required SudokuModifierRegistry registry,
    required SudokuModifierContext context,
    required SudokuModifierGlobalConfig config,
    required void Function(SudokuModifierType? modifier) onModifierChanged,
  }) : _registry = registry,
       _context = context,
       _config = config,
       _onModifierChanged = onModifierChanged;

  final SudokuModifierRegistry _registry;
  final SudokuModifierContext _context;
  final SudokuModifierGlobalConfig _config;
  final void Function(SudokuModifierType? modifier) _onModifierChanged;

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

    final int minSeconds = max(0, _config.scheduler.spawnMinSeconds);
    final int maxSeconds = max(minSeconds, _config.scheduler.spawnMaxSeconds);
    final int delaySeconds = _context.randomBetweenInclusive(
      minSeconds,
      maxSeconds,
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

    final List<SudokuModifier> candidates = _buildWeightedCandidates();
    if (candidates.isEmpty) {
      _scheduleNextActivation();
      return;
    }

    final SudokuModifier nextModifier = _pickWeightedModifier(candidates);
    final int durationSeconds = nextModifier.durationSeconds(_context);

    _activeModifier = nextModifier;
    _context.safeSetState(() {
      _onModifierChanged(nextModifier.type);
    });

    nextModifier.onStart(_context);

    _endTimer?.cancel();
    if (!nextModifier.controlsOwnDeactivation) {
      _endTimer = Timer(
        Duration(seconds: max(1, durationSeconds)),
        deactivateCurrentModifier,
      );
    }
  }

  List<SudokuModifier> _buildWeightedCandidates() {
    final List<SudokuModifier> candidates = <SudokuModifier>[];
    for (final SudokuModifier modifier in _registry.modifiers) {
      final ModifierRuntimeConfig runtime = _config.runtimeFor(modifier.type);
      if (!runtime.enabled || runtime.weight <= 0) {
        continue;
      }
      candidates.add(modifier);
    }
    return candidates;
  }

  SudokuModifier _pickWeightedModifier(List<SudokuModifier> candidates) {
    int totalWeight = 0;
    for (final SudokuModifier modifier in candidates) {
      totalWeight += _config.runtimeFor(modifier.type).weight;
    }

    if (totalWeight <= 0) {
      return candidates[_context.random.nextInt(candidates.length)];
    }

    int rolled = _context.random.nextInt(totalWeight);
    for (final SudokuModifier modifier in candidates) {
      rolled -= _config.runtimeFor(modifier.type).weight;
      if (rolled < 0) {
        return modifier;
      }
    }

    return candidates.last;
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
