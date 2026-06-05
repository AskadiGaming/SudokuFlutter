# Implementierungsplan: Abgeschlossene Sudokus im Profil anzeigen

## Ziel
Im Profil soll ein neuer Button `Abgeschlossene Sudokus anzeigen` erscheinen.
Beim Klick darauf oeffnet sich eine Seite mit allen abgeschlossenen Sudokus.
Jeder Eintrag zeigt mindestens:
- Abschlusszeitpunkt (`Timestamp`, Format `dd.MM.yyyy HH:mm`, z. B. `05.06.2026 09:07`)
- benoetigte Dauer bis zum Abschluss
- Schwierigkeitsgrad

## Annahmen
- Die Liste soll lokal aus der App-Datenhaltung kommen und offline verfuegbar sein.
- Die Historie soll nicht nur fuer Challenge-Sudokus gelten, sondern generell fuer abgeschlossene Sudoku-Runden wiederverwendbar sein.
- Die Liste wird absteigend nach `completed_at` sortiert, also neueste Abschluesse zuerst.

## Bestehender Stand
- Die Profilseite existiert bereits in `lib/features/profile/presentation/profile_page.dart`.
- Die lokale SQLite-Datenbank existiert in `lib/core/database/app_database.dart`.
- Fuer `challenge_progress` gibt es bereits `started_at`, `updated_at` und `completed_at`.
- Fuer normale Sudoku-Runden gibt es aktuell noch keine persistente Abschluss-Historie.

## Umsetzungsschritte

### 1. Fachliches Datenmodell fuer Abschluss-Historie festlegen
- Neues Domain-Modell einfuehren, z. B. `CompletedSudokuEntry`.
- Felder:
  - `id`
  - `difficulty`
  - `startedAt`
  - `completedAt`
  - `durationSeconds`
  - optional `mode` (`normal`, `daily`, `challenge`), damit die Historie spaeter erweiterbar bleibt
  - optional Referenz auf Puzzle bzw. Fortschrittsdatensatz
- Die Dauer soll beim Speichern eindeutig bestimmt werden, damit die Anzeige spaeter nicht von Laufzeitberechnung oder Zeitzonenformatierung abhaengt.

### 2. Persistenz fuer abgeschlossene Sudokus erweitern
- Neue Tabelle anlegen, z. B. `completed_sudoku_log`.
- Vorschlag fuer Spalten:
  - `id INTEGER PRIMARY KEY AUTOINCREMENT`
  - `difficulty TEXT NOT NULL`
  - `mode TEXT NOT NULL`
  - `started_at TEXT NOT NULL`
  - `completed_at TEXT NOT NULL`
  - `duration_seconds INTEGER NOT NULL`
  - optional `challenge_date TEXT NULL`
  - optional `source_sudoku_id INTEGER NULL`
- Index auf `completed_at` anlegen, damit die Liste performant sortiert geladen werden kann.
- `AppDatabase` per Migration erweitern; Datenbankversion erhoehen.

### 3. Repository- und DataSource-Schicht einfuehren
- Neues Feature oder Teilmodul fuer Sudoku-Historie anlegen, z. B. unter `lib/features/profile` oder `lib/features/sudoku_history`.
- Schnittstellen:
  - `CompletedSudokuLogRepository`
  - `CompletedSudokuLogLocalDataSource`
- Benoetigte Methoden:
  - `Future<void> addCompletedSudoku(CompletedSudokuEntry entry)`
  - `Future<List<CompletedSudokuEntry>> getCompletedSudokus()`
- Mapping von DB-Row <-> Domain-Modell zentral kapseln.

### 4. Abschluss-Logging in den Sudoku-Finish-Flow einbauen
- Im bestehenden Sudoku-Ende muss beim erfolgreichen Abschluss ein Historien-Eintrag erzeugt werden.
- Quelle fuer die Zeitwerte:
  - `startedAt` beim Rundenstart setzen bzw. verfuegbar halten
  - `completedAt` beim erfolgreichen Loesen setzen
  - `durationSeconds = completedAt - startedAt`
- Wichtig: Der Eintrag darf pro Runde nur genau einmal gespeichert werden, auch wenn Finish-UI oder Navigation mehrfach getriggert wird.
- Challenge-spezifische Abschluesse koennen zusaetzlich weiterhin ihren bestehenden Fortschrittsdatensatz pflegen; das Log ist davon getrennt.

