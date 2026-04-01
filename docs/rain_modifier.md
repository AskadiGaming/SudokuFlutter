# Implementierungsplan: Rain Modifier (Regen ueber den ganzen Bildschirm)

## Ziel
Ein neuer Crazy-Mode-Modifier **"Rain Modifier"** soll waehrend seiner Aktivzeit einen sichtbaren Regeneffekt ueber den **gesamten Spielbildschirm** legen.

Anforderungen:
- Regen deckt den gesamten verfuegbaren Screen-Bereich ab (nicht nur das Sudoku-Grid).
- Effekt ist rein visuell und veraendert keine Sudoku-Logik.
- Eingaben bleiben voll moeglich (`IgnorePointer`).
- Modifier laeuft sauber im bestehenden Scheduler-Lifecycle (start/stop/dispose).

## Ausgangslage im Code
- Modifier-Framework vorhanden: `SudokuModifier`, `SudokuModifierFactory`, `SudokuModifierScheduler`.
- Aktive Modifier werden in `PlaySudokuPage` verwaltet.
- Overlays existieren bereits im Grid (z. B. Goat), aber Rain braucht Screen-Level-Overlay.
- Runtime-Konfiguration liegt in `SudokuModifierGlobalConfig` + `defaultSudokuModifierGlobalConfig`.

## Architekturentscheidung
Rain wird als eigener Modifier plus eigenes Overlay-Rendering umgesetzt:

1. `RainModifier` steuert nur Lifecycle und Partikel-Zustand (spawn/update/clear).
2. Rendering erfolgt in einem dedizierten Rain-Overlay-Widget (oberste Layer in `PlaySudokuPage`).
3. State liegt im `PlaySudokuPage` State und wird ueber `SudokuModifierContext` bereitgestellt.
4. Kein Input-Blocking: Overlay ist immer in `IgnorePointer(ignoring: true)` gekapselt.

## Umsetzungsstrategie (in 11 Schritten)

### 1. Modifier-Typ erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Neues Enum-Element hinzufuegen:
  - `rain`

Ergebnis: Rain ist als reguliererbarer Modifier im System bekannt.

### 2. Konfigurationsmodell erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_config.dart`
- Neue Config-Klasse `RainModifierConfig` einfuehren, z. B.:
  - `runtime` (enabled/weight)
  - `duration` (Range)
  - `spawnMinMilliseconds` / `spawnMaxMilliseconds`
  - `movementTickMilliseconds`
  - `minDropLengthPx` / `maxDropLengthPx`
  - `minSpeedPxPerSecond` / `maxSpeedPxPerSecond`
  - `maxVisibleDrops`
  - `minOpacity` / `maxOpacity`
- `SudokuModifierGlobalConfig` um Feld `rain` erweitern.
- `runtimeFor(...)` um `SudokuModifierType.rain` ergaenzen.

Ergebnis: Rain hat dieselbe konfigurierbare Struktur wie bestehende Modifier.

### 3. Default-Werte hinterlegen
- Datei: `lib/features/sudoku/domain/default_sudoku_modifier_config.dart`
- Sinnvolle Startwerte setzen (z. B. moderate Dichte, mittlere Geschwindigkeit).
- Anfangsgewicht konservativ setzen, damit Effekt nicht ueberhaeufig auftritt.

Ergebnis: Rain kann sofort mit Baseline-Werten im Crazy Mode auftauchen.

### 4. Kontext um Rain-State erweitern
- Datei: `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart`
- Neue Reader/Writer fuer Rain-Daten aufnehmen, z. B.:
  - Viewport-Size fuer Screen-Level-Regen
  - Liste aktiver Regentropfen
  - letzte Update-Zeit
  - laufende IDs
- In `PlaySudokuPage` die dazugehoerigen State-Felder anlegen und in den Context injizieren.

Ergebnis: Modifier und UI arbeiten auf demselben Rain-Zustand.

### 5. Datenmodell fuer Regentropfen definieren
- Neue Datei: `lib/features/sudoku/presentation/modifiers/models/rain_drop.dart`
- Modellfelder z. B.:
  - `id`
  - `x`, `y`
  - `lengthPx`
  - `speedPxPerSecond`
  - `opacity`
  - optional `thicknessPx` / `slant`

Ergebnis: Tropfen-Verhalten ist klar und testbar modelliert.

