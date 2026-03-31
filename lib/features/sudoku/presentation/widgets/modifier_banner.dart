import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../domain/sudoku_modifier_type.dart';

class ModifierBanner extends StatelessWidget {
  const ModifierBanner({required this.activeModifier, super.key});

  final SudokuModifierType? activeModifier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    String label = l10n?.modifierNone ?? 'No modifier active';
    switch (activeModifier) {
      case SudokuModifierType.shaking:
        label = l10n?.modifierShakingTitle ?? 'Shaking Modifier';
        break;
      case SudokuModifierType.rotation360:
        label = l10n?.modifier360Title ?? '360 Modifier';
        break;
      case SudokuModifierType.rotation90:
        label = l10n?.modifier90Title ?? '90 Modifier';
        break;
      case SudokuModifierType.goat:
        label = l10n?.modifierGoatTitle ?? 'Goat Modifier';
        break;
      case SudokuModifierType.textRotation:
        label = l10n?.modifierTextRotationTitle ?? 'Text Rotation Modifier';
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
}
