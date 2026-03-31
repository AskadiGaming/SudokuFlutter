# Implementierungsplan: Text Rotation Modifier (360° pro Zahl)

## Ziel
Ein neuer Crazy-Mode-Modifier mit dem Namen **"Text Rotation Modifier"** soll nur die **ausgefuellten Zahlen** der Sudoku-Matrix drehen.

Pflichtanforderungen:
- Nur Zellen mit `value != 0` werden animiert.
- Jede betroffene Zahl rotiert **genau einmal um 360 Grad**.
- Die Rotationsrichtung wird **pro Zahl zufaellig** bestimmt:
  - clockwise oder counter-clockwise.
- Jede Zahl darf eine andere Richtung haben.
- Das Spiel bleibt waehrend der Animation voll spielbar.
- Nach Ende der Animation bleibt die Matrix selbst unveraendert (nur visueller Effekt auf Text).

## Ausgangslage im Code
- Modifier-Framework ist vorhanden (`SudokuModifier`, `SudokuModifierScheduler`, `SudokuModifierRegistry`).
- Es gibt bereits Rotationscontroller fuer Matrixrotation (`rotationController`, `rotation90Controller`).
- Die Zahlen werden in `lib/features/sudoku/presentation/widgets/sudoku_grid.dart` in jeder Zelle gerendert.
- Aktive Modifier werden ueber `ModifierBanner` angezeigt.

## Architekturentscheidung
Da nur Text rotieren soll, wird der Modifier als **reiner Darstellungs-Modifier** umgesetzt:

1. Keine Rotation von `currentGrid` oder `isFixed`.
2. Ein eigener `AnimationController` steuert den Fortschritt `0..1`.
3. Pro Zelle wird eine stabile Richtung hinterlegt (`+1` oder `-1`), damit die Richtung waehrend einer Aktivierung nicht bei jedem Rebuild wechselt.
4. Winkel je Zelle: `angle = direction * progress * 2*pi`.

## Umsetzungsstrategie (in 10 Schritten)

### 1. Modifier-Typ erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Neues Enum-Element einfuegen:
  - `textRotation`

Ergebnis: Der Modifier ist im Domain-Modell bekannt.

### 2. Lokalisierung ergaenzen
- In allen ARB-Dateien neuen Key anlegen:
  - `modifierTextRotationTitle` (z. B. "Text Rotation Modifier")
- L10n-Regeneration ausfuehren.

Ergebnis: Banner kann den neuen Modifier lokalisiert anzeigen.

### 3. Banner-Mapping erweitern
- Datei: `lib/features/sudoku/presentation/widgets/modifier_banner.dart`
- Neuen `switch`-Fall aufnehmen:
  - `textRotation -> l10n.modifierTextRotationTitle`

Ergebnis: Aktiver Text-Rotations-Modifier ist sichtbar.

### 4. Modifier-Klasse anlegen
- Neue Datei: `lib/features/sudoku/presentation/modifiers/text_rotation_modifier.dart`
- Implementierung analog zu bestehenden Modifiern (`rotation_360_modifier.dart`).
- Dauerempfehlung: 4-7 Sekunden fuer gute Lesbarkeit.

Ergebnis: Lifecycle (start/stop) ist zentral und sauber gekapselt.

### 5. Kontext um Text-Rotationszustand erweitern
- Datei: `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart`
- Ergaenzen:
  - `AnimationController textRotationController`
  - Zugriff auf eine Map fuer Zellrichtungen, z. B. `Map<int, int>` (Index 0..80 -> `-1`/`+1`)
- Im `PlaySudokuPage` State entsprechende Felder anlegen und in den Context injecten.

Ergebnis: Modifier und Grid greifen auf dieselbe Animations- und Richtungsquelle zu.

### 6. Zufallsrichtung pro gefuellter Zelle setzen
- Beim `onStart` des Modifiers:
  - Richtungsmap leeren.
  - Fuer alle 81 Zellen mit `value != 0` Richtung zufaellig bestimmen (`random.nextBool() ? 1 : -1`).
- Optional fuer waehrenddessen neu befuellte Zellen:
  - Bei erster Darstellung lazy Richtung vergeben, falls noch nicht vorhanden.

Ergebnis: Jede Zahl hat waehrend einer Aktivierung eine stabile, individuell zufaellige Drehrichtung.

### 7. Controller starten und stoppen
- `onStart`:
  - `textRotationController.reset()`
  - `textRotationController.forward()`
- `onStop`:
  - Controller stoppen/resetten
  - Richtungsmap aufraeumen

Ergebnis: Keine Zustandslecks zwischen Modifier-Runden.

### 8. SudokuGrid um Textrotation erweitern
- Datei: `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`
- Neue Eingaben am Widget:
  - `AnimationController textRotationController`
  - Richtungsmap
- Renderregel fuer Zelltext:
  - Nur wenn `activeModifier == SudokuModifierType.textRotation` und `value != 0`.
  - Winkel je Text: `direction * controller.value * (2 * pi)`.
  - `Transform.rotate` direkt um den `Text` anwenden.
- Grid-HitTests unveraendert lassen.

Ergebnis: Es rotieren nur Zahlen, nicht das Board.

### 9. Registry und Verdrahtung abschliessen
- Datei: `lib/features/sudoku/presentation/play_sudoku_page.dart`
- Neuen Controller initialisieren/disposen.
- `TextRotationModifier()` in `SudokuModifierRegistry` aufnehmen.
- `SudokuGrid`-Parameter durchreichen.

Ergebnis: Modifier kann vom Scheduler zufaellig aktiviert werden.

### 10. Tests und Abnahme
- Unit-Tests Modifier:
  - Bei Start entstehen Richtungen nur fuer `value != 0`.
  - Richtungen sind nur `-1` oder `+1`.
- Widget-Tests:
  - Banner zeigt `modifierTextRotationTitle`.
  - Bei aktivem Modifier rotiert Text, Board selbst bleibt ortsfest.
  - Eingaben waehrend Animation funktionieren.
- Manueller Test:
  - Mehrfache Aktivierung pruefen.
  - Kombination mit `shaking`, `rotation360`, `rotation90`, `goat` ohne Seiteneffekte.

Ergebnis: Verhalten entspricht exakt der Produktanforderung.

## Technische Leitplanken
- Nur ein aktiver Modifier gleichzeitig (bestehende Regel).
- Keine Mutation von Sudoku-Logikdaten fuer diesen Effekt.
- Zufallsrichtung darf pro Aktivierung neu sein, aber innerhalb einer Aktivierung stabil bleiben.
- Alle Controller/Listener in `dispose()` sauber aufraeumen.

## Geplante Dateien
- `docs/text_rotation_modifier.md`
- `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- `lib/features/sudoku/presentation/modifiers/text_rotation_modifier.dart`
- `lib/features/sudoku/presentation/modifiers/core/sudoku_modifier_context.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`
- `lib/features/sudoku/presentation/widgets/modifier_banner.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Der neue Modifier **"Text Rotation Modifier"** existiert und im Crazy Mode auftaucht.
- Nur ausgefuellte Zahlen drehen sich.
- Jede betroffene Zahl dreht sich genau einmal um 360 Grad.
- Die Richtung ist pro Zahl zufaellig und kann zwischen Zahlen unterschiedlich sein.
- Die Matrixpositionen bleiben unveraendert.
- Das Spiel bleibt waehrend des Effekts normal bedienbar.
