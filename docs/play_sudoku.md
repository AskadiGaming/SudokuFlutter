# Implementierungsplan: Sudoku-Spielstart aus Quickmatch

## Ziel
Beim Klick auf den Button "Spielen" in Quickmatch soll ein Sudoku-Spiel gestartet werden.
Das zu ladende Sudoku haengt von der gewaehlten Schwierigkeit ab:
- Leicht
- Mittel
- Schwer
- Extrem

Fuer den ersten Schritt werden pro Schwierigkeit feste Sudoku-Strings verwendet (hardcodiert).
Die Struktur wird so vorbereitet, dass die Datenquelle spaeter leicht auf eine REST-API umgestellt werden kann.

Zusaetzlich im Spielfenster:
- 9x9 Spielfeld (Matrix)
- darunter 9 Zahlentasten (1-9)
- immer genau eine Zahlentaste aktiv
- Klick auf ein Feld traegt die aktive Zahl ein
- alle Felder mit gleicher Zahl wie die aktive Zahl werden visuell markiert

## Ausgangslage
- Quickmatch mit Schwierigkeits-Dropdown und "Spielen"-Button ist bereits vorhanden.
- Der "Spielen"-Button hat aktuell noch keine Spiellogik.
- Die App liegt aktuell hauptsaechlich in `lib/main.dart`.

## Umsetzungsstrategie
Wir teilen die Umsetzung in 6 Schritte:
1. Spielstart von Quickmatch an eine Sudoku-Seite anbinden
2. Sudoku-Datenquelle mit REST-faehiger Schnittstelle einfuehren
3. Sudoku-String in 9x9 Matrix ueberfuehren
4. Sudoku-UI (Grid + Zahlentasten) bauen
5. Eingabe- und Markierungslogik implementieren
6. Testen und technische Vorbereitung fuer REST-Umstieg absichern

## Schritt-fuer-Schritt-Plan

### 1. Quickmatch-Play mit Navigation verbinden
- In `QuickmatchPage` den `onPressed` vom "Spielen"-Button umsetzen.
- Aus dem ausgewaehlten `QuickmatchDifficulty` die gewuenschte Schwierigkeit ableiten.
- Auf eine neue Seite `PlaySudokuPage` navigieren und die Schwierigkeit uebergeben.

Ergebnis:
Der Button startet nicht mehr nur einen Platzhalter, sondern oeffnet das Sudoku-Spiel.

### 2. Datenquelle abstrahieren (heute hardcoded, morgen REST)
- Ein kleines Repository/Service-Interface definieren, z. B.:
- `SudokuPuzzleRepository`
- Methode `Future<String> loadPuzzle(SudokuDifficulty difficulty)`
- Erste Implementierung `LocalSudokuPuzzleRepository` anlegen:
- 4 hardcodierte Strings, jeweils 81 Zeichen lang (0 = leeres Feld).
- Bereits jetzt Fehlerfaelle vorsehen:
- Stringlaenge ungleich 81 -> Fehler werfen
- ungueltige Zeichen -> Fehler werfen

Ergebnis:
Die Aufrufstelle kennt nur das Repository-Interface. Fuer REST wird spaeter nur die Implementierung ausgetauscht.

### 3. Domaenenmodell fuer Spielfeld aufbauen
- `SudokuDifficulty` als vom UI unabhaengiges Enum einfuehren (Mapping von `QuickmatchDifficulty`).
- Hilfsfunktion erstellen: `List<List<int>> parsePuzzle(String puzzle)`.
- 81 Zeichen in eine 9x9 Matrix wandeln.
- Optional zwei Matrizen halten:
- `initialGrid` (vorgegebene Zellen)
- `currentGrid` (aktueller Spielstand)
- Zellstatus vorbereiten, z. B. `isFixed`, damit Vorgabefelder nicht ueberschrieben werden.

Ergebnis:
Es gibt ein stabiles, UI-unabhaengiges Datenmodell fuer das Sudoku.

