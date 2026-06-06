# Implementierungsplan: Admin-Button zum fast vollstaendigen Loesen eines Sudokus

## Ziel
Es soll eine einfache Dev-Konfiguration geben, mit der ein Admin-Button fuer Sudoku-Runden ein- oder ausgeschaltet werden kann.

Wenn das Flag `ADMIN_BUTTON_SUDOKU_SOLVE` auf `true` steht:
- wird in der Sudoku-Ansicht ein zusaetzlicher Button angezeigt
- dieser Button fuellt das aktuelle Sudoku automatisch korrekt aus
- genau ein einziges Feld bleibt leer
- der Tester kann das letzte Feld manuell setzen, um den normalen Erfolgsabschluss zu pruefen

Wenn das Flag auf `false` steht:
- ist der Button nicht sichtbar
- das bisherige Verhalten bleibt unveraendert

## Ist-Zustand
- `PlaySudokuPage` ist die zentrale Sudoku-Spielseite.
- `SudokuGridData` enthaelt bereits:
  - `initialGrid`
  - `currentGrid`
  - `solutionGrid`
  - `isFixed`
- Die Loesungspruefung nutzt bereits `solutionGrid` ueber `isGridSolved(...)`.
- Es gibt schon einen Dev-Bereich fuer Sudoku unter:
  - `lib/features/sudoku/dev/admin_test_sudoku_override.dart`
  - `lib/features/sudoku/domain/admin_test_sudoku_config.dart`

Wichtige Erkenntnis:
Fuer das geplante Feature ist kein neuer Sudoku-Solver noetig, weil die vollstaendige Loesung schon beim Parsen in `solutionGrid` vorliegt.

## Fachliche Entscheidung (MVP)
1. Das Feature ist rein fuer Entwicklung und Test gedacht.
2. Die Steuerung erfolgt ueber ein konstantes Flag in einer Config-Datei.
3. Der Button soll nur dann gerendert werden, wenn das Flag aktiv ist.
4. Beim Klick werden nur beschreibbare, nicht-fixe Felder gesetzt.
5. Genau ein nicht-fixes Feld bleibt absichtlich leer.
6. Das freigelassene Feld soll korrekt loesbar bleiben, damit der normale Finish-Flow unveraendert getestet wird.
7. Das automatische Vorbefuellen darf den Abschluss nicht direkt selbst triggern.

## Vorschlag fuer die Konfigurationsdatei
Empfohlen ist eine kleine Dev-Datei im bestehenden Sudoku-Dev-Bereich, zum Beispiel:

- `lib/features/sudoku/dev/admin_sudoku_flags.dart`

Mit einer Konstante wie:

```dart
const bool ADMIN_BUTTON_SUDOKU_SOLVE = false;
```

Alternative:
Das Flag kann auch in die bestehende Datei `admin_test_sudoku_override.dart` aufgenommen werden, wenn die Dev-Konfiguration bewusst gebuendelt bleiben soll.

Empfehlung:
Eine eigene kleine Flag-Datei ist sauberer, weil der neue Button fachlich nichts mit dem Puzzle-Override selbst zu tun hat.

## Umsetzungsstrategie

### 1. Dev-Flag definieren
- Neue Datei fuer Sudoku-Admin-Flags anlegen.
- Konstante `ADMIN_BUTTON_SUDOKU_SOLVE` dort definieren.
- Nur `const`-basierte Konfiguration, kein Persistenzbedarf.

Ergebnis:
Ein klarer, zentraler Schalter fuer die Sichtbarkeit des Test-Buttons.

### 2. Sichtbarkeit in `PlaySudokuPage` integrieren
- Flag in `play_sudoku_page.dart` importieren.
- In `_buildContent(...)` den Admin-Button nur anzeigen, wenn `ADMIN_BUTTON_SUDOKU_SOLVE == true`.
- Button sollte ausserhalb des Sudoku-Grids liegen, damit das Layout stabil bleibt.

Empfohlene Position:
- zwischen Grid und NumberPad
- oder direkt unter dem NumberPad als Dev-Aktion

Ergebnis:
Das Feature ist komplett ausgeblendet, wenn das Flag deaktiviert ist.

### 3. Admin-Aktion in der State-Klasse kapseln
- In `_PlaySudokuPageState` eine Methode einfuehren, z. B.:
  - `_fillSudokuForAdminTestLeavingOneCellOpen()`
- Diese Methode arbeitet nur auf `_gridData.currentGrid`.
- Vor dem Schreiben Guards pruefen:
  - `_gridData != null`
  - keine aktive Finish-Sequenz
  - kein geloestes Sudoku
  - keine gesperrte Interaktion

