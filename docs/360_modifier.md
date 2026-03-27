# Implementierungsplan: 360 Modifier (rotierende Sudoku-Matrix)

## Ziel
Ein neuer Modifier mit dem Namen **"360 Modifier"** soll in Crazy Mode verfuegbar sein.  
Wenn aktiv, dreht sich die Sudoku-Matrix langsam um **360 Grad**, waehrend das Spiel ganz normal bedienbar bleibt (Zellen antippen, Zahlen setzen/loeschen).

## Ausgangslage im Code
- Modifier-Lifecycle ist bereits in `lib/features/sudoku/presentation/play_sudoku_page.dart` vorhanden.
- Aktuell existiert nur `SudokuModifierType.shaking`.
- Der aktive Modifier wird bereits oberhalb der Matrix als Banner angezeigt.
- Es gilt bereits die Regel: immer nur ein Modifier gleichzeitig.

## Architekturansatz
Der neue Modifier wird in das bestehende System integriert, ohne neue Grundarchitektur:

1. `SudokuModifierType` um `rotation360` erweitern.
2. Lifecycle waehlt zufaellig zwischen `shaking` und `rotation360`.
3. Fuer `rotation360` laeuft eine zeitbasierte Rotationsanimation ueber die Matrix.
4. Hit-Testing bleibt aktiv, damit Eingaben waehrend der Drehung funktionieren.

## Umsetzungsstrategie (in 9 Schritten)

### 1. Modifier-Typ erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Enum erweitern um:
  - `rotation360`

Ergebnis: Der neue Modifier ist im Domain-Modell verankert.

### 2. Lokalisierung fuer den Namen ergaenzen
- In allen ARB-Dateien neuen Key anlegen:
  - `modifier360Title` (z. B. "360 Modifier")
- L10n-Regeneration ausfuehren.

Ergebnis: Banner kann den neuen Modifier lokalisiert anzeigen.

### 3. Banner-Textmapping erweitern
- Datei: `lib/features/sudoku/presentation/play_sudoku_page.dart`
- In `_buildModifierBanner(...)` den neuen Fall abbilden:
  - `rotation360 -> l10n.modifier360Title`

Ergebnis: Bei Aktivierung wird der korrekte Name angezeigt.

### 4. Zustand fuer Rotation einfuehren
- In `_PlaySudokuPageState` ergaenzen:
  - `AnimationController _rotationController` (mit `SingleTickerProviderStateMixin`)
  - optional Getter `double _rotationAngle`
- Controller-Lebensdauer sauber in `initState()`/`dispose()` verwalten.

Ergebnis: Es gibt eine robuste, fluide Animationsquelle statt Timer-Jitter.

### 5. Modifier-Auswahl zufaellig machen
- In `_activateRandomModifier()` nicht mehr hardcodiert `shaking` setzen.
- Kandidatenliste:
  - `SudokuModifierType.shaking`
  - `SudokuModifierType.rotation360`
- Auswahl per `Random`.

Ergebnis: Beide Modifier koennen im Crazy Mode auftreten.

### 6. Rotation starten/stoppen
- Beim Aktivieren von `rotation360`:
  - Controller auf `0.0` setzen und vorwaerts bis `1.0` animieren.
  - Dauer so waehlen, dass exakt eine langsame volle Drehung entsteht
    (Empfehlung: 8-12 Sekunden; final ueber Playtest festlegen).
- Beim Deaktivieren:
  - Rotation stoppen/resetten.
  - Sicherstellen, dass kein alter Zustand in den naechsten Modifier "durchlaeuft".

Ergebnis: Der Modifier fuehrt genau eine kontrollierte 360-Grad-Drehung aus.

### 7. Matrix visuell rotieren
- In `_buildGrid(...)` die bestehende Grid-Huelle erweitern:
  - `Transform.rotate(angle: _rotationAngle, transformHitTests: true, alignment: Alignment.center)`
- Rotation nur anwenden, wenn `_activeModifier == SudokuModifierType.rotation360`.
- Bestehendes Shaking-Verhalten unveraendert lassen.

Ergebnis: Matrix dreht sich sichtbar, Interaktion bleibt an der transformierten Position moeglich.

### 8. Spielbarkeit waehrend Drehung absichern
- UX/Technik-Pruefpunkte:
  - Zell-Taps funktionieren waehrend der Animation.
  - Zahlentoggle unten bleibt unveraendert bedienbar.
  - Keine UI-Blockade durch Pointer-absorbing Widgets.
  - Matrix bleibt vollstaendig sichtbar (bei Bedarf minimal skalieren oder Layoutabstaende leicht erhoehen).

Ergebnis: Kernanforderung "normal weiterspielen waehrend Drehung" ist erfuellt.

### 9. Tests und Abnahme
- Unit/Widget-Tests:
  - Modifier-Auswahl umfasst `rotation360`.
  - Banner zeigt `modifier360Title`, wenn aktiv.
  - Aktiv/Deaktivierung setzt Rotationszustand korrekt.
- Manuelle Tests (mind. 2-3 Minuten):
  - Mehrfaches Auftreten des 360 Modifiers.
  - Waehrend Rotation mehrere Zahlen korrekt setzen/loeschen.
  - Wechsel zwischen `shaking` und `rotation360` ohne visuelle Artefakte.

Ergebnis: Funktion ist stabil und regressionsarm.

## Technische Leitplanken
- Weiterhin maximal ein aktiver Modifier ueber `_activeModifier`.
- Rotation nicht per `Timer.periodic`, sondern per `AnimationController` (fluessiger, wartbarer).
- Alle laufenden Animationen/Timer in `dispose()` sauber beenden.
- Keine Aenderung an Sudoku-Regeln oder Eingabelogik; nur visuelle Matrix-Transformation.

## Geplante Dateien
- `docs/360_modifier.md`
- `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Es existiert ein neuer Crazy-Mode-Modifier namens **"360 Modifier"**.
- Bei Aktivierung dreht sich die Sudoku-Matrix langsam um 360 Grad.
- Das Spiel bleibt waehrend der Drehung normal spielbar (Zellen antippbar, Zahlen setzbar/loeschbar).
- Es ist weiterhin nie mehr als ein Modifier gleichzeitig aktiv.
- Der aktive Modifier wird korrekt oberhalb der Matrix angezeigt.

## Optionaler Ausbau
- Schwierigkeit beeinflusst Drehgeschwindigkeit (z. B. schneller bei `hard/extreme`).
- Gewichtete Spawn-Wahrscheinlichkeiten pro Modifier.
- Sanftes Ein-/Ausblenden der Rotation (Ease-In/Ease-Out) fuer bessere Lesbarkeit.