### 4. Spielseite mit Grid und Zahlenauswahl bauen
- Neue `PlaySudokuPage` als `StatefulWidget` anlegen.
- Beim Oeffnen Puzzle asynchron laden (z. B. in `initState`), waehrenddessen Ladeanzeige.
- 9x9 Grid darstellen:
- sichtbare Trennung von 3x3 Bloecken
- leere Felder bei `0`, sonst Zahl anzeigen
- Unter dem Grid 9 Buttons (1-9) anzeigen.
- Ein Zustand `activeNumber` (int 1-9) steuert den aktiven Button.
- Sicherstellen: immer nur ein Button aktiv (Single-Select-Verhalten).

Ergebnis:
Die Spielseite zeigt Matrix und Zahlenauswahl vollstaendig an.

### 5. Interaktionslogik implementieren
- Klick auf Zahlentaste:
- `activeNumber` setzen
- UI aktualisieren
- Klick auf Grid-Zelle:
- nur bearbeitbare Zellen erlauben (`!isFixed`)
- `currentGrid[row][col] = activeNumber`
- Markierung gleicher Zahlen:
- Alle Zellen hervorheben, deren Wert `activeNumber` entspricht
- sowohl gegebene als auch vom Nutzer eingetragene Zahlen markieren
- Optional: aktive Zelle zusaetzlich hervorheben.

Ergebnis:
Nutzer kann Zahl waehlen, ins Feld eintragen und visuell alle gleichen Zahlen erkennen.

### 6. Qualitaet, Tests und REST-Vorbereitung
- Unit-Tests:
- Parsing 81er-String -> 9x9 Matrix
- Fehler bei ungueltiger Laenge/Zeichen
- Schwierigkeit -> korrekter Puzzle-String
- Widget-Tests:
- nur ein aktiver Zahlenbutton
- Klickfolge "Zahl waehlen -> Feld klicken" traegt korrekt ein
- Markierung fuer gleiche Zahlen reagiert auf aktive Zahl
- REST-Vorbereitung dokumentieren:
- zukuenftige Klasse `ApiSudokuPuzzleRepository`
- Rueckgabeformat: weiterhin `String` (81 Zeichen), damit UI unveraendert bleibt

Ergebnis:
Funktion ist sauber testbar und mit minimalem Umbau auf REST erweiterbar.

## Geplante Dateien
- `lib/main.dart` (nur falls kurzfristig Navigation/Quickmatch dort bleibt)
- empfohlen neu:
- `lib/features/quickmatch/quickmatch_page.dart`
- `lib/features/sudoku/play_sudoku_page.dart`
- `lib/features/sudoku/domain/sudoku_difficulty.dart`
- `lib/features/sudoku/domain/sudoku_grid_parser.dart`
- `lib/features/sudoku/data/sudoku_puzzle_repository.dart`
- `lib/features/sudoku/data/local_sudoku_puzzle_repository.dart`
- `docs/play_sudoku.md`

Hinweis:
Wenn vorerst keine Feature-Ordnerstruktur gewuenscht ist, kann Schritt 1 als Minimalversion direkt in `lib/main.dart` umgesetzt werden. Die Repository-Abstraktion sollte trotzdem direkt eingefuehrt werden.

## Akzeptanzkriterien
Das Feature gilt als umgesetzt, wenn:
- Klick auf "Spielen" startet eine Sudoku-Spielseite.
- Je nach Quickmatch-Schwierigkeit wird jeweils ein unterschiedlicher Sudoku-String geladen.
- Puzzle wird als 9x9 Matrix angezeigt.
- Es gibt genau 9 Zahlentasten (1-9), dabei ist immer genau eine aktiv.
- Nach Auswahl einer Zahl traegt Klick auf ein Feld diese Zahl ein (nur in bearbeitbare Felder).
- Alle gleichen Zahlen wie die aktive Zahl sind im Grid sichtbar markiert.
- Die Ladefunktion ist ueber ein Repository gekapselt und kann ohne UI-Umbau auf REST umgestellt werden.
