# Implementierungsplan: Challenge-Kalender mit Monatsansicht

## Ziel
Es soll einen neuen Hauptmenueeintrag `Challenge` geben.
Dahinter liegt ein Kalender wie in `docs/gui/sudoku_kalender.png`, in dem jeder Tag eines Monats anklickbar ist.

Fuer jeden Kalendertag gibt es pro Schwierigkeit genau ein vordefiniertes Sudoku.
Spieler koennen eine Challenge jederzeit starten, verlassen und spaeter exakt an derselben Stelle fortsetzen.
Der Spielstand wird nach jeder Nutzeraktion automatisch zwischengespeichert.

Status im Kalender:
- nicht gestartet: keine Markierung
- angefangen: hellblauer Kreis
- abgeschlossen: goldener Kreis

Standardmaessig soll beim Oeffnen der Challenge-Seite der Monat angezeigt werden, in dem zuletzt ein Challenge-Sudoku gespielt wurde.

## Ausgangslage
- Es gibt bereits eine Bottom-Navigation mit `Duell`, `Quickmatch` und `Einstellungen`.
- `PlaySudokuPage` kann bereits Sudokus laden und kennt mit `SudokuRoundMode.daily` schon einen ersten Daily-Mode.
- Die lokale SQLite-Datenbank `sudoku` existiert bereits und enthaelt Sudokus nach Schwierigkeit.
- Es gibt aktuell noch keine Monatsansicht, keine persistierten Challenge-Spielstaende und keine Statusanzeige pro Kalendertag.

## Fachliche Entscheidungen fuer die spaetere Umsetzung

### 1. Challenge ist eigener Modus
- `Challenge` wird nicht in `Quickmatch` integriert, sondern bekommt einen eigenen Hauptmenuepunkt.
- Der bestehende `SudokuRoundMode` wird um einen eigenen Wert fuer Kalender-Challenges erweitert, z. B. `challenge`.

### 2. Pro Tag und Schwierigkeit genau ein festes Sudoku
- Fuer jedes Datum gibt es vier feste Zuordnungen:
  - `easy`
  - `medium`
  - `hard`
  - `extreme`
- Die Zuordnung darf sich spaeter nicht mehr aendern, damit Fortschritte und abgeschlossene Tage stabil bleiben.

### 3. Status ist schwierigkeitsbezogen
- Ein Tag kann je nach aktuell gewaehlter Schwierigkeit einen anderen Status haben.
- Empfehlung fuer die UI:
  - Schwierigkeit oberhalb des Kalenders waehlen
  - der Kalender zeigt dann Status genau fuer diese Schwierigkeit
- Dadurch bleibt die Kreis-Markierung eindeutig.

### 4. Wiederaufnahme hat Vorrang
- Wenn fuer Tag + Schwierigkeit bereits ein angefangener Spielstand existiert, wird nicht neu gestartet.
- Stattdessen wird genau dieser gespeicherte Stand geladen.

### 5. Autosave nach jeder Nutzeraktion
- Speichern nach jeder relevanten Aenderung:
  - Zahl setzen
  - Zahl loeschen
  - ggf. Notizen, falls spaeter vorhanden
- Optional technisch ergaenzen:
  - kleines Debounce-Fenster von z. B. 150-300 ms, falls mehrere Aktionen sehr schnell hintereinander kommen
- Fachlich gilt trotzdem: kein manueller Speichern-Button.

## Zielarchitektur

### UI-Ebene
- `ChallengePage` fuer Monatsansicht
- eigener Kalender-Widget-Baustein, z. B. `ChallengeCalendar`
- Schwierigkeitsschalter oberhalb des Kalenders
- Monatsnavigation mit `vorheriger Monat` / `naechster Monat`
- CTA unten:
  - wenn Tag noch nicht gestartet: `Spielen`
  - wenn Spielstand existiert: `Fortsetzen`

### Application-Ebene
- `ChallengeController` oder `ChallengeCalendarController`
- Verantwortlich fuer:
  - aktuellen Monat
  - zuletzt gewaehlte Schwierigkeit
  - geladenen Monatsstatus
  - ausgewaehlten Kalendertag
  - Standardmonat aus letzter Challenge-Aktivitaet

