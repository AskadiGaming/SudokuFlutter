import '../../../domain/sudoku_modifier_config.dart';
import '../goat_modifier.dart';
import '../rotation_360_modifier.dart';
import '../rotation_90_modifier.dart';
import '../shaking_modifier.dart';
import '../text_rotation_modifier.dart';
import 'sudoku_modifier.dart';
import 'sudoku_modifier_registry.dart';

class SudokuModifierFactory {
  SudokuModifierFactory({required this.config});

  final SudokuModifierGlobalConfig config;

  SudokuModifierRegistry buildRegistry() {
    final List<SudokuModifier> modifiers = <SudokuModifier>[
      ShakingModifier(config: config.shaking),
      Rotation360Modifier(config: config.rotation360),
      Rotation90Modifier(config: config.rotation90),
      GoatModifier(config: config.goat),
      TextRotationModifier(config: config.textRotation),
    ];

    return SudokuModifierRegistry(modifiers: modifiers);
  }
}
