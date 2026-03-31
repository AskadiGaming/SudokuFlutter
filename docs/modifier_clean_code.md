# Implementierungsplan: Clean-Code-Refactoring fuer Screens und Modifier

## Ziel
Der bestehende Code soll deutlich lesbarer, modularer und einfacher erweiterbar werden.
Fokus dieses Plans:
- Hauptscreens in eigene Dateien aufteilen: `Quickmatch`, `Duell`, `Einstellungen`
- Modifier-System aufsplitten: pro Modifier eine eigene Datei
- `PlaySudokuPage` entlasten und auf Orchestrierung reduzieren
- Struktur vorbereiten, damit neue Modifier spaeter mit minimalem Aufwand hinzukommen

Nicht-Ziel in diesem Schritt:
- Keine funktionalen Produktaenderungen
- Kein Redesign der UI
- Keine Aenderung am Nutzerfluss

## Aktuelle Ausgangslage
- `lib/main.dart` enthaelt neben App-Bootstrap auch Navigation, Theme-Logik und mehrere Seiten-Widgets.
- `lib/features/sudoku/presentation/play_sudoku_page.dart` ist sehr umfangreich und enthaelt UI, Modifier-Lifecycle und konkrete Effektimplementierungen.
- Modifier sind aktuell direkt in `PlaySudokuPage` implementiert (shaking, 360, 90, goat).

## Zielarchitektur (nach Refactoring)

### 1. App/Screens trennen
Vorgeschlagene Struktur:

```text
lib/
  app/
    app.dart
    main_navigation_page.dart
    theme/
      app_theme.dart
  features/
    duell/
      presentation/
        duell_page.dart
    quickmatch/
      domain/
        quickmatch_difficulty.dart
      presentation/
        quickmatch_page.dart
    settings/
      domain/
        language_option.dart
      presentation/
        settings_page.dart
```

### 2. Modifier-System trennen (eine Datei pro Modifier)
Vorgeschlagene Struktur:

```text
lib/features/sudoku/
  domain/
    sudoku_modifier_type.dart
  presentation/
    play_sudoku_page.dart
    modifiers/
      core/
        sudoku_modifier.dart
        sudoku_modifier_context.dart
        sudoku_modifier_registry.dart
        sudoku_modifier_scheduler.dart
      models/
        flying_goat.dart
      shaking_modifier.dart
      rotation_360_modifier.dart
      rotation_90_modifier.dart
      goat_modifier.dart
```

Hinweis:
- Datei pro Modifier ist explizit abgedeckt.
- Gemeinsame Vertrage/Context liegen in `core/`, damit Modifier nicht voneinander abhaengig werden.

## Designprinzipien fuer das Refactoring
- Single Responsibility: Jede Datei hat genau eine klar erkennbare Aufgabe.
- Composition statt monolithischer State-Klasse.
- Keine zyklischen Abhaengigkeiten zwischen Modifiern.
- Neue Modifier muessen ohne Aenderung an bestehender Modifier-Logik hinzufuegbar sein.
- Verhalten bleibt waehrend Refactoring stabil (Strangler-Ansatz in kleinen Schritten).

## Umsetzungsplan in Phasen

### Phase 0 - Sicherheitsnetz und Vorbereitung
1. Bestehende Tests ausfuehren und Status festhalten.
2. Zusatztickets fuer fehlende Tests anlegen (insb. Modifier-Lifecycle, Rotation90-Commit, Goat-Overlay).
3. Baseline fuer manuelle Checks dokumentieren:
- Quickmatch startet Runde
- Crazy Mode aktiviert Modifier
- Jeder Modifier laeuft wie bisher

Ergebnis:
Refactoring startet mit klarer Baseline.

### Phase 1 - `main.dart` entlasten und Screens auslagern
1. `app.dart` einfuehren und App-Setup aus `main.dart` auslagern.
2. `MainNavigationPage` in `app/main_navigation_page.dart` verschieben.
3. Screens aufteilen:
- `DuellPage` nach `features/duell/presentation/duell_page.dart`
- `QuickmatchPage` nach `features/quickmatch/presentation/quickmatch_page.dart`
- `SettingsPage` nach `features/settings/presentation/settings_page.dart`
4. `QuickmatchDifficulty` aus `main.dart` in `features/quickmatch/domain/quickmatch_difficulty.dart` verschieben.
5. Theme-Enum, Mapping und ThemeFactory aus `main.dart` in `app/theme/app_theme.dart` extrahieren.

Ergebnis:
`main.dart` ist nur noch Bootstrap, alle Hauptscreens sind in eigenen Dateien.

### Phase 2 - PlaySudoku in Schichten schneiden
1. In `play_sudoku_page.dart` nur noch Kernzustand und Seitenlayout behalten.
2. UI-Teile in eigene Dateien auslagern, z. B.:
- `widgets/sudoku_grid.dart`
- `widgets/modifier_banner.dart`
- `widgets/number_pad.dart`
3. Hilfsfunktionen wie Zellrahmen, Button-Labels und kleinere Mapping-Logik aus der State-Klasse herausziehen.

