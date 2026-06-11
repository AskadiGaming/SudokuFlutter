# Implementierungsplan: Kleiner Runden-Timer auf der Sudoku-Seite

## Ziel
Auf der Sudoku-Spielseite soll ein sehr kleiner Timer sichtbar sein, der anzeigt, wie lange die aktuelle Runde bereits laeuft.

Anforderungen:
- Der Timer soll links oben unter der Top-Navigationsleiste erscheinen.
- Die Schrift soll sehr klein sein.
- Die Schriftgroesse soll ungefaehr halb so gross sein wie die Zahlen im Sudoku-Grid.
- In normalen Runden startet der Timer bei `00:00` und laeuft waehrend der aktiven Spielzeit.
- In Challenge-Runden soll der Timer beim Fortsetzen nicht neu starten, sondern bei der bereits gespielten Zeit weiterlaufen.

## Ausgangslage
- Die Spielseite wird in `lib/features/sudoku/presentation/play_sudoku_page.dart` aufgebaut.
- Oberhalb des Inhalts gibt es bereits ein `Scaffold` mit `AppBar`, darunter `SafeArea` und einen `Stack`.
- Die Sudoku-Zahlen im Grid verwenden aktuell `theme.textTheme.titleLarge` in `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`.
- Fuer Challenge-Runden existiert bereits Persistenz ueber `ChallengeRepository` und `ChallengeRoundData`.
- Fuer aktive Spielzeit und Resume existiert bereits eine passende Basis im Replay-System:
  - `SudokuReplayLoggingController`
  - `currentElapsedMillis(...)`
  - Session-Start/Pause ueber `startSession(...)` und `pauseSession(...)`

Wichtig:
- `ChallengeRoundData.startedAt` beschreibt den Startzeitpunkt der Challenge, ist aber keine gute Quelle fuer einen sichtbaren Resume-Timer.
- Fuer den sichtbaren Timer sollte spaeter moeglichst dieselbe aktive Spielzeit verwendet werden, die auch fuer Replay und Abschlussdauer zaehlt.

## Umsetzungsstrategie
Wir teilen die spaetere Umsetzung in 5 Schritte:
1. Zeitquelle fachlich festlegen
2. Live-Timer-Zustand in `PlaySudokuPage` einfuehren
3. Kleines Timer-Widget fuer die Position links oben bauen
4. Resume-Verhalten fuer Challenge sauber anbinden
5. Tests fuer Anzeige, Tick-Verhalten und Resume ergaenzen

## Schritt-fuer-Schritt-Plan

### 1. Zeitquelle fachlich eindeutig festlegen
- Der sichtbare Timer soll aktive Spielzeit anzeigen, nicht reine Wandzeit.
- Dadurch soll die Zeit nicht weiterlaufen, wenn:
  - die Seite verlassen wird
  - die App pausiert oder in den Hintergrund geht
  - eine Challenge spaeter fortgesetzt wird
- Fuer die spaetere Implementierung sollte die Zeit daher nicht aus `DateTime.now() - _roundStartedAt` berechnet werden.
- Empfohlene Quelle:
  - live aus `_replayLoggingController.currentElapsedMillis(DateTime.now())`
- Vorteil:
  - dieselbe Logik wird bereits fuer Abschlussdauer und Replay verwendet
  - Challenge-Resume bekommt die zuvor gespielte aktive Zeit automatisch wieder
  - keine zweite, davon abweichende Timer-Logik noetig

Ergebnis:
Der sichtbare Timer und die intern gespeicherte aktive Spielzeit bleiben konsistent.

### 2. Lokalen Live-Timer in `PlaySudokuPage` einfuehren
- In `PlaySudokuPage` einen kleinen UI-Timer-Zustand ergaenzen, z. B.:
  - `Timer? _roundClockTimer`
  - `Duration _visibleElapsed = Duration.zero`
- Nach erfolgreichem Laden der Runde und nach Initialisierung des Replay-Controllers den sichtbaren Wert einmal initial setzen.
- Danach einen periodischen Tick starten, z. B. alle 1 Sekunde:
  - `currentElapsedMillis(DateTime.now())` lesen
  - in `Duration` umwandeln
  - per `setState` nur den sichtbaren Timer aktualisieren
- Beim `dispose`, beim Verlassen der Seite und beim Lifecycle-Pause den UI-Timer sauber stoppen.
- Beim Lifecycle-Resume den UI-Timer wieder starten, passend zur bereits vorhandenen Replay-Session-Logik.

Ergebnis:
Die Seite hat eine leichte, klar gekapselte Live-Anzeige fuer die aktuelle aktive Spielzeit.

### 3. Positionierung links oben unter der Top-Bar sauber umsetzen
- Die aktuelle Seite nutzt im Body bereits einen `Stack` mit globalem `Padding(16)`.
- Fuer die spaetere Umsetzung ist ein zusaetzliches, kleines Overlay-Element im bestehenden Body-`Stack` sinnvoll.
- Empfehlung:
  - Timer als eigenes Widget im `Stack`
  - `Positioned(top: 16, left: 16, child: ...)`
- Gleichzeitig sollte oberhalb des eigentlichen Inhalts etwas Platz reserviert werden, damit der Timer nicht mit Banner oder Grid kollidiert.
- Moegliche Umsetzung:
  - oberhalb des bisherigen `Column`-Inhalts ein fixer vertikaler Abstand
  - oder ein eigener oberer Slot fuer den Timer, falls das Layout spaeter ohne Overlay besser lesbar bleibt
