# Implementierungsplan: Sudoku-Finish-Sequenz mit Schnecken-Animation und Replay

## Ziel
Wenn ein Sudoku komplett und korrekt geloest wurde, soll nicht sofort zurueck navigiert werden, sondern eine Finish-Sequenz starten:
1. Die 81 Felder verschwinden nacheinander in einer Schnecken-/Spiral-Reihenfolge.
2. Startfeld ist immer links oben (`row=0`, `col=0`).
3. Nach dem letzten Feld erscheint der Text `Sudoku geloest`.
4. Darunter erscheint ein Button `Erneut spielen`.
5. `Erneut spielen` startet direkt eine neue Sudoku-Runde und beruecksichtigt weiterhin die bestehende Werbelogik (Ad bei jeder 10. Runde).

## Ist-Zustand
- In `PlaySudokuPage` werden Eingaben in `_writeActiveNumberToCell(...)` geschrieben, aber es gibt noch keine Gewinnpruefung.
- Das Grid wird ueber `SudokuGrid` gerendert; eine Finish-Overlay-Logik existiert aktuell nicht.
- Die Werbelogik sitzt in `QuickmatchPage` via `ShowAdBeforeRoundUseCase` und `SharedPrefsAdRoundCounterStore` (`minRoundsBetweenAds: 10`).

## Fachliche Entscheidungen (MVP)
1. Gewinnbedingung: Sudoku gilt als geloest, wenn jede Zelle befuellt ist und `currentGrid` exakt `solutionGrid` entspricht.
2. Interaktion waehrend Sequenz: Grid + NumberPad sind waehrend der Finish-Sequenz deaktiviert.
3. Reihenfolge der Felder: Spiralpfad (clockwise), Start links oben.
4. Animationsende: Erst nach Verschwinden aller 81 Felder wird das End-Overlay gezeigt.
5. Replay-Start soll denselben Start-Flow wie Quickmatch verwenden, damit Ads, Zaehler und Fail-Open unveraendert korrekt bleiben.
6. Bei `Erneut spielen` bleibt die ausgewaehlte Schwierigkeit erhalten, aber es wird ein neuer Sudoku-String aus dem Pool dieser Schwierigkeit geladen (keine Wiederverwendung des alten Puzzles).

## Umsetzungsstrategie (8 Schritte)

### 1. Rundenstart-Flow zentralisieren (wichtig fuer Replay + Ads)
- Aktuell ist der Start in `QuickmatchPage._startQuickmatchRound()` direkt verdrahtet.
- Einen gemeinsamen Round-Starter einfuehren, z. B.:
  - `lib/features/quickmatch/application/quickmatch_round_starter.dart`
- Verantwortung:
  - `ShowAdBeforeRoundUseCase.execute()` ausfuehren
  - danach `PlaySudokuPage` mit passender `SudokuRoundConfig` starten
- `QuickmatchPage` nutzt diesen Starter statt lokaler Logik.

Ergebnis: Derselbe Flow kann spaeter vom `Erneut spielen`-Button wiederverwendet werden, inkl. Ad-bei-10.

### 2. Finish-State in `PlaySudokuPage` einfuehren
- Neue States/Felder in `_PlaySudokuPageState`, z. B.:
  - `_isSolved`
  - `_isFinishSequenceRunning`
  - `_visibleCellIndices` oder `_hiddenCellIndices`
  - `_showSolvedOverlay`
- Nach jedem validen Schreibvorgang in `_writeActiveNumberToCell(...)` Gewinn pruefen.
- Bei Gewinn einmalig Finish-Sequenz starten (Guard gegen Mehrfachtrigger).

Ergebnis: Loesung wird erkannt und in einen kontrollierten Endzustand ueberfuehrt.

### 3. Spiralreihenfolge (Schnecke) deterministisch berechnen
- Helper einbauen, z. B. in `play_sudoku_page.dart` oder als Domain-Helper:
  - `List<int> buildSpiralOrder9x9()`
- Erwartete Reihenfolge:
  - Start: `(0,0)`
  - dann obere Reihe nach rechts, rechte Spalte nach unten, untere Reihe nach links, linke Spalte nach oben, usw.
- Ausgabe als lineare Zellindizes (`row * 9 + col`) fuer einfache Verwendung im Grid.

Ergebnis: Eindeutiger, testbarer Pfad fuer das nacheinander Verschwinden.

### 4. Grid um "Zelle unsichtbar" erweitern
- `SudokuGrid` erhaelt neue Eingabe, z. B. `hiddenCellIndices` oder `isCellVisible(row,col)`.
- Rendering pro Zelle:
  - sichtbare Zellen normal
  - versteckte Zellen transparent (oder Scale->0) und ohne Tap-Interaktion