### Data-Ebene
- Challenge-Repository fuer:
  - Kalenderdaten eines Monats
  - feste Puzzle-Zuordnung pro Tag und Schwierigkeit
  - Laden/Speichern von Challenge-Spielstaenden
  - Speichern des zuletzt gespielten Challenge-Monats

## Datenmodell

### Bestehende Tabelle `sudoku`
- Kann weiterhin den eigentlichen Sudoku-String halten.
- Das bisherige Feld `daily` reicht fuer die neue Anforderung nicht aus, weil jetzt pro Datum vier feste Puzzles benoetigt werden und Spielstaende separat gespeichert werden muessen.

### Neue Tabelle fuer feste Challenge-Zuordnung
Empfehlung: `challenge_puzzle`

Felder:
- `id`
- `challenge_date` als ISO-Datum `yyyy-MM-dd`
- `difficulty`
- `sudoku_id`

Constraints:
- `UNIQUE(challenge_date, difficulty)`

Nutzen:
- garantiert pro Tag und Schwierigkeit genau ein festes Puzzle
- entkoppelt Datumszuordnung sauber von der Puzzle-Stammtabelle

### Neue Tabelle fuer Fortschritt
Empfehlung: `challenge_progress`

Felder:
- `id`
- `challenge_date`
- `difficulty`
- `sudoku_id`
- `current_grid` als 81-Zeichen-String
- `is_completed` als `0/1`
- `started_at`
- `updated_at`
- `completed_at` nullable

Constraints:
- `UNIQUE(challenge_date, difficulty)`

Nutzen:
- ein Spielstand pro Tag und Schwierigkeit
- Status kann direkt aus den Daten abgeleitet werden

Statusableitung:
- kein Eintrag in `challenge_progress` -> nicht gestartet
- Eintrag vorhanden und `is_completed = 0` -> angefangen
- Eintrag vorhanden und `is_completed = 1` -> abgeschlossen

### Neue lokale Preference fuer letzten Challenge-Monat
Empfehlung ueber `SharedPreferences` oder kleine DB-Tabelle.

Gespeichert wird:
- letzter geoeffneter oder gespielter Challenge-Monat, z. B. `2026-04`

Empfehlung:
- speichern, sobald ein Challenge-Sudoku gestartet oder fortgesetzt wird
- optional auch beim reinen Monatswechsel im Kalender

## Umsetzungsstrategie
Wir teilen die spaetere Umsetzung in 9 Schritte.

### 1. Navigation um `Challenge` erweitern
- In `MainNavigationPage` neuen Tab `Challenge` einfuegen.
- Reihenfolge festlegen, z. B.:
  - Duell
  - Quickmatch
  - Challenge
  - Einstellungen
- Neue Lokalisierungsstrings ergaenzen:
  - `tabChallenge`
  - `pageChallenge`
  - Monatsnavigation
  - `Spielen`
  - `Fortsetzen`
  - Statustexte, falls benoetigt

Ergebnis:
Die Challenge ist als eigener Hauptbereich erreichbar.

### 2. Domain fuer Challenge einfuehren
- Neue Modelle anlegen, z. B.:
  - `ChallengeDayStatus`
  - `ChallengeDayEntry`
  - `ChallengeMonthData`
  - `ChallengeSelection`
- `SudokuRoundMode` um `challenge` erweitern.
- `SudokuRoundConfig` um Challenge-Kontext erweitern, z. B.:
  - Datum
  - Schwierigkeit
  - Puzzle-ID

Ergebnis:
Die Kalender-Logik ist fachlich von Quickmatch getrennt und trotzdem kompatibel zur bestehenden Sudoku-Seite.

### 3. Datenbank-Migration vorbereiten
- `AppDatabase` auf neue Version anheben.
- Migration fuer neue Tabellen `challenge_puzzle` und `challenge_progress` anlegen.
- Indizes fuer schnelle Monatsabfragen ergaenzen:
  - auf `challenge_date`
  - auf `(challenge_date, difficulty)`

