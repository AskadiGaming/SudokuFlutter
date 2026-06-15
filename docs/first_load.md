# Implementierungsplan: Erster App-Start mit Splashscreen und Fortschrittsbalken

## Zielbild
Beim allerersten Start nach der Installation soll die App nicht direkt in die normale Navigation springen, waehrend die Sudoku-Datenbank erst beim ersten Spielzugriff befuellt wird.
Stattdessen soll ein eigener Startfluss mit Splashscreen erscheinen, der die initiale Vorbereitung sichtbar ausfuehrt.
Der Nutzer soll ueber einen Fortschrittsbalken und kurze Statusmeldungen sehen, dass die App Daten vorbereitet.
Nach erfolgreichem Abschluss soll die App wie gewohnt in die normale Hauptnavigation wechseln.
Ab dem zweiten Start soll dieser Initial-Seed nicht erneut sichtbar laufen.

## Vermutete Ursache im aktuellen Stand
- Die Sudokus werden aktuell nicht beim App-Start importiert, sondern erst beim ersten Zugriff auf `SudokuLocalDataSource.ensureSeeded()`.
- Diese Seed-Logik liest nacheinander alle Asset-Dateien unter `assets/sudoku/` und schreibt alle Datensaetze in die Tabelle `sudoku`.
- `ensureSeeded()` wird unter anderem aus `getRandomByDifficulty()`, `getOrCreateDailySudoku()`, `LocalChallengeRepository.loadMonthData()` und `LocalChallengeRepository.loadOrCreateRoundData()` aufgerufen.
- Dadurch tritt die Wartezeit aus Nutzersicht spaet auf, also genau dann, wenn eigentlich schon schnell ein Sudoku oder eine Challenge angezeigt werden soll.

## Relevante bestehende Einstiegspunkte
- `lib/main.dart`
  - initialisiert Flutter und die SQLite-Factory
- `lib/app/app.dart`
  - initialisiert aktuell Sprache und Profil
  - zeigt danach direkt `MainNavigationPage`
- `lib/features/sudoku/data/datasources/sudoku_local_datasource.dart`
  - enthaelt die aktuelle Seed-Logik
- `lib/features/challenge/data/local_challenge_repository.dart`
  - fordert ebenfalls frueh `ensureSeeded()` an

## Zielarchitektur fuer die spaetere Umsetzung
- Ein zentraler App-Startup-Flow entscheidet beim Start:
  - erster Start mit noetiger Datenvorbereitung
  - normaler Folge-Start ohne sichtbaren Seed-Screen
- Die Seed-Logik bleibt fachlich an einer Stelle gebuendelt, wird aber um Fortschrittsinformationen erweitert.
- UI und Initialisierung werden getrennt:
  - Startup-Orchestrierung bzw. Bootstrap-Service
  - Splashscreen-UI
  - bestehende Datenimport-Logik
- Der erste Import soll moeglichst idempotent bleiben:
  - wenn die Datenbank bereits befuellt ist, wird sofort uebersprungen
  - wenn der Seed unterbrochen wurde, muss der naechste Start sauber weiter bzw. erneut sicher starten koennen

## Vorschlag fuer die Architektur

### 1. Startup-Koordinator einfuehren
- Neue Komponente, z. B. `AppStartupController`, `AppBootstrapController` oder `InitialLoadCoordinator`
- Verantwortung:
  - Profileinstellungen und Sprache laden
  - pruefen, ob ein Initial-Seed noetig ist
  - Seed mit Fortschritt starten
  - Fehlerzustand fuer den Splashscreen bereitstellen
  - nach Erfolg die Haupt-App freigeben

### 2. Seed-Logik vom reinen `ensureSeeded()` in einen beobachtbaren Prozess ueberfuehren
- Die aktuelle Logik in `SudokuLocalDataSource` eignet sich als fachliche Basis, liefert aber noch keinen Fortschritt.
- Empfohlen:
  - einen dedizierten `SudokuSeedService` oder `SudokuInitializationService` einfuehren
  - dieser kapselt die Schritte:
    - Datenbank oeffnen
    - vorhandene Datensaetze pruefen
    - Asset-Datei pro Schwierigkeit laden
    - Sudoku-Zeilen parsen
    - Batch-Insert pro Schwierigkeit ausfuehren
- Die bestehende `ensureSeeded()`-Methode kann spaeter intern auf diesen Service delegieren, damit alte Aufrufer kompatibel bleiben.