- Bestehende Modifier-Effekte nicht brechen:
  - Prioritaet: Finish-Sequenz deaktiviert aktive Spielinteraktion
  - visuelle Effekte duerfen weiterlaufen oder beim Finish sauber gestoppt werden (einheitlich entscheiden)

Ergebnis: Einzelne Felder koennen gezielt ausgeblendet werden.

### 5. Finish-Sequenz zeitlich ablaufen lassen
- In `PlaySudokuPage` die Spiral-Liste schrittweise abarbeiten:
  - z. B. `Timer.periodic` oder `Future`-Loop mit `await Future.delayed(...)`
- Pro Tick:
  - naechstes Spiral-Feld ausblenden
  - `setState`
- Nach 81 Schritten:
  - `_showSolvedOverlay = true`

Ergebnis: Sichtbare Animation "Feld nach Feld verschwindet" bis komplett leer.

### 6. End-Overlay mit CTA bauen
- Unter/ueber dem leeren Grid ein klares End-UI anzeigen:
  - Text: `Sudoku geloest`
  - Button: `Erneut spielen`
- Der Button triggert den zentralen Round-Starter mit derselben Schwierigkeit/Crazy-Mode-Konfiguration wie die aktuelle Runde.
- Beim Neustart wird kein bestehender Puzzle-String recycelt, sondern eine neue Runde ueber den normalen Ladepfad gestartet, damit ein neuer String derselben Schwierigkeit gezogen wird.
- Optional: Button waehrend Start-Flow laden/deaktivieren (Doppelklickschutz).

Ergebnis: Spieler kann ohne Umweg direkt weiter spielen.

### 7. Werbelogik fuer Replay sicherstellen
- Replay darf nicht am Ad-Flow vorbeigehen.
- Technisch sicherstellen, dass `Erneut spielen` denselben Use Case nutzt wie Quickmatch (`ShowAdBeforeRoundUseCase`).
- Erwartung:
  - Runde 10/20/30 ... zeigt weiterhin Ad
  - bei Ad-Fehler startet Runde trotzdem

Ergebnis: Keine Inkonsistenz zwischen erstem Spielstart und Replay.

### 8. Tests und Abnahme
- Unit-Tests:
  - Gewinnpruefung (voll + korrekt / voll + falsch / unvollstaendig)
  - Spiralreihenfolge (`first == (0,0)`, Laenge 81, keine Duplikate)
- Widget-Tests:
  - bei geloestem Sudoku startet Sequenz
  - nach Sequenz erscheint `Sudoku geloest` + `Erneut spielen`
  - Interaktion im Grid waehrend Sequenz deaktiviert
- Integrationsnah:
  - `Erneut spielen` triggert Round-Starter inkl. Ad-Use-Case
  - Ads kommen weiterhin bei jeder 10. Runde

Ergebnis: Finish-Flow ist stabil und regressionsarm.

## Geplante Dateien (voraussichtlich)
- `docs/sudoku_finished.md`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`
- `lib/features/quickmatch/presentation/quickmatch_page.dart`
- `lib/features/quickmatch/application/quickmatch_round_starter.dart` (neu, empfohlen)
- ggf. `lib/features/quickmatch/application/...` weitere kleine Modelle/Helper
- `test/...` fuer Spiral, Gewinnpruefung, Replay-Flow

## Akzeptanzkriterien
1. Wenn das Sudoku korrekt geloest ist, startet automatisch die Finish-Sequenz.
2. Das erste verschwindende Feld ist oben links.
3. Alle 81 Felder verschwinden in Spiral-/Schneckenreihenfolge.
4. Nach der Sequenz erscheinen Text `Sudoku geloest` und Button `Erneut spielen`.
5. `Erneut spielen` startet eine neue Runde mit denselben Round-Parametern.
6. Beim Neustart bleibt die Schwierigkeit gleich, aber der geladene Sudoku-String ist neu und passend zur Schwierigkeit.
7. Die bestehende Werbelogik bleibt aktiv: Ad weiterhin bei jeder 10. gestarteten Runde.
8. Bei Ad-Fehler startet die neue Runde trotzdem (Fail-Open).

## Risiken / offene Punkte
- Modifier + Finish-Sequenz koennen sich visuell ueberlagern; hier klare Prioritaetsregel definieren.
- Bei sehr schneller Animation koennte der Effekt unklar wirken; Tick-Dauer als Konstante konfigurierbar machen.
- Falls spaeter Daily-Mode denselben Endflow erhalten soll, Round-Starter abstrahieren (nicht nur Quickmatch).
