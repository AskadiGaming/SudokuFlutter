# Implementierungsplan: Lokale Sudoku-Datenbank

## Ziel
Eine lokale Datenbank einfuehren, die Sudokus zentral speichert und spaeter fuer:
- zufaellige Auswahl pro Schwierigkeit
- taegliche Challenge (`daily`)
verwendet wird.

## Anforderungen (aus Vorgabe)
- Neue Tabelle: `sudoku`
- Felder:
  - `id`
  - `level` (zugehoerig zum Sudoku-String)
  - `difficulty` (`easy`, `medium`, `hard`, `extreme`)
  - `daily` (Datumsfeld fuer Daily Challenge)
- Datenquelle:
  - `easy.txt`
  - `medium.txt`
  - `hard.txt`
  - `extreme.txt`
- Einfuegen der TXT-Daten nur einmalig (Initial-Seed)
- Spaeter: zufaelliges Sudoku passend zur gewaehlten Schwierigkeit laden

## Technische Entscheidung
Empfehlung: `sqflite` + `path` (leichtgewichtig, direkt SQLite, gut fuer Flutter lokal).

## Datenbankschema (V1)
Tabelle `sudoku`:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `level INTEGER NOT NULL`
- `difficulty TEXT NOT NULL CHECK(difficulty IN ('easy','medium','hard','extreme'))`
- `sudoku_string TEXT NOT NULL`
- `daily TEXT NULL` (ISO-Datum, z. B. `2026-04-01`)

Indizes/Constraints:
- `UNIQUE(difficulty, level)` (kein doppeltes Sudoku-Level pro Schwierigkeit)
- `UNIQUE(daily)` optional, falls pro Kalendertag nur ein Sudoku global erlaubt ist
- Index auf `difficulty`
- Index auf `daily`

Hinweis: Obwohl in der Vorgabe primaer `id`, `level`, `difficulty`, `daily` genannt sind, wird `sudoku_string` als zusaetzliches Pflichtfeld benoetigt, damit die Inhalte der TXT-Dateien gespeichert werden koennen.

## Datei- und Modulstruktur (Vorschlag)
- `assets/sudoku/easy.txt`
- `assets/sudoku/medium.txt`
- `assets/sudoku/hard.txt`
- `assets/sudoku/extreme.txt`
- `lib/core/database/app_database.dart` (DB oeffnen, Migrationen)
- `lib/features/sudoku/data/datasources/sudoku_local_datasource.dart` (CRUD/Queries)
- `lib/features/sudoku/data/repositories/sudoku_repository_impl.dart`

Zusaetzlich in `pubspec.yaml`:
- Assets registrieren (`assets/sudoku/`)
- Dependencies (`sqflite`, `path`)

## Schritt-fuer-Schritt-Umsetzung

## 1) Datenbank vorbereiten
- `sqflite` und `path` in `pubspec.yaml` ergaenzen.
- `AppDatabase` erstellen:
  - DB-Dateiname festlegen (z. B. `sudoku.db`)
  - `onCreate`: Tabelle `sudoku` + Indizes anlegen
  - `onUpgrade`: Versionierung vorbereiten

## 2) TXT-Dateien einbinden
- Die vier Dateien nach `assets/sudoku/` legen.
- Jede Zeile = ein Sudoku-String.
- Format pruefen:
  - Leerzeilen ignorieren
  - Laenge (typisch 81 Zeichen) validieren
  - nur erlaubte Zeichen (z. B. `0-9` oder `.-9`, je nach bestehender Spiel-Logik)

## 3) Einmaliges Initial-Seeding umsetzen
- Beim App-Start nach DB-Init pruefen:
  - `SELECT COUNT(*) FROM sudoku`
  - nur wenn `count == 0` Seed starten
- Fuer jede Datei:
  - `difficulty` aus Dateiname ableiten
  - Zeilen einlesen
  - laufenden `level` pro Schwierigkeit vergeben (1..n)
  - Datensaetze in Batch einfuegen:
    - `level`
    - `difficulty`
    - `sudoku_string`
    - `daily = NULL`

Sicherheitsaspekte:
- Seed in Transaktion ausfuehren
- Bei Fehlern Rollback
- Logging (Anzahl eingefuegter Zeilen pro Schwierigkeit)

## 4) Query fuer Zufallssudoku nach Schwierigkeit
- Repository-API definieren, z. B.:
  - `Future<SudokuEntity> getRandomByDifficulty(SudokuDifficulty difficulty)`
- SQL-Query:
  - `SELECT * FROM sudoku WHERE difficulty = ? ORDER BY RANDOM() LIMIT 1`
- Optional:
  - zuletzt gespielte IDs cachen, um direkte Wiederholungen zu reduzieren

## 5) Daily-Challenge vorbereiten
- Daily-Logik (ein Vorschlag):
  - pro Datum genau ein Sudoku bestimmen
  - wenn fuer `today` kein Eintrag mit `daily = today` existiert:
    - zufaelliges, noch nicht als daily gesetztes Sudoku auswaehlen
    - `daily = today` setzen
  - danach immer dieses Sudoku fuer den Tag ausliefern
- API:
  - `Future<SudokuEntity> getOrCreateDailySudoku(DateTime date)`

## 6) Integration in bestehende Feature-Logik
- An der Stelle, wo aktuell ein Sudoku geladen wird:
  - bei Modus "normal": `getRandomByDifficulty(...)`
  - bei Modus "daily": `getOrCreateDailySudoku(today)`
- `difficulty` als Enum im Domain-Layer halten und sauber auf DB-String mappen.

## 7) Tests
- Unit-Tests:
  - Parser fuer TXT-Zeilen (Validierung)
  - Mapping Difficulty Enum <-> DB String
- Integrationstests (lokale Test-DB):
  - Seed laeuft nur einmal (zweiter App-Start fuegt nichts nach)
  - Zufallsquery liefert nur passende Schwierigkeit
  - Daily liefert am gleichen Tag immer denselben Datensatz

## 8) Migrationen/Erweiterungen (spaeter)
- DB-Versionierung ab V1 konsequent pflegen
- Optionale neue Felder:
  - `source` (Herkunft der Daten)
  - `created_at`
  - `is_daily_locked`

## Akzeptanzkriterien
- Beim ersten Start werden alle Sudokus aus den 4 TXT-Dateien genau einmal importiert.
- Beim erneuten Start erfolgt kein doppelter Import.
- Fuer jede gewaehlte Schwierigkeit wird ein zufaelliges Sudoku derselben Schwierigkeit geladen.
- Daily-Challenge kann ueber `daily` stabil pro Datum ausgeliefert werden.

## Annahmen
- `level` wird als laufender Index pro Schwierigkeit interpretiert.
- `daily` wird als ISO-Datum (`yyyy-MM-dd`) gespeichert, nicht als Timestamp.
- Sudoku-Strings liegen zeilenweise in den TXT-Dateien vor.
