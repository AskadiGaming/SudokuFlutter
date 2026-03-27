# Implementierungsplan: Crazy Mode mit Modifier-System

## Ziel
Im Quickmatch soll eine zusaetzliche Checkbox **"Crazy Mode aktivieren"** erscheinen.  
Wenn Crazy Mode aktiv ist, werden waehrend der Runde zufaellig Modifier aktiviert, die das Spielverhalten temporaer veraendern.

Rahmenbedingungen:
- Immer nur **ein** Modifier gleichzeitig aktiv.
- Der aktuell aktive Modifier wird stets **oberhalb der 9x9 Sudoku-Matrix** angezeigt.
- Der erste umzusetzende Modifier ist der **Shaking Modifier** (Grid wackelt sichtbar).

## Ausgangslage im Code
- Quickmatch-Start liegt in `QuickmatchPage` in `lib/main.dart`.
- Beim Start wird aktuell `PlaySudokuPage(difficulty: ...)` aufgerufen.
- Die Sudoku-UI liegt in `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Lokalisierung laeuft ueber `lib/l10n/*.arb`.

## Architekturvorschlag (MVP)
Fuer einen schnellen, aber erweiterbaren Einstieg:

1. **Config vom Quickmatch in die Runde geben**
- Neues Config-Objekt fuer den Rundenstart (z. B. `SudokuRoundConfig`) mit mindestens:
  - `SudokuDifficulty difficulty`
  - `bool crazyModeEnabled`
- `QuickmatchPage` erstellt diese Config und uebergibt sie an `PlaySudokuPage`.

2. **Modifier-Domain kapseln**
- Neues Enum `SudokuModifierType` mit erstem Wert `shaking`.
- Optional frueh mitdenken: Erweiterbar fuer spaetere Modifier (`fog`, `swapControls`, ...).

3. **Modifier-Controller in der Spielseite**
- In `PlaySudokuPage` bzw. State-Klasse:
  - `SudokuModifierType? _activeModifier`
  - Timer/Loop fuer zufaellige Aktivierung nur wenn `crazyModeEnabled == true`.
  - Garantiert: vor Aktivierung eines neuen Modifiers muss der alte beendet sein.

## Umsetzungsstrategie (in 8 Schritten)

### 1. Datenmodell fuer Runden-Konfiguration einfuehren
- Neue Datei: `lib/features/sudoku/domain/sudoku_round_config.dart`
- Enthaltene Felder:
  - `difficulty`
  - `crazyModeEnabled` (Default `false`)
- `PlaySudokuPage` Konstruktor von `difficulty` auf `roundConfig` umstellen.

Ergebnis: Der Spielstart kann Features wie Crazy Mode explizit transportieren.

### 2. Quickmatch-UI um Checkbox erweitern
- In `QuickmatchPage` (`lib/main.dart`):
  - Neuer State: `_isCrazyModeEnabled = false`
  - Unterhalb der Schwierigkeit einen `CheckboxListTile` oder `SwitchListTile` einfuegen.
  - Label exakt: **"Crazy Mode aktivieren"** (ueber l10n-Key, nicht hardcodiert).
- Beim Klick auf `Spielen`: `SudokuRoundConfig(..., crazyModeEnabled: _isCrazyModeEnabled)` uebergeben.

Ergebnis: User kann Crazy Mode vor Rundenstart aktivieren/deaktivieren.

### 3. Lokalisierung erweitern
- In allen ARB-Dateien neue Keys anlegen:
  - `quickmatchCrazyModeToggle`
  - `modifierNone` (optional fuer "Kein Modifier aktiv")
  - `modifierShakingTitle` (z. B. "Shaking Modifier")
- Danach `flutter gen-l10n` bzw. normaler Build-Regeneration-Lauf.

Ergebnis: Checkbox und Modifier-Anzeige sind sauber lokalisiert.

### 4. Modifier-Typ und Metadaten definieren
- Neue Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Enum:
  - `shaking`
- Hilfsmethode/Extension fuer Anzeige-Text (ueber l10n im UI gemappt).

Ergebnis: Ein einheitlicher Typ fuer aktive Modifier ist vorhanden.

### 5. Modifier-Lifecycle in PlaySudokuPage einbauen
- In `_PlaySudokuPageState`:
  - `SudokuModifierType? _activeModifier`
  - `Timer? _modifierSpawnTimer`
  - `Timer? _modifierEndTimer`
- Start-Regel (MVP-Vorschlag):
  - Nach zufaelligem Intervall (z. B. 8-20 Sekunden) aktiviert sich ein Modifier.
  - Laufzeit pro Modifier (z. B. 3-6 Sekunden).
  - Danach `_activeModifier = null` und naechstes zufaelliges Intervall planen.
- Nur starten, wenn Puzzle geladen und Crazy Mode aktiv ist.
- In `dispose()` alle Timer sicher abbrechen.

Ergebnis: Zufaellige Modifier koennen robust aktiviert/deaktiviert werden.

### 6. Anzeige des aktiven Modifiers ueber der Matrix
- In `_buildContent(...)` oberhalb des Grid-Containers eine kompakte Statuszeile/Karte einfuegen.
- Anzeige-Logik:
  - Wenn `_activeModifier != null`: deutlicher Text mit aktuellem Modifier.
  - Wenn `null`: optional "Kein Modifier aktiv" oder ausgeblendete Zeile.
- Platzierung strikt **ueber** der Sudoku-Matrix, aber innerhalb der Spiel-Content-Column.

Ergebnis: Der aktive Modifier ist immer sichtbar, wie gefordert.

### 7. Shaking Modifier visuell umsetzen
- In `_buildGrid(...)` die Grid-Widget-Huelle ergaenzen:
  - Bei `shaking` wird das gesamte 9x9 Grid mit horizontal/vertikalem Offset animiert.
- Moegliche MVP-Implementierung:
  - `TweenAnimationBuilder<Offset>` oder `AnimatedBuilder` + `Transform.translate`.
  - Zufalls-Offset in kurzer Frequenz (z. B. alle 40-70ms) mit kleiner Amplitude (2-6 px), damit es klar sichtbar ist, aber spielbar bleibt.
- Wichtig:
  - Nur das Grid wackelt, nicht die gesamte Seite.
  - Touch-Interaktion auf Zellen bleibt erhalten.

Ergebnis: Der erste Modifier erzeugt klaren "verrueckten" Effekt ohne Spiellogik zu brechen.

### 8. Tests und Abnahme
- Widget-Tests Quickmatch:
  - Checkbox vorhanden und toggelbar.
  - Start uebergibt `crazyModeEnabled` korrekt an Runde.
- Widget-/State-Tests PlaySudoku:
  - Bei deaktiviertem Crazy Mode kein Modifier-Lifecycle.
  - Bei aktiviertem Crazy Mode wird maximal ein Modifier gleichzeitig aktiv.
  - Modifier-Banner reagiert auf Statuswechsel.
- Manueller Test:
  - 2-3 Minuten Spielzeit, mehrfaches Auftreten des Shaking Modifiers pruefen.

Ergebnis: Verhalten ist stabil und regressionsarm.

## Technische Leitplanken
- "Nur ein Modifier gleichzeitig" wird zentral ueber `_activeModifier` abgesichert.
- Keine Modifier-Aktivierung vor fertigem Puzzle-Load.
- Timer muessen bei `dispose()` sauber gestoppt werden, um Memory Leaks und setState-Fehler zu vermeiden.
- Modifier-System so schneiden, dass spaeter weitere Modifier ohne Umbau der Core-Logik ergaenzt werden koennen.

## Geplante Dateien
- `docs/modifier.md`
- `lib/main.dart`
- `lib/features/sudoku/domain/sudoku_round_config.dart` (neu)
- `lib/features/sudoku/domain/sudoku_modifier_type.dart` (neu)
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`

## Akzeptanzkriterien (MVP)
Das Ziel gilt als erreicht, wenn:
- Im Quickmatch ist die Checkbox **"Crazy Mode aktivieren"** vorhanden.
- Die Checkbox beeinflusst den Rundenstart (`an`/`aus`) korrekt.
- Bei aktivem Crazy Mode erscheinen zufaellige Modifier waehrend der Runde.
- Es ist niemals mehr als ein Modifier gleichzeitig aktiv.
- Der aktive Modifier wird sichtbar oberhalb der Sudoku-Matrix angezeigt.
- Der `Shaking Modifier` laesst das 9x9 Grid waehrend seiner Aktivzeit deutlich wackeln.

## Ausbau nach MVP
- Weitere Modifier-Typen (z. B. invertierte Steuerung, temporare Zellabdeckung).
- Gewichte pro Modifier (haeufig/selten) statt Gleichverteilung.
- Difficulty-abhaengige Modifier-Intensitaet.
- Optionaler "Crazy Score Bonus" fuer aktive Modifier-Zeiten.