### 3. Fortschrittsmodell definieren
- Statt eines ungenauen "indeterminate" Loaders soll ein echter `LinearProgressIndicator(value: ...)` verwendet werden.
- Da `loadString()` selbst keinen Byte-Fortschritt liefert, ist ein schrittbasierter Fortschritt fuer die erste Version sinnvoll.
- Vorschlag fuer die Fortschrittsphasen:
  - 5 %: Datenbankzugriff initialisiert
  - 10 %: Seed-Bedarf geprueft
  - 20 %: `easy.txt` geladen und geparst
  - 40 %: `medium.txt` geladen und geparst
  - 60 %: `hard.txt` geladen und geparst
  - 80 %: `extreme.txt` geladen und geparst
  - 95 %: Datenbank-Batch abgeschlossen
  - 100 %: App bereit
- Alternativ etwas feiner:
  - pro Schwierigkeit zwei Teilphasen:
    - Datei lesen
    - Datensaetze schreiben
- Zusaetzlich kurze Statusmeldungen anzeigen, z. B.:
  - `Bereite Datenbank vor`
  - `Lade leichte Sudokus`
  - `Importiere mittlere Sudokus`
  - `Initialisierung abgeschlossen`

### 4. First-Launch-Erkennung sauber festlegen
- Nur ein `SharedPreferences`-Flag wie `first_launch_completed` waere allein zu fragil.
- Bevorzugt:
  - Primaere Quelle: `SELECT COUNT(*) FROM sudoku`
  - Optional zusaetzlich ein Preference-Flag fuer UI-Steuerung oder Telemetrie
- Vorteil:
  - auch nach App-Abbruch oder inkonsistentem Preference-Stand bleibt die Wahrheit in der Datenbank

### 5. Splashscreen als eigener Screen statt Overlay
- Empfohlen ist ein eigener Startscreen vor `MainNavigationPage`.
- Vorteil:
  - klarer Ablauf
  - keine halb initialisierte Hauptnavigation im Hintergrund
  - Fehler- und Retry-Zustand lassen sich sauber darstellen
- Moegliche Widgets:
  - `AppStartupGate`
  - `FirstLoadSplashPage`
  - `StartupProgressCard`

## Umsetzungsphasen

### 1. Initialisierungsfluss zentralisieren
- In `lib/app/app.dart` die App-Initialisierung nicht mehr nur fuer Sprache und Profil verwenden.
- Einen gemeinsamen Startup-Flow bauen, der alle notwendigen Startaufgaben kennt.
- `home:` soll zunaechst einen Startup-Screen oder ein Startup-Gate anzeigen.

### 2. Seed-Service mit Progress-Events bauen
- Seed-Logik aus `SudokuLocalDataSource` extrahieren oder dort intern erweitern.
- Ein Zustandsmodell definieren, z. B.:
  - `progress` als `double` von `0.0` bis `1.0`
  - `message` als sichtbarer Statustext
  - `isComplete`
  - `error`
- Technisch moegliche Formen:
  - `ChangeNotifier`
  - `ValueNotifier`
  - `Stream<StartupProgress>`
- Fuer die bestehende Codebasis wirkt `ChangeNotifier` oder `ValueNotifier` am naheliegendsten.

### 3. Splashscreen-UI erstellen
- Neuer Screen fuer den ersten Start:
  - App-Logo oder Sudoku-Titel
  - kurzer Einleitungstext
  - Fortschrittsbalken
  - aktuelle Statusmeldung
- Optional:
  - kleiner Hinweis wie `Dies passiert nur beim ersten Start`
- Wichtig:
  - nicht zu ueberladen
  - auch auf kleineren Displays gut lesbar

### 4. Normale App erst nach Abschluss freischalten
- Wenn Startup erfolgreich:
  - in `MainNavigationPage` wechseln
- Wenn keine Initialisierung noetig:
  - Splashscreen sofort ueberspringen
- Wenn Fehler auftritt:
  - Fehlertext plus Retry-Button anzeigen

### 5. Bestehende Sudoku-Zugriffe kompatibel halten
- `getRandomByDifficulty()` und `getOrCreateDailySudoku()` sollen weiterhin sicher funktionieren.
- Auch nach Einfuehrung des Startup-Seeds sollte `ensureSeeded()` defensiv erhalten bleiben, damit spaetere Codepfade nicht brechen.
- Dabei aber vermeiden, dass dieselbe Arbeit zweimal parallel startet.

### 6. Fehler- und Abbruchverhalten absichern
- Falls Asset-Datei ungueltig ist oder DB-Insert fehlschlaegt:
  - Splashscreen darf nicht haengen bleiben
  - Nutzer muss einen klaren Fehler sehen
  - Retry soll denselben Ablauf erneut anstossen koennen
- Seed sollte weiterhin in Transaktionen laufen, damit keine halb fertigen Datenbestaende sichtbar werden.

## Technische Detailentscheidungen fuer die spaetere Umsetzung

### Option A: `SudokuLocalDataSource` direkt erweitern
- Vorteile:
  - wenig neue Dateien
  - bestehende Seed-Logik bleibt nah am Datenzugriff