Ergebnis:
`PlaySudokuPage` wird lesbar und orchestriert nur noch.

### Phase 3 - Modifier-Core abstrahieren
1. Contract `SudokuModifier` definieren, z. B. mit Methoden:
- `type`
- `duration`
- `onStart(context)`
- `onTick(context, dt)` (optional)
- `onStop(context)`
2. `SudokuModifierContext` bereitstellen mit minimal noetigen Hooks:
- Zugriff auf Grid-State
- Zugriff auf Animation/Timer-Schnittstellen
- sichere `setState`-Bruecke
3. `SudokuModifierRegistry` einfuehren:
- Liste registrierter Modifier
- ggf. Gewichtung fuer spaetere Spawn-Logik
4. `SudokuModifierScheduler` auslagern:
- Spawn-Intervalle
- Aktivieren/Deaktivieren
- Sicherstellen: maximal ein aktiver Modifier

Ergebnis:
Modifier-Lifecycle ist zentral und testbar, nicht mehr in UI vergraben.

### Phase 4 - Eine Datei pro Modifier umsetzen
Modifier nacheinander migrieren, jeweils ohne Verhaltensaenderung:
1. `shaking_modifier.dart`
2. `rotation_360_modifier.dart`
3. `rotation_90_modifier.dart`
4. `goat_modifier.dart`

Dazu:
- Modifier-spezifische Modelle (z. B. `FlyingGoat`) in eigene Model-Datei.
- Modifier-spezifische Konstanten in die jeweilige Modifier-Datei (oder lokales `*_config.dart`).
- Anzeige-Label weiter ueber `SudokuModifierType` plus l10n-Mapping.

Ergebnis:
Jeder Modifier ist physisch getrennt und isoliert wartbar.

### Phase 5 - Integration und Aufraeumen
1. Alte Modifier-Methoden aus `PlaySudokuPage` entfernen.
2. Doppelte Utilities zusammenfassen.
3. Imports bereinigen, ungenutzte Felder/Timer entfernen.
4. Linting/Formatting ausfuehren.

Ergebnis:
Sauberer Endzustand ohne Altlasten.

### Phase 6 - Verifikation
1. Tests aktualisieren/erweitern:
- Unit-Tests fuer Scheduler/Registry
- Unit-Tests pro Modifier (Start/Stop-Effekte)
- Widget-Tests fuer Banner-Status und Overlay
2. Manuelle Smoke-Tests fuer alle Modifier und alle drei Hauptscreens.
3. Optional: kurze Performance-Pruefung fuer Goat-Modifier (Frame-Stabilitaet).

Ergebnis:
Refactoring ist funktional stabil und regressionsarm.

## Konkrete Ticket-Zuschnitte (empfohlen)
1. Ticket A: `main.dart` entschlacken + Screen-Dateien anlegen
2. Ticket B: Theme + Settings-Domain trennen
3. Ticket C: PlaySudoku-UI in Widgets auslagern
4. Ticket D: Modifier-Core (Contract + Context + Scheduler)
5. Ticket E: Shaking migrieren
6. Ticket F: Rotation360 migrieren
7. Ticket G: Rotation90 migrieren
8. Ticket H: Goat migrieren
9. Ticket I: Cleanup + Tests + Doku

## Definition of Done
- `Quickmatch`, `Duell`, `Einstellungen` liegen in separaten Dateien.
- Pro Modifier existiert genau eine eigene Datei.
- `PlaySudokuPage` enthaelt keine modifier-spezifischen Implementierungsdetails mehr.
- Neuer Modifier kann hinzugefuegt werden, ohne bestehende Modifier-Dateien zu editieren.
- Alle bestehenden Funktionen laufen unveraendert.
- Tests und manuelle Checks sind gruen.

## Risiken und Gegenmassnahmen
- Risiko: Refactoring aendert unbemerkt Verhalten.
  Gegenmassnahme: kleine Commits, pro Phase Tests + manueller Smoke-Test.

- Risiko: Zu fruehe Generalisierung im Modifier-API.
  Gegenmassnahme: API minimal halten und nur fuer aktuelle 4 Modifier designen.

- Risiko: Hohe Komplexitaet durch Timer/Animation.
  Gegenmassnahme: Scheduler zentralisieren, Modifier nur fuer ihren Effekt verantwortlich machen.

## Reihenfolge-Empfehlung
1. Erst Screens auslagern (`Quickmatch`, `Duell`, `Einstellungen`).
2. Dann `PlaySudokuPage` UI aufraeumen.
3. Danach Modifier-Core und Modifier-Dateien migrieren.

So bleibt die Aenderung nachvollziehbar und das Risiko pro Schritt klein.