Wichtig:
- Bestehende `sudoku`-Daten bleiben erhalten.
- Die bisherige `daily`-Spalte kann vorerst bestehen bleiben, auch wenn die neue Challenge-Logik sie nicht mehr nutzt.

Ergebnis:
Die Datenbasis fuer feste Tages-Challenges und Resume ist vorhanden.

### 4. Feste Puzzle-Zuordnung pro Datum und Schwierigkeit aufbauen
- Repository-Methode definieren, z. B.:
  - `Future<int> getOrCreateChallengePuzzleId(DateTime date, SudokuDifficulty difficulty)`
- Beim ersten Zugriff auf Tag + Schwierigkeit:
  - falls Eintrag existiert -> wiederverwenden
  - sonst festes Puzzle aus `sudoku` ziehen und in `challenge_puzzle` speichern
- Wichtig fuer Stabilitaet:
  - dieselbe Kombination aus Datum + Schwierigkeit muss immer dieselbe `sudoku_id` behalten

Offene Produktentscheidung:
- Entweder Zuordnung lazily beim ersten Oeffnen erzeugen
- oder Monate im Voraus generieren

Empfehlung fuer MVP:
- lazy `getOrCreate`, weil einfacher und robust genug

Ergebnis:
Jeder Tag hat pro Schwierigkeit ein dauerhaft festes Sudoku.

### 5. Challenge-Fortschritt mit Autosave umsetzen
- Neues Repository/API, z. B.:
  - `loadChallengeProgress(date, difficulty)`
  - `saveChallengeProgress(...)`
  - `markChallengeCompleted(...)`
- In `PlaySudokuPage` Challenge-Start unterscheiden:
  - existierender Progress -> `current_grid` laden
  - sonst aus zugeordnetem Puzzle neuen Progress erzeugen
- Nach jeder Zellaktion sofort speichern.
- Beim erfolgreichen Loesen:
  - `is_completed = 1`
  - `completed_at` setzen

Wichtig:
- Speichern muss auch funktionieren, wenn der Nutzer direkt per Zurueck-Navigation die Seite verlaesst.
- Die Seite darf sich nicht darauf verlassen, dass nur in `dispose()` gespeichert wird.

Ergebnis:
Challenge-Runden sind jederzeit unterbrechbar und fortsetzbar.

### 6. Kalender-Monatsansicht bauen
- Neue `ChallengePage` als `StatefulWidget` oder controllerbasierte Seite.
- Aufbau analog zum Referenzbild:
  - Monatsname oben gross
  - Wochentage als Kopfzeile
  - 7-spaltiges Kalenderraster
  - Tage ausserhalb des aktiven Monats visuell abgeschwaecht
  - unten ein grosser CTA-Button
- Jeder Tag ist tappable.
- Ausgewaehlter Tag bekommt zusaetzlich einen klaren Fokuszustand.

Statusdarstellung:
- nicht gestartet: neutral
- angefangen: hellblauer Kreis hinter der Zahl
- abgeschlossen: goldener Kreis hinter der Zahl
- aktuell ausgewaehlter Tag: falls noetig ueber Ring/Border hervorheben, damit Statusfarbe sichtbar bleibt

Ergebnis:
Die Monatsansicht bildet die gewuenschte Challenge-Oberflaeche aus dem Screenshot nach.

### 7. Monatswechsel und Standardmonat umsetzen
- Buttons oder Pfeile fuer `vorheriger Monat` und `naechster Monat`.
- Beim Laden der `ChallengePage`:
  - zuerst zuletzt gespielten Challenge-Monat laden
  - falls keiner vorhanden ist: aktuellen Monat verwenden
- Beim Starten oder Fortsetzen einer Challenge:
  - diesen Monat als `last played challenge month` speichern

Empfehlung:
- Monat immer als erstes Datum des Monats intern darstellen, z. B. `DateTime(year, month)`

Ergebnis:
Die Seite oeffnet sich standardmaessig im zuletzt relevanten Challenge-Monat.

### 8. Verbindung zur Sudoku-Spielseite
- `PlaySudokuPage` um Challenge-Ladepfad erweitern.
- Challenge-Start uebergibt:
  - Modus `challenge`
  - Datum
  - Schwierigkeit
  - ggf. `sudokuId`