### 6. RainModifier implementieren
- Neue Datei: `lib/features/sudoku/presentation/modifiers/rain_modifier.dart`
- Responsibilities:
  - Bei `onStart`: Spawn-/Movement-Timer starten.
  - Pro Tick Tropfen bewegen, neue Tropfen spawnen, offscreen Tropfen entfernen.
  - Bei `onStop`: Timer stoppen und Liste leeren.
  - Bei `dispose`: Timer final sauber abbrechen.
- `controlsOwnDeactivation` bleibt standardmaessig `false`, Scheduler steuert Dauer.

Ergebnis: Vollstaendiger Lifecycle analog zu vorhandenen Modifiern.

### 7. Factory/Registry verdrahten
- Datei: `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_factory.dart`
- `RainModifier(config: config.rain)` zur Modifierliste hinzufuegen.

Ergebnis: Scheduler kann Rain normal auswaehlen und aktivieren.

### 8. Screen-Level Overlay im Play Screen einbauen
- Datei: `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `Scaffold`-Body auf `Stack` umstellen (Basis: bisheriger Inhalt, darueber Rain-Overlay).
- Sichtbarkeitsregel:
  - Overlay zeigen, wenn `activeModifier == rain` oder noch Tropfen auslaufen.
- Screen-Size erfassen (z. B. `LayoutBuilder` auf Body-Ebene) und an Rain-State melden.

Ergebnis: Regen ist ueber dem gesamten Spiel sichtbar, nicht nur ueber der Matrix.

### 9. Rain-Overlay-Widget erstellen
- Neue Datei: `lib/features/sudoku/presentation/modifiers/widgets/rain_overlay.dart`
- Rendering per `CustomPaint` (empfohlen fuer viele Linien) oder leichtgewichtigem `Stack`.
- Jeder Tropfen als kurze vertikale/leicht diagonale Linie zeichnen.
- Immer in `IgnorePointer(ignoring: true)` kapseln.

Ergebnis: Performantes, nicht-interaktives Vollbild-Overlay.

### 10. Lokalisierung erweitern
- Dateien: `lib/l10n/app_*.arb`
- Neuer Key:
  - `modifierRainTitle` (z. B. "Rain Modifier")
- Banner-Mapping erweitern, damit Rain korrekt benannt wird.

Ergebnis: Rain erscheint konsistent lokalisiert im Modifier-Banner.

### 11. Tests und Abnahme
- Unit-Tests:
  - Config-Validierung (`min <= max`, positive Werte, etc.).
  - Spawn-/Cleanup-Logik entfernt offscreen Tropfen korrekt.
- Widget-Tests:
  - Overlay ist aktiv bei Rain und ignoriert Pointer.
  - Regen deckt Body-Layer ab (nicht nur Grid-Layer).
  - Nach `onStop` verschwinden Tropfen.
- Manueller Test:
  - 2-3 Minuten Crazy Mode auf verschiedenen Displaygroessen.
  - Fluessigkeit (jank-frei), Lesbarkeit des Grids, keine Input-Probleme.

Ergebnis: Rain ist stabil, performant und UX-sicher.

## Technische Leitplanken
- Nur visueller Effekt, keinerlei Aenderung an Sudoku-Regeln.
- Keine Input-Interferenz (`IgnorePointer`).
- Timer/State muessen bei Stop/Dispose immer sauber beendet werden.
- Dichte/Speed so waehlen, dass Grid noch lesbar bleibt.
- Bei kleineren Geraeten ggf. Partikelzahl dynamisch deckeln.

## Geplante Dateien
- `docs/rain_modifier.md`
- `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- `lib/features/sudoku/domain/sudoku_modifier_config.dart`
- `lib/features/sudoku/domain/default_sudoku_modifier_config.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart`
- `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_factory.dart`
- `lib/features/sudoku/presentation/modifiers/rain_modifier.dart` (neu)
- `lib/features/sudoku/presentation/modifiers/models/rain_drop.dart` (neu)
- `lib/features/sudoku/presentation/modifiers/widgets/rain_overlay.dart` (neu)
- `lib/features/sudoku/presentation/widgets/modifier_banner.dart` (falls Mapping dort zentral ist)
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Der neue Modifier **Rain** im Crazy Mode aktiviert werden kann.
- Waehrend der Aktivzeit ist Regen ueber dem gesamten Spielbildschirm sichtbar.
- Sudoku bleibt waehrenddessen normal bedienbar.
- Der Modifier endet sauber ohne verbleibende Timer/Partikel.
- Rain wird im Banner korrekt lokalisiert angezeigt.
