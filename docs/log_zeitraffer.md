# Implementierungsplan: Sudoku-Zeitraffer fuer abgeschlossene Runden

## Ziel
Beim Klick auf einen Eintrag in der Liste der abgeschlossenen Sudokus soll eine Detailansicht geoeffnet werden.
Dort wird das geloeste Sudoku als Replay abgespielt.
Die Zellen sollen dabei exakt in der Geschwindigkeit erscheinen und verschwinden, in der der Spieler sie urspruenglich gesetzt oder geloescht hat.

Zusaetzlich soll die Replay-Ansicht enthalten:
- eine laufende Zeitleiste
- Drag-and-drop zum Spulen
- einen Speed-Button mit der Folge `1x -> 2x -> 4x -> 8x -> 16x -> 32x -> 1x`

Die gleiche Datenbasis soll spaeter auch fuer die "echte Spielzeit" verwendet werden.
Wenn ein Spieler pausiert und z. B. erst am naechsten Tag weiterspielt, darf die Abschlussdauer nicht die gesamte Wandzeit enthalten, sondern nur die tatsaechlich gespielte Zeit.

## Kernidee
Die Replay-Funktion und die korrekte Zeitmessung sollten nicht getrennt geloest werden.
Statt nur `started_at` und `completed_at` zu speichern, braucht jede Runde kuenftig ein echtes Aktivitaetsprotokoll:
- wann eine aktive Spielsession beginnt
- wann sie endet bzw. pausiert
- welche Aktion wann innerhalb der aktiven Spielzeit passiert

Damit koennen wir spaeter aus derselben Quelle:
- die Abschlussdauer berechnen
- ein Replay aufbauen
- auf der Zeitleiste beliebig vor- und zurueckspringen

## Bestehender Stand
- Die Historienliste existiert bereits in `lib/features/sudoku_history/presentation/completed_sudoku_log_page.dart`.
- Abgeschlossene Runden werden bereits in `completed_sudoku_log` gespeichert.
- `CompletedSudokuEntry` enthaelt aktuell nur Metadaten wie Schwierigkeit, Startzeit, Endzeit und `duration_seconds`.
- In `PlaySudokuPage` werden Eingaben direkt ins Grid geschrieben, aber noch nicht als einzelne Aktionen protokolliert.
- Fuer Challenge-Runden gibt es Persistenz fuer Grid-Fortschritt, aber keine Historie der einzelnen Moves und keine Trennung zwischen Wandzeit und aktiver Spielzeit.

## Fachliche Anforderungen

### 1. Replay-faehige Aktionen
Jede Spieleraktion muss einzeln gespeichert werden:
- Zahl gesetzt
- Zahl entfernt

Pro Aktion werden mindestens benoetigt:
- eindeutige Reihenfolge innerhalb der Runde
- betroffene Zelle
- neuer Wert
- vorheriger Wert
- Zeitstempel relativ zur aktiven Spielzeit, nicht relativ zur Uhrzeit

`vorheriger Wert` ist wichtig, damit Vorwaerts- und Rueckwaerts-Spulen robust funktionieren.

### 2. Aktive Spielzeit statt Wandzeit
Die Zeit darf nur laufen, solange wirklich gespielt wird.
Die Berechnung muss daher auf aktiven Sessions basieren, nicht auf `completed_at - started_at`.

Beispiel:
- Tag 1: 10 Minuten spielen
- App schliessen
- Tag 2: 5 Minuten spielen und loesen

Gespeicherte Abschlussdauer:
- korrekt: `15 Minuten`
- nicht korrekt: `24 Stunden + 5 Minuten`

### 3. Deterministisches Replay
Das Replay muss jederzeit aus den gespeicherten Daten rekonstruierbar sein:
- Startzustand = urspruengliches Puzzle
- danach Aktionen in gespeicherter Reihenfolge anwenden

Die abgespielte Zeitachse basiert auf der kumulierten aktiven Spielzeit.

## Datenmodell fuer die spaetere Umsetzung

### 1. Bestehendes Abschlussmodell erweitern
`CompletedSudokuEntry` sollte spaeter zusaetzlich Replay-Metadaten referenzieren oder direkt tragen, z. B.:
- `replayId`
- `playedDurationMillis`
- `initialGridString`
- optional `finalGridString`