### 5. Profilseite um CTA erweitern
- In `ProfilePage` unterhalb des bestehenden Headers einen gut sichtbaren Button oder `ListTile` einfuegen:
  - Text: `Abgeschlossene Sudokus anzeigen`
- Klick navigiert zu einer neuen Verlauf-Seite.
- Die bestehende Username-Bearbeitung bleibt unveraendert.

### 6. Neue Verlaufsseite bauen
- Neue Seite, z. B. `CompletedSudokuLogPage`.
- Inhalte:
  - AppBar mit Titel wie `Abgeschlossene Sudokus`
  - Laden der Historie ueber Controller oder direkt ueber dediziertes State-Objekt
  - leere Zustandsanzeige, falls noch kein Sudoku abgeschlossen wurde
  - scrollbare Liste fuer vorhandene Eintraege
- Pro Listeneintrag anzeigen:
  - Schwierigkeit
  - formatiertes Abschlussdatum mit Uhrzeit im Format `dd.MM.yyyy HH:mm`
  - formatiertes Dauer-Label, z. B. `12 min 34 s`
- Sortierung: neueste Eintraege zuerst.

### 7. State-Management fuer die Verlauf-Seite
- Analog zum Profil-Controller einen kleinen Controller einfuehren, z. B. `CompletedSudokuLogController`.
- Verantwortlichkeiten:
  - Historie laden
  - Loading-State abbilden
  - leere Liste vs. gefuellte Liste behandeln
- Falls das Projekt bewusst schlank bleiben soll, kann alternativ auch ein `FutureBuilder` genutzt werden; ein Controller ist aber fuer Tests und Erweiterungen robuster.

### 8. Formatierung und Lokalisierung
- Anzeigeformate zentral halten:
  - Datum/Uhrzeit einheitlich mit fuehrenden Nullen formatieren, also `dd.MM.yyyy HH:mm` statt `5.6.2026`
  - Dauer aus Sekunden lesbar darstellen
- UI-Texte in die bestehenden Lokalisierungsdateien aufnehmen, mindestens:
  - `Abgeschlossene Sudokus anzeigen`
  - `Abgeschlossene Sudokus`
  - `Noch keine abgeschlossenen Sudokus`
  - Labels fuer Dauer und Schwierigkeit, falls noetig

### 9. Tests
- Unit-Tests:
  - Mapping `CompletedSudokuEntry` <-> DB
  - Dauerberechnung
  - Sortierung nach `completed_at`
- Widget-Tests:
  - Profilseite zeigt den neuen Button
  - Klick navigiert zur Verlauf-Seite
  - leerer Zustand wird korrekt angezeigt
  - Listeneintrag zeigt Schwierigkeit, Timestamp und Dauer
- Integrationsnahe Tests:
  - Abschluss eines Sudokus erzeugt genau einen Log-Eintrag
  - Historie bleibt nach App-Neustart erhalten

## Empfohlene Reihenfolge
1. Datenmodell und DB-Migration definieren
2. Repository/DataSource fuer Historie implementieren
3. Finish-Flow um Logging erweitern
4. Profil-Button und Verlauf-Seite bauen
5. Formatierung und Tests ergaenzen

## Offene Punkte vor der Umsetzung
- Soll die Liste wirklich alle abgeschlossenen Modi enthalten oder in der ersten Version nur normale Sudokus?
- Soll pro Eintrag zusaetzlich das Abschlussdatum des Challenge-Tags angezeigt werden, falls der Eintrag aus dem Challenge-Modus kommt?
- Soll es spaeter Filter geben, z. B. nach Schwierigkeit oder Modus? Wenn ja, sollte `mode` direkt in der Tabelle mitgespeichert werden.

## Akzeptanzkriterien
- Im Profil ist der Button `Abgeschlossene Sudokus anzeigen` sichtbar.
- Ein Klick oeffnet eine eigene Verlauf-Seite.
- Jeder abgeschlossene Sudoku-Eintrag zeigt Timestamp, Dauer und Schwierigkeitsgrad.
- Die Daten kommen aus lokaler Persistenz und bleiben nach App-Neustart erhalten.
- Ein erfolgreich geloestes Sudoku erscheint genau einmal in der Historie.
