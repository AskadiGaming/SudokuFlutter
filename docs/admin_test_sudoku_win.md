# Implementierungsplan: Admin Test Sudoku Override (Windows/Dev)

## Ziel
Fuer die Entwicklung soll es eine Admin-Testkonfiguration geben, in der ein fixer Sudoku-String eingetragen werden kann.
Wenn diese Konfiguration aktiv ist, wird immer genau dieser Sudoku-String verwendet, unabhaengig von der gewaehlten Schwierigkeit.

## Ist-Zustand
- `QuickmatchPage` uebergibt aktuell nur `SudokuRoundConfig` (inkl. Difficulty) an `PlaySudokuPage`.
- `PlaySudokuPage` laedt bei normalem Modus immer `getRandomByDifficulty(...)`.
- Die Puzzle-Quelle liegt im Repository/DataSource-Flow:
  - `SudokuPuzzleRepository`
  - `SudokuRepositoryImpl`
  - `SudokuLocalDataSource`

## Fachliche Entscheidung (MVP)
1. Der Override gilt nur fuer Entwicklungszwecke (Debug/Admin), nicht fuer regulare Release-Nutzung.
2. Wenn Override aktiv und gueltig ist, hat er Prioritaet vor Difficulty und vor normaler Zufallsauswahl.
3. Ein ungueltiger String (nicht 81 Zeichen oder nicht nur `0-9`) deaktiviert die Anwendung des Overrides zur Laufzeit (Fail-Open auf normalen Ladepfad).
4. Konfiguration ist persistent, damit sie nach App-Neustart auf Windows erhalten bleibt.

## Umsetzungsstrategie (8 Schritte)

### 1. Admin-Testkonfiguration als Domain-Modell einfuehren
- Neue Klasse, z. B. `AdminTestSudokuConfig`:
  - `bool enabled`
  - `String? sudokuString`
- Hilfsmethoden:
  - `bool get hasValidOverride`
  - Validierung: genau 81 Zeichen, nur Ziffern `0-9`.

Ergebnis: Eindeutiges, testbares Konfigurationsobjekt.

### 2. Persistenten Store fuer die Konfiguration bauen
- Neues Interface, z. B. `AdminTestSudokuConfigStore`.
- Implementierung via `shared_preferences`, z. B.:
  - `lib/features/sudoku/infrastructure/shared_prefs_admin_test_sudoku_config_store.dart`
- Persistenz-Keys (Beispiel):
  - `admin_test_sudoku.enabled`
  - `admin_test_sudoku.value`

Ergebnis: Admin-Testwerte bleiben zwischen Starts erhalten.

### 3. Windows/Debug-Admin-Fenster erstellen
- Neue Seite `AdminTestSudokuPage` mit:
  - Toggle `Override aktiv`
  - Textfeld fuer Sudoku-String
  - Inline-Validierung + Fehlermeldung
  - Buttons `Speichern` und `Zuruecksetzen`
- Sichtbarkeit nur fuer Dev-Kontext:
  - empfohlen: `kDebugMode`
  - optional zusaetzlich: nur `TargetPlatform.windows`

Ergebnis: Konfiguration kann waehrend Entwicklung bequem gepflegt werden.

### 4. Einstiegspunkt in die vorhandene UI integrieren
- In `SettingsPage` einen Dev/Admin-Bereich anzeigen (nur wenn Dev-Guard aktiv):
  - z. B. ListTile "Admin Test Sudoku"
  - Navigation zur neuen `AdminTestSudokuPage`.

Ergebnis: Admin-Funktion ist erreichbar, ohne Produktions-UI zu beeinflussen.

### 5. Override in den Puzzle-Ladepfad integrieren
- In `PlaySudokuPage._loadPuzzle()` den Override vor dem bestehenden Ladepfad pruefen:
  - `if (override aktiv und gueltig) -> puzzle = override`
  - sonst unveraendert:
    - daily -> `getOrCreateDailyPuzzle(...)`
    - normal -> `getRandomByDifficulty(...)`
- Parsing bleibt zentral ueber `parsePuzzle(puzzle)` bestehen.

Ergebnis: Der eingetragene Sudoku-String wird immer verwendet, unabhaengig von Difficulty.

### 6. Fail-Open und Safety absichern
- Wenn gespeicherter Override ungueltig:
  - keine harte Exception im Startflow
  - stattdessen normaler Ladepfad + optional Debug-Log.
- Optional: bei ungueltigem Wert Toggle intern auf `false` setzen.

Ergebnis: Spielstart bleibt stabil, auch bei fehlerhafter Admin-Eingabe.

### 7. Tests einfuehren
- Unit-Tests:
  - Validierung `81 Zeichen + 0-9`.
  - Store lesen/schreiben.
- Widget-/Integrationstests:
  - Aktiv + gueltig => Override wird geladen.
  - Aktiv + ungueltig => Fallback auf normalen Repository-Ladepfad.
  - Inaktiv => normales Verhalten unveraendert.

Ergebnis: Override-Logik ist regressionssicher.

### 8. Release-Schutz dokumentieren
- In der Doku klar festhalten:
  - Admin-UI nur in Debug (und optional Windows).
  - Kein funktionaler Einfluss in regularem Release.
- Optional: kleines Dev-Readme mit Beispiel-Workflows ergaenzen.

Ergebnis: Kein versehentliches Leaken der Testfunktion in produktive Nutzung.

## Geplante Dateien
- `docs/admin_test_sudoku_win.md`
- `lib/features/sudoku/domain/admin_test_sudoku_config.dart` (neu)
- `lib/features/sudoku/application/admin_test_sudoku_config_store.dart` (neu)
- `lib/features/sudoku/infrastructure/shared_prefs_admin_test_sudoku_config_store.dart` (neu)
- `lib/features/sudoku/presentation/admin_test_sudoku_page.dart` (neu)
- `lib/features/settings/presentation/settings_page.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `test/...` fuer Validierung, Store und Ladepfad

## Akzeptanzkriterien
1. In Dev/Admin kann ein Sudoku-String eingegeben und gespeichert werden.
2. Bei aktiviertem Override wird dieser String beim Spielstart immer verwendet.
3. Die gewaehlte Difficulty hat dann keinen Einfluss auf das geladene Sudoku.
4. Nach App-Neustart bleibt die Einstellung erhalten.
5. Ungueltige Eingaben blockieren den Spielstart nicht (Fallback auf normalen Ladepfad).
6. In produktiver Release-Konfiguration ist die Admin-Funktion nicht sichtbar bzw. nicht aktiv.

## Risiken und offene Entscheidungen
- Scope-Frage: Soll der Override auch fuer `daily` gelten oder nur fuer normalen Quickmatch?
- UI-Ort: eigener Admin-Screen unter Settings vs. versteckter Dev-Einstieg.
- Plattformgrenze: nur Windows oder allgemein Debug auf allen Plattformen.