- Beim Laden:
  - Puzzle-Zuordnung pruefen
  - Progress laden oder anlegen
  - `currentGrid` aus Progress befuellen
- Nach Abschluss:
  - Rueckkehr zum Kalender
  - Monatsstatus aktualisieren, damit der Tag sofort gold markiert wird

Ergebnis:
Kalender und Spielseite verhalten sich wie ein zusammenhaengender Flow.

### 9. Tests und Abnahme
- Unit-Tests:
  - Statusableitung aus `challenge_progress`
  - Monatsberechnung und Rasterbelegung
  - `getOrCreateChallengePuzzleId` bleibt stabil
  - letzter Challenge-Monat wird korrekt gelesen/geschrieben
- Datenbank-/Integrationstests:
  - Migration erstellt neue Tabellen korrekt
  - Spielstand wird nach Aktion gespeichert
  - Wiederaufnahme laedt denselben Grid-Stand
  - Abschluss setzt `is_completed`
- Widget-Tests:
  - Tage eines Monats sind anklickbar
  - abgeschwaechte Nachbar-Monate werden korrekt angezeigt
  - hellblauer/goldener Status wird sichtbar
  - CTA wechselt zwischen `Spielen` und `Fortsetzen`

Ergebnis:
Das Feature ist stabil und regressionsarm.

## Geplante Dateien
- `docs/daily.md`
- `lib/app/main_navigation_page.dart`
- `lib/l10n/app_de.arb`
- weitere ARB-Dateien
- `lib/features/challenge/presentation/challenge_page.dart`
- `lib/features/challenge/presentation/widgets/challenge_calendar.dart`
- `lib/features/challenge/application/challenge_controller.dart`
- `lib/features/challenge/data/challenge_repository.dart`
- `lib/features/challenge/data/local_challenge_repository.dart`
- `lib/features/challenge/domain/challenge_day_status.dart`
- `lib/features/challenge/domain/challenge_day_entry.dart`
- `lib/features/challenge/domain/challenge_month_data.dart`
- `lib/core/database/app_database.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- passende Tests unter `test/`

## Akzeptanzkriterien
- Es gibt einen neuen Hauptmenueeintrag `Challenge`.
- Die Challenge-Seite zeigt einen Monatskalender mit anklickbaren Tagen.
- Fuer jeden Tag existiert pro Schwierigkeit genau ein festes Sudoku.
- Ein angefangener Challenge-Tag wird hellblau markiert.
- Ein abgeschlossener Challenge-Tag wird gold markiert.
- Spieler koennen eine Challenge jederzeit verlassen und spaeter fortsetzen.
- Der Spielstand wird nach jeder Nutzeraktion automatisch gespeichert.
- Andere Monate koennen angezeigt und ausgewaehlt werden.
- Standardmaessig wird der Monat geoeffnet, in dem zuletzt ein Challenge-Sudoku gespielt wurde.

## Offene Punkte vor der Umsetzung
- Soll die Schwierigkeit direkt auf der Challenge-Seite sichtbar umschaltbar sein oder aus einer globalen Auswahl kommen?
- Soll ein Tag mehrfach abgeschlossen werden koennen, wenn man die Schwierigkeit wechselt? Fachlich waere das sinnvoll, da pro Schwierigkeit ein eigenes Puzzle existiert.
- Soll der CTA fuer zukuenftige Tage immer aktiv sein oder nur fuer Tage bis heute?
- Soll nach einem geloesten Challenge-Sudoku automatisch zum Kalender zurueck navigiert werden oder zunaechst das bestehende Finish-Overlay sichtbar bleiben?

## Empfehlung fuer den Start
- Zuerst Navigation, Datenbank-Migration und Repositorys bauen.
- Danach Challenge-Kalender ohne finale Optik, aber mit echten Monats- und Statusdaten.
- Anschliessend `PlaySudokuPage` um Resume + Autosave erweitern.
- Zum Schluss visuelles Feintuning gemaess `sudoku_kalender.png`.