- Nachteile:
  - Datenquelle bekommt UI-nahe Verantwortung fuer Fortschritt
  - langfristig schwerer testbar

### Option B: separaten `SudokuSeedService` einfuehren
- Vorteile:
  - sauberere Trennung
  - Fortschrittslogik, Seed-Logik und Datenquelle sind klar separiert
  - besser fuer Tests und spaetere Erweiterungen
- Nachteile:
  - etwas mehr Umbau

### Empfehlung
- Option B ist fuer die spaetere Umsetzung vorzuziehen.
- `SudokuLocalDataSource` sollte dann nur noch:
  - Seed sicher anfordern koennen
  - auf einen gemeinsamen Seed-Service delegieren

## Vorschlag fuer betroffene Dateien
- `lib/app/app.dart`
- optional neu: `lib/app/startup/app_startup_controller.dart`
- optional neu: `lib/app/startup/app_startup_state.dart`
- optional neu: `lib/app/startup/app_startup_gate.dart`
- optional neu: `lib/app/startup/first_load_splash_page.dart`
- `lib/features/sudoku/data/datasources/sudoku_local_datasource.dart`
- optional neu: `lib/features/sudoku/data/services/sudoku_seed_service.dart`
- optional neu: `lib/features/sudoku/data/models/startup_progress.dart`
- eventuell Tests unter:
  - `test/`
  - spaeter Widget-Test fuer Splashscreen
  - spaeter Datenquellen-/Seed-Test

## Empfohlene Reihenfolge fuer die Umsetzung
1. Seed-Logik fachlich isolieren, ohne Verhalten zu aendern.
2. Fortschrittsmodell und Startup-State definieren.
3. Startup-Gate in `app.dart` einhaengen.
4. Splashscreen mit Progressbar bauen.
5. Seed-Service an den Splashscreen anbinden.
6. Fehler- und Retry-Zustand einbauen.
7. Bestehende Datenzugriffe auf Kompatibilitaet pruefen.
8. Tests und manuelle Verifikation nachziehen.

## Testplan fuer die spaetere Umsetzung

### Unit-Tests
- Seed wird uebersprungen, wenn `sudoku` bereits Datensaetze enthaelt.
- Seed importiert alle Schwierigkeiten genau einmal.
- Fortschrittszustand laeuft in plausibler Reihenfolge von 0 bis 100 %.
- Fehler beim Asset-Parsing fuehren zu einem Fehlerzustand.

### Widget-Tests
- Beim ersten Start wird der Splashscreen angezeigt.
- Der Splashscreen zeigt Fortschrittsbalken und Statusmeldung.
- Nach erfolgreichem Abschluss wird die Hauptnavigation angezeigt.
- Bei Fehler erscheint ein Retry-Button.

### Manuelle Tests
- Neuinstallation der App:
  - Splashscreen erscheint
  - Fortschritt bewegt sich sichtbar
  - nach Abschluss startet die App normal
- Zweiter Start:
  - kein langer Splashscreen mehr
  - Quickmatch und Challenge reagieren schnell
- Fehlerfall:
  - defekte Asset-Datei simulieren
  - Fehlermeldung und Retry pruefen

## Akzeptanzkriterien
- Beim ersten App-Start wird der Nutzer nicht direkt in einen spaet blockierenden Spielfluss geschickt.
- Stattdessen erscheint ein Splashscreen mit sichtbarem Fortschrittsbalken.
- Der Seed importiert die Sudoku-Daten weiterhin nur dann, wenn sie noch nicht vorhanden sind.
- Nach erfolgreicher Initialisierung startet die App automatisch in die normale Hauptnavigation.
- Bei spaeteren App-Starts wird der Initial-Seed nicht erneut sichtbar ausgefuehrt.
- Fehler waehrend der Initialisierung fuehren zu einem klaren Fehlerzustand mit Wiederholmoeglichkeit.

## Offene Entscheidungen vor der Umsetzung
- Soll der Splashscreen nur beim echten Erststart sichtbar sein oder auch bei spaeteren Reparatur-Seeds?
- Soll der Fortschritt rein schrittbasiert sein oder spaeter feiner pro Anzahl importierter Sudokus laufen?
- Soll waehrend des Seeds bereits parallel die Profil-/Spracheinstellung geladen werden, um Startzeit zu sparen?
- Soll nach erfolgreichem Seed ein kleines lokales Flag gesetzt werden, obwohl die DB-Pruefung bereits ausreicht?

## Empfohlene Kurzentscheidung
- Erstversion mit eigenem Startup-Gate, separatem `SudokuSeedService`, schrittbasiertem Fortschritt und DB-basierter Seed-Pruefung.
- Das ist robust, fuer Nutzer klar sichtbar und passt gut zur bestehenden Architektur.