`durationSeconds` sollte mittelfristig durch eine aus Sessions berechnete aktive Dauer ersetzt werden oder aus dieser aktiv erzeugt werden.

### 2. Neues Replay-Domain-Modell
Vorschlag fuer neue Modelle:
- `SudokuReplay`
- `SudokuReplayMove`
- `SudokuPlaySession`

Beispielhafte Inhalte:

`SudokuReplay`
- `id`
- Referenz auf Abschluss-Log oder Rundenkontext
- `puzzleString`
- `difficulty`
- `mode`
- `playedDurationMillis`

`SudokuReplayMove`
- `id`
- `replayId`
- `sequence`
- `cellRow`
- `cellCol`
- `previousValue`
- `nextValue`
- `elapsedMillis`

`SudokuPlaySession`
- `id`
- `replayId`
- `sessionIndex`
- `startedAt`
- `endedAt`
- `activeDurationMillis`

Wichtig:
- Fuer das Replay reicht `elapsedMillis` pro Move.
- Fuer Nachvollziehbarkeit und Debugging sind echte Session-Zeitpunkte trotzdem hilfreich.

## Persistenzkonzept

### 1. Neue Tabellen
Vorschlag fuer neue lokale Tabellen:

`sudoku_replay`
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `completed_log_id INTEGER NULL`
- `mode TEXT NOT NULL`
- `difficulty TEXT NOT NULL`
- `puzzle_string TEXT NOT NULL`
- `final_grid_string TEXT NOT NULL`
- `played_duration_millis INTEGER NOT NULL`
- `created_at TEXT NOT NULL`

`sudoku_replay_move`
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `replay_id INTEGER NOT NULL`
- `sequence INTEGER NOT NULL`
- `cell_row INTEGER NOT NULL`
- `cell_col INTEGER NOT NULL`
- `previous_value INTEGER NOT NULL`
- `next_value INTEGER NOT NULL`
- `elapsed_millis INTEGER NOT NULL`

`sudoku_play_session`
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `replay_id INTEGER NOT NULL`
- `session_index INTEGER NOT NULL`
- `started_at TEXT NOT NULL`
- `ended_at TEXT NULL`
- `active_duration_millis INTEGER NOT NULL DEFAULT 0`

Sinnvolle Indizes:
- `idx_sudoku_replay_move_replay_sequence` auf `(replay_id, sequence)`
- `idx_sudoku_play_session_replay_session_index` auf `(replay_id, session_index)`

### 2. Migration
`AppDatabase` muss spaeter erweitert werden.
Die bestehende DB-Version `3` wird erhoeht.

Wichtig fuer Alt-Daten:
- Bereits vorhandene Eintraege in `completed_sudoku_log` haben noch keine Replay-Daten.
- Diese Eintraege sollten in der UI als "kein Replay verfuegbar" behandelt werden.
- Es ist nicht sinnvoll, fuer alte Daten kuenstlich ein Replay zu erzeugen.

## Logging im Spiel

### 1. Runde beim Start vorbereiten
Beim Start einer neuen Runde sollte direkt ein Replay-Kontext erzeugt werden.
Dieser haelt:
- Puzzle-Startzustand
- laufende aktive Session
- kumulierte aktive Spielzeit
- Liste bzw. Persistenz der Moves

### 2. Session-Lebenszyklus
Aktive Spielsessions muessen explizit behandelt werden:
- Start der Runde -> Session starten
- App in Hintergrund / Seite verlassen / Pause -> Session beenden
- Rueckkehr ins Spiel -> neue Session starten
- Abschluss -> letzte Session finalisieren

Damit wird die aktive Spielzeit zur Summe aller Session-Dauern.

### 3. Move-Logging in `PlaySudokuPage`
In `_writeActiveNumberToCell` muss spaeter vor dem Schreiben geprueft werden:
- alter Wert der Zelle
- neuer Wert der Zelle
- nur loggen, wenn sich der Wert wirklich aendert