Ergebnis:
Die Dev-Logik ist lokal gekapselt und greift nicht diffus in die restliche Seite ein.

### 4. Zielzelle fuer das offene letzte Feld festlegen
- Aus allen nicht-fixen Feldern genau eines auswaehlen, das leer bleiben soll.
- Empfohlene Regel fuer MVP:
  - das letzte nicht-fixe Feld in Leserichtung (`row 0..8`, `col 0..8`)

Warum diese Regel sinnvoll ist:
- deterministisch
- leicht testbar
- keine Zufallskomponente

Optional spaeter:
- immer das aktuell selektierte Feld offen lassen
- oder das erste noch leere nicht-fixe Feld offen lassen

Ergebnis:
Das Verhalten ist reproduzierbar und einfach zu verstehen.

### 5. Sudoku aus `solutionGrid` vorbefuellen
- Alle nicht-fixen Felder mit den Werten aus `solutionGrid` befuellen.
- Die gewaehlte Zielzelle wird uebersprungen und auf `0` gesetzt.
- Bereits falsch eingetragene Werte werden dabei ebenfalls korrigiert.

Wichtig:
- Es soll bewusst direkt aus `solutionGrid` geschrieben werden, nicht ueber einzelne simulierte Tap-Eingaben.
- Dadurch bleibt die Implementierung robust und kurz.

Ergebnis:
Das Sudoku ist korrekt vorbereitet und es fehlt genau ein letzter Eintrag.

### 6. Finish-Logik bewusst nicht automatisch ausloesen
- Nach dem Admin-Vorbefuellen darf `_checkSolvedAndMaybeStartFinishSequence()` nicht zu einem automatischen Abschluss fuehren.
- Das ist automatisch erfuellt, wenn eine Zelle auf `0` bleibt.
- Trotzdem im Plan festhalten:
  - die Methode darf nur einen "fast geloesten" Zustand herstellen
  - nicht den Endzustand

Ergebnis:
Der echte Testfall bleibt erhalten: Der Nutzer schliesst das Sudoku selbst mit dem letzten Feld ab.

### 7. UI- und Guard-Verhalten definieren
- Button deaktivieren, wenn:
  - `_gridData == null`
  - `_isInteractionLocked == true`
  - `_isSolved == true`
- Optional:
  - Buttontext klar als Dev-Funktion markieren, z. B. `Admin: fast loesen`

Ergebnis:
Keine merkwuerdigen Zustandswechsel waehrend Finish-Sequenz oder nach Abschluss.

### 8. Tests fuer das Feature einplanen
- Unit-/Widget-Tests fuer:
  - Flag `false` => Button nicht sichtbar
  - Flag `true` => Button sichtbar
  - Klick fuellt alle nicht-fixen Felder bis auf genau eins
  - genau ein Feld bleibt `0`
  - das offene Feld ist nicht fix
  - nach manuellem Eintrag des letzten Feldes startet der bestehende Finish-Flow

Optional zusaetzlich:
- Test, dass bestehende fixe Startwerte nie ueberschrieben werden

Ergebnis:
Das Feature ist gegen Regressionen abgesichert.

## Voraussichtlich betroffene Dateien
- `docs/adminLoesen.md`
- `lib/features/sudoku/dev/admin_sudoku_flags.dart` (neu, empfohlen)
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- ggf. `test/play_sudoku_finish_sequence_test.dart`
- ggf. neuer Widget-Test speziell fuer den Admin-Button

## Akzeptanzkriterien
1. Es gibt eine Config-Datei mit dem Flag `ADMIN_BUTTON_SUDOKU_SOLVE`.
2. Bei `false` ist in der Sudoku-Ansicht kein Admin-Button sichtbar.
3. Bei `true` ist der Admin-Button sichtbar.
4. Ein Klick auf den Button fuellt das Sudoku korrekt bis auf genau ein letztes Feld.
5. Das offene Feld ist ein beschreibbares, nicht-fixes Feld.
6. Das Sudoku gilt nach dem Button-Klick noch nicht als abgeschlossen.
7. Nach manuellem Setzen des letzten Feldes laeuft der bestehende Erfolgs-/Finish-Flow unveraendert an.

## Offene Detailentscheidung
Es sollte vor der Umsetzung einmal festgelegt werden, welches Feld offen bleiben soll.

Empfehlung fuer die erste Umsetzung:
- letztes nicht-fixes Feld in Leserichtung offen lassen

Das ist die einfachste und am besten testbare Variante.
