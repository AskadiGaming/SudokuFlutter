# Globale Modifier-Konfiguration

## Status
Die zentrale Modifier-Konfiguration ist umgesetzt.

## Source of Truth
- `lib/features/sudoku/domain/sudoku_modifier_config.dart`
- `lib/features/sudoku/domain/default_sudoku_modifier_config.dart`

Alle Laufzeitwerte fuer Modifier und Scheduler werden hier definiert:
- Aktivierung (`enabled`)
- Gewichtung (`weight`)
- Spawn-Intervall des Schedulers
- Dauer pro Modifier
- Modifier-spezifische Parameter (z. B. Goat Spawn/Speed/Size)

## Verdrahtung
- `PlaySudokuPage` verwendet zentral `defaultSudokuModifierGlobalConfig`.
- `SudokuModifierFactory` erstellt Modifier-Instanzen aus der Config.
- `SudokuModifierScheduler` liest Spawn-Werte, filtert nach `enabled` und waehlt gewichtet nach `weight`.
- Alle Modifier lesen ihre Parameter aus ihrem Config-Block statt aus lokalen `static const` Laufzeitwerten.

## Relevante Dateien
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_factory.dart`
- `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_scheduler.dart`
- `lib/features/sudoku/presentation/modifiers/shaking_modifier.dart`
- `lib/features/sudoku/presentation/modifiers/rotation_360_modifier.dart`
- `lib/features/sudoku/presentation/modifiers/rotation_90_modifier.dart`
- `lib/features/sudoku/presentation/modifiers/text_rotation_modifier.dart`
- `lib/features/sudoku/presentation/modifiers/goat_modifier.dart`

## Tuning-Workflow
1. Werte in `default_sudoku_modifier_config.dart` anpassen.
2. Optional Tests in `test/sudoku_modifier_config_test.dart` und `test/sudoku_modifier_scheduler_test.dart` erweitern.
3. `flutter test` ausfuehren.

## Guardrails
- Neue Modifier duerfen keine versteckten Laufzeit-Hardcodes enthalten.
- Neue Laufzeitparameter muessen in `SudokuModifierGlobalConfig` aufgenommen werden.
- `weight` darf nicht negativ sein.
- Bereiche wie `min <= max` muessen validiert werden.