Dann wird ein Move gespeichert mit:
- `previousValue`
- `nextValue`
- Zellposition
- aktuellem `elapsedMillis` innerhalb der aktiven Spielzeit

Das gilt auch fuer das Entfernen einer Zahl.
Falls Loeschen aktuell ueber den Wert `0` abgebildet wird, sollte genau dieses Ereignis als Move gespeichert werden.

### 4. Challenge-Autosave und Replay trennen
Die bestehende Challenge-Persistenz fuer `current_grid` bleibt sinnvoll, sollte aber fachlich getrennt werden von:
- Fortschrittsspeicherung fuer Resume
- Replay- und Session-Logging

Beides darf parallel laufen, sollte aber nicht dasselbe Datenmodell verwenden.

## Replay-Aufbau

### 1. Neue Detailseite
Beim Tap auf einen Historieneintrag soll nicht nur eine Card angezeigt werden, sondern eine neue Replay-Seite geoeffnet werden, z. B.:
- `CompletedSudokuReplayPage`

Die Seite zeigt:
- Sudoku-Grid
- aktuelle Replay-Zeit
- gesamte aktive Spielzeit
- Zeitleiste
- Play/Pause
- Speed-Button

### 2. Rekonstruktion des Zustands
Die Replay-Seite startet mit dem Ursprungs-Puzzle.
Von dort aus wird der Zustand aus den Moves aufgebaut:
- fuer normalen Playhead-Lauf: Moves der Reihe nach anwenden
- fuer Spruenge per Timeline: Grid bis zur Zielzeit rekonstruieren

Fuer spaeteren Komfort kann zusaetzlich ueber Snapshot-Optimierung nachgedacht werden.
Fuer die erste Version reicht bei 81 Feldern und normaler Move-Anzahl meist auch eine Rekonstruktion aus dem Startzustand.

### 3. Zeitbasierte Wiedergabe
Die Wiedergabe laeuft ueber einen Playhead in Millisekunden.
Bei jedem Tick werden alle Moves angewendet, deren `elapsedMillis <= playheadMillis` sind.

Die Abspielgeschwindigkeit multipliziert nur den Playhead-Fortschritt:
- `1x`
- `2x`
- `4x`
- `8x`
- `16x`
- `32x`

### 4. Rueckwaerts- und Vorwaertsspulen
Beim Drag auf der Timeline wird der Playhead direkt auf die neue Zielzeit gesetzt.
Danach wird das Grid fuer genau diesen Zeitpunkt rekonstruiert.

Wichtig:
- Waehrend des Drags sollte die automatische Wiedergabe pausiert werden oder stabil eingefroren bleiben.
- Nach Loslassen kann die vorherige Abspielart optional fortgesetzt werden.

## UI-Plan

### 1. Historienliste
`CompletedSudokuLogPage` wird spaeter erweitert:
- Listeneintrag antippbar machen
- bei vorhandenem Replay zur Replay-Seite navigieren
- bei alten Eintraegen ohne Replay optional Hinweis anzeigen

### 2. Replay-Steuerung
Empfohlene Controls:
- Play/Pause-Button
- Speed-Button mit zyklischer Umschaltung
- Slider fuer die Zeitleiste
- Zeitlabels `aktuelle Zeit / Gesamtdauer`

### 3. Speed-Button
Der Buttontext rotiert exakt so:
- `1x`
- `2x`
- `4x`
- `8x`
- `16x`
- `32x`
- danach wieder `1x`

Die Reihenfolge sollte zentral als Konstante gepflegt werden, damit UI und Logik nicht auseinanderlaufen.

## Architekturvorschlag

### 1. Neues Feature-Modul
Empfohlen ist ein eigener Bereich unter `lib/features/sudoku_replay/` mit:
- `domain/`
- `data/`
- `application/`
- `presentation/`

### 2. Verantwortlichkeiten
`sudoku_history`
- Abschlussliste und Navigation

`sudoku_replay`
- Replay-Datenmodelle
- Replay-Repository
- Session- und Move-Logging
- Replay-Controller
- Replay-UI

`sudoku`
- liefert die eigentlichen Spielereignisse

So bleibt die laufende Spielseite schlank und die Replay-Logik kapselbar.