- Der Timer soll bewusst unauffaellig sein:
  - kleine Schrift
  - keine dominante Karte
  - eher einfacher Text oder sehr dezentes Label wie `00:47`

Ergebnis:
Der Timer sitzt stabil links oben direkt unter der AppBar, ohne das Sudoku-Layout optisch zu stoeren.

### 4. Schriftgroesse relativ zum Sudoku-Grid definieren
- Die Grid-Zahlen verwenden aktuell `theme.textTheme.titleLarge`.
- Die Timer-Schrift soll ungefaehr halb so gross sein wie die sichtbaren Sudoku-Zahlen.
- Fuer die spaetere Umsetzung sollte diese Relation nicht als magische feste Zahl verteilt im Code landen.
- Empfehlung:
  - in `PlaySudokuPage` oder in einem kleinen Hilfswidget aus `theme.textTheme.titleLarge?.fontSize` ableiten
  - daraus `fontSize * 0.5` bilden
  - mit einem sinnvollen Fallback absichern, falls `fontSize` `null` ist
- Beispielhafte Zielrichtung:
  - Grid-Zahl etwa `titleLarge`
  - Timer etwa `titleLarge * 0.5`

Ergebnis:
Die gewuenschte visuelle Relation bleibt stabil, auch wenn das Theme spaeter angepasst wird.

### 5. Challenge-Resume explizit absichern
- Challenge-Runden sollen beim Fortsetzen nicht wieder bei `00:00` starten.
- Die vorhandene Replay-Initialisierung nutzt bereits `allowResume: true` fuer Challenge-Runden.
- Dadurch werden bestehende Sessions und ihre aktive Dauer beim Oeffnen einer offenen Challenge erneut geladen.
- Der sichtbare Timer sollte spaeter direkt nach `_initializeReplayLogging(...)` seinen Startwert aus dem Replay-Controller beziehen.
- Wichtig:
  - Der Timer darf erst starten, wenn diese Initialisierung abgeschlossen ist.
  - Sonst koennte die Anzeige kurzzeitig `00:00` zeigen, obwohl bereits Spielzeit vorhanden ist.
- Fuer normale Runden bleibt das Verhalten einfach:
  - neue Runde
  - neue Session
  - Timer startet bei `00:00`

Ergebnis:
Challenge-Resume funktioniert ohne Sonderpersistenz fuer einen separaten UI-Timer.

## Betroffene Dateien
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- optional neu: kleines Widget wie `lib/features/sudoku/presentation/widgets/sudoku_round_timer.dart`
- optional Tests im Sudoku-Presentation-Bereich
- `docs/timer.md`

## Technische Hinweise fuer die spaetere Umsetzung
- Der Timer sollte nicht direkt auf `ChallengeRepository.started_at` aufbauen, weil sonst Pausen und spaeteres Fortsetzen fachlich falsch als durchlaufende Echtzeit angezeigt wuerden.
- Die bestehende Replay-Session-Logik ist die robusteste Basis, weil sie aktive Spielzeit bereits korrekt in Sessions trennt.
- Falls der Timer als Overlay umgesetzt wird, sollte geprueft werden, ob `ModifierBanner` oder andere Elemente oben genug Abstand bekommen.
- Falls die Seite spaeter weitere Kopf-Informationen erhaelt, kann der Timer in einen kleinen, eigenen Header-Slot verschoben werden, solange er visuell links oben unter der AppBar bleibt.
- Der Timer sollte bei geloester Runde auf dem finalen Wert stehen bleiben und nicht weiterlaufen.

## Tests fuer die spaetere Umsetzung
- Widget-Test:
  - Timer ist auf der Spielseite sichtbar
  - Timer steht links oben im oberen Seitenbereich
- Widget-Test:
  - Anzeige startet in einer normalen Runde bei `00:00`
  - Anzeige springt nach Zeitablauf sichtbar weiter
- Widget- oder Integrations-Test:
  - Challenge mit vorhandener Replay-/Session-Zeit wird geoeffnet
  - Timer startet nicht bei `00:00`, sondern mit gespeicherter aktiver Zeit
- Widget-Test:
  - Nach App-Pause oder Seitenwechsel laeuft der Timer nicht unkontrolliert weiter
- Widget-Test:
  - Nach geloester Runde bleibt der Timer stehen

## Akzeptanzkriterien
Das Feature gilt spaeter als korrekt umgesetzt, wenn:
- Auf der Sudoku-Seite ist links oben unter der AppBar ein kleiner Timer sichtbar.
- Die Anzeige zeigt die bereits gespielte aktive Rundenzeit.
- Die Schrift ist deutlich kleiner als die Grid-Zahlen und etwa halb so gross wie deren Schrift.
- Normale Runden starten bei `00:00`.
- Challenge-Runden setzen die Anzeige beim Fortsetzen mit der bisherigen aktiven Zeit fort.
- Die Zeit laeuft nicht waehrend App-Pausen oder ausserhalb einer aktiven Spielsitzung weiter.
- Nach dem Loesen bleibt die Anzeige auf dem Endwert stehen.

## Empfehlung fuer die spaetere Umsetzung
- Nicht auf `startedAt` oder `updatedAt` der Challenge gehen.
- Den sichtbaren Timer direkt an die vorhandene Replay-Session-Zeit koppeln.
- Erst danach das kleine UI-Widget und die Positionierung links oben ergaenzen.