## Empfohlene Umsetzungsschritte

### Phase 1: Datenbasis schaffen
1. Neues Replay-Datenmodell definieren.
2. DB-Migration fuer Replay-, Move- und Session-Tabellen anlegen.
3. Repository- und DataSource-Schicht fuer Replay-Daten bauen.

### Phase 2: Aktive Spielzeit sauber erfassen
1. Session-Start und Session-Ende im Spiellebenszyklus einfuehren.
2. Kumulierte aktive Dauer berechnen und persistieren.
3. Abschlussdauer nicht mehr aus Wandzeit ableiten, sondern aus Session-Daten.

### Phase 3: Einzelne Moves loggen
1. Schreiben und Entfernen von Zahlen als Move speichern.
2. Nur echte Aenderungen loggen.
3. Resume-Flows pruefen, damit Sessions und Moves nicht doppelt entstehen.

### Phase 4: Replay laden und darstellen
1. Replay-Seite bauen.
2. Grid-Rekonstruktion aus `puzzle_string + moves` implementieren.
3. Playhead, Play/Pause und Zeitleiste anbinden.

### Phase 5: Scrubbing und Geschwindigkeit
1. Drag-and-drop auf der Zeitleiste aktivieren.
2. Rekonstruktion fuer beliebige Zeitpunkte stabil machen.
3. Speed-Button mit den festen Stufen anbinden.

### Phase 6: History-Integration
1. Historieneintraege klickbar machen.
2. Nur bei vorhandenen Replay-Daten in die Replay-Ansicht navigieren.
3. Alt-Eintraege ohne Replay sauber behandeln.

## Tests

### Unit-Tests
- Move wird korrekt mit `previousValue`, `nextValue` und `elapsedMillis` gespeichert.
- Aktive Spielzeit summiert mehrere Sessions korrekt.
- Pause ueber Nacht veraendert die aktive Dauer nicht ungueltig.
- Replay-Rekonstruktion liefert fuer einen beliebigen Zeitpunkt den korrekten Grid-Zustand.
- Speed-Stufen rotieren exakt in der gewuenschten Reihenfolge.

### Widget-Tests
- Klick auf Historieneintrag oeffnet Replay-Seite.
- Slider zeigt Position und erlaubt Drag.
- Speed-Button schaltet `1x -> 2x -> 4x -> 8x -> 16x -> 32x -> 1x`.
- Ein Replay mit Setzen und Loeschen wird sichtbar korrekt abgespielt.

### Integrationsnahe Tests
- Challenge-Runde mit Unterbrechung erzeugt mehrere Sessions, aber eine korrekte Abschlussdauer.
- Abschluss-Logging und Replay-Logging entstehen genau einmal pro geloester Runde.

## Offene Punkte vor der spaeteren Umsetzung
- Soll das Replay nur manuelle Zahleneingaben zeigen oder spaeter auch Hilfsfunktionen wie Notizen, Undo oder Hinweise, falls solche Features noch kommen?
- Soll beim Oeffnen eines Replays automatisch abgespielt werden oder zunaechst auf `0:00` pausiert starten?
- Soll das Replay nach Erreichen des Endes automatisch stoppen oder wieder von vorne beginnen?
- Sollen Daily-, Normal- und Challenge-Runden alle denselben Replay-Flow nutzen? Fachlich ist das sehr zu empfehlen.

## Akzeptanzkriterien fuer die spaetere Implementierung
- Ein Klick auf einen abgeschlossenen Sudoku-Eintrag oeffnet eine Replay-Ansicht.
- Das Sudoku wird in exakt der urspruenglichen Loesungsgeschwindigkeit abgespielt.
- Setzen und Entfernen von Zahlen sind beide im Replay sichtbar.
- Die Zeitleiste laeuft mit und erlaubt Spulen per Drag-and-drop.
- Der Speed-Button schaltet zyklisch durch `1x`, `2x`, `4x`, `8x`, `16x`, `32x`.
- Die angezeigte Abschlussdauer basiert auf echter aktiver Spielzeit und nicht auf blosser Wandzeit zwischen erstem Start und finalem Abschluss.
