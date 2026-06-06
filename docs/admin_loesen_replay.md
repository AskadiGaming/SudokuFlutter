# Implementierungsplan: Admin-Loesen im Replay sichtbar machen

## Ziel
Wenn der Admin-Loesen-Button in einer Sudoku-Runde genutzt wird, soll diese Aktion spaeter auch im Replay sichtbar sein.

Das bedeutet:
- die automatisch eingetragenen Zahlen muessen als Replay-Moves persistiert werden
- im Replay sollen die Felder daher an der passenden Stelle der Zeitleiste erscheinen
- genau ein Feld bleibt weiterhin offen, damit der normale Finish-Flow manuell getestet werden kann

## Aktueller Stand
- Der Admin-Button ist in `PlaySudokuPage` bereits vorhanden.
- Die Methode `_fillSudokuForAdminTestLeavingOneCellOpen()` fuellt das Grid derzeit direkt per `setState`.
- Manuelle Eingaben werden ueber `_replayLoggingController.logMove(...)` als `SudokuReplayMove` gespeichert.
- Das Replay rekonstruiert den sichtbaren Zustand ausschliesslich aus `puzzleString + moves`.

Konsequenz:
Die Admin-Aktion aendert zwar das Live-Grid, erzeugt aber aktuell keine Replay-Moves. Deshalb bleibt das Replay an dieser Stelle leer bzw. zeigt die Auto-Fuellung nicht an.

## Leitentscheidung fuer die spaetere Umsetzung
Empfohlen ist die kleine, robuste Loesung:
- keine neue Replay-Tabelle
- kein separates Event-Modell nur fuer Admin-Aktionen
- stattdessen dieselbe Replay-Move-Pipeline nutzen wie bei manuellen Zelleingaben

Damit bleibt das Replay deterministisch und die bestehende Architektur kann unveraendert weiterverwendet werden.

## Fachliches Zielbild
Beim Klick auf `Admin: fast loesen` passiert spaeter fachlich Folgendes:
1. Alle nicht-fixen Felder werden aus `solutionGrid` vorbereitet.
2. Genau ein nicht-fixes Feld bleibt auf `0`.
3. Fuer jedes durch den Admin geaenderte Feld wird ein `SudokuReplayMove` geschrieben.
4. Felder, die bereits den korrekten Wert enthalten, erzeugen keinen ueberfluessigen Move.
5. Die Runde gilt danach weiterhin als nicht geloest.
6. Das letzte Feld wird weiterhin manuell gesetzt und triggert erst dann den bestehenden Finish-Flow.

## Empfohlene Umsetzungsstrategie

### 1. Admin-Fuellung und Replay-Logging zusammenfuehren
- `_fillSudokuForAdminTestLeavingOneCellOpen()` soll nicht mehr nur das Grid mutieren.
- Stattdessen soll die Methode vor dem Schreiben fuer jedes betroffene Feld den `previousValue` ermitteln und anschliessend einen Replay-Move erzeugen.
- Die Admin-Aktion soll dieselbe Datenqualitaet liefern wie eine normale Spielaktion:
  - `row`
  - `col`
  - `previousValue`
  - `nextValue`
  - `elapsedMillis` indirekt ueber `logMove(..., at: ...)`

Empfehlung:
- innerhalb des Admin-Flows einmal `final DateTime actionTime = DateTime.now();` erfassen
- diesen Zeitstempel fuer alle erzeugten Replay-Moves wiederverwenden

Vorteil:
Im Replay erscheinen die automatisch gesetzten Zahlen gesammelt an genau einem Zeitpunkt, was das tatsaechliche Admin-Verhalten gut widerspiegelt.

### 2. Nur echte Aenderungen loggen
- Vor jedem Write pruefen:
  - ist das Feld nicht fix?
  - ist es nicht das bewusst offene Restfeld?
  - unterscheidet sich `currentGrid[row][col]` vom Zielwert aus `solutionGrid`?
- Nur wenn sich der Wert wirklich aendert, soll:
  - das Grid aktualisiert werden
  - ein Replay-Move geschrieben werden

Damit vermeiden wir:
- doppelte Replay-Eintraege
- unnoetiges Rauschen im Verlauf
- inkonsistente Sequenzen ohne sichtbare Aenderung

### 3. Offenes Restfeld explizit beruecksichtigen
- Das ausgewaehlte offene Feld bleibt weiter bewusst bei `0`.
- Falls dieses Feld vor dem Admin-Klick bereits einen falschen Wert enthaelt, sollte die spaetere Umsetzung entscheiden, ob:
  - der Wert aktiv auf `0` zurueckgesetzt und als Replay-Move gespeichert wird
  - oder das Feld unveraendert bleibt, solange es nicht korrekt geloest werden soll

Empfehlung fuer die spaetere Implementierung:
- das offene Feld immer deterministisch auf `0` setzen
- falls sich der bisherige Wert dadurch aendert, auch diesen Reset als Replay-Move loggen

Grund:
Dann stimmen Live-Grid und Replay sicher ueberein, auch wenn vor dem Admin-Klick schon Fehleingaben vorhanden waren.

### 4. Reihenfolge der Moves stabil halten
- Die Admin-Aktion sollte die betroffenen Felder in fester Leserichtung verarbeiten.
- Dadurch bleibt die erzeugte `sequence` stabil und testbar.
- Auch wenn alle Moves denselben Zeitstempel verwenden, ist die Reihenfolge in der Datenbank weiter eindeutig.

Empfehlung:
- Iteration wie bisher ueber `index 0..80`
- Auswahl des offenen Feldes weiterhin deterministisch

### 5. UI-Verhalten bewusst unveraendert lassen
- Der Button bleibt ein reiner Dev-Button.
- Nach dem Admin-Klick soll weiterhin kein automatischer Abschluss gestartet werden.
- `_checkSolvedAndMaybeStartFinishSequence()` soll erst nach dem manuellen letzten Feld wieder den normalen Abschluss ausloesen.

Das bestehende Testziel bleibt also erhalten:
- fast komplett geloest durch Admin
- final geloest durch manuelle Nutzereingabe

### 6. Optionale Erweiterung nur bei echtem Bedarf
Falls spaeter im Replay sichtbar unterschieden werden soll, ob ein Move manuell oder per Admin entstanden ist, koennte das Modell erweitert werden, z. B. um:
- `origin`
- oder `isAutomated`

Fuer das hier beschriebene Ziel ist das aber nicht notwendig.

Empfehlung:
- zuerst ohne Schema-Aenderung umsetzen
- nur bei spaeterem UI-Bedarf erweitern

## Voraussichtlich betroffene Dateien bei der spaeteren Umsetzung
- `docs/admin_loesen_replay.md`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- optional `lib/features/sudoku_replay/application/sudoku_replay_logging_controller.dart`, falls ein kleiner Hilfsweg fuer Bulk-Logging sinnvoll wird
- ggf. Tests unter `test/` fuer Admin-Button und Replay-Rekonstruktion

## Technische Umsetzungsschritte
1. Admin-Methode in `PlaySudokuPage` so umbauen, dass sie die Zielaenderungen zuerst berechnet.
2. Pro geaendertem Feld `previousValue` und `nextValue` bestimmen.
3. Grid aktualisieren.
4. Fuer jede echte Aenderung `unawaited(_replayLoggingController.logMove(...))` oder eine gebuendelte Logging-Hilfe aufrufen.
5. Offenes Restfeld bei Bedarf aktiv auf `0` zuruecksetzen und ebenfalls loggen.
6. Challenge-Autosave wie bisher nach der Grid-Aenderung weiterlaufen lassen.
7. Sicherstellen, dass kein automatischer Finish-Flow entsteht.

## Testplan fuer die spaetere Umsetzung

### Unit-/Widget-Tests
- Admin-Klick erzeugt Replay-Moves fuer alle geaenderten Auto-Felder.
- Bereits korrekte Felder erzeugen keine zusaetzlichen Moves.
- Das offene Restfeld bleibt nach der Aktion leer.
- Wenn das offene Restfeld vorher falsch befuellt war und auf `0` zurueckgesetzt wird, erscheint auch dafuer ein Replay-Move.
- Nach dem Admin-Klick ist das Sudoku noch nicht geloest.
- Nach manuellem Eintrag des letzten Feldes startet weiterhin der normale Finish-Flow.

### Replay-Tests
- Das Replay zeigt vor dem Admin-Zeitpunkt das urspruengliche bzw. bis dahin manuell gespielte Grid.
- Ab dem Admin-Zeitpunkt erscheinen die automatisch gesetzten Felder im Replay.
- Das Replay endet weiterhin erst mit dem manuellen letzten Feld im voll geloesten Zustand.

## Akzeptanzkriterien fuer die spaetere Implementierung
1. Die Admin-Loesen-Aktion ist im Replay sichtbar.
2. Alle automatisch gesetzten Felder werden im Replay korrekt eingetragen.
3. Es werden nur tatsaechlich geaenderte Felder als Move gespeichert.
4. Genau ein Feld bleibt nach der Admin-Aktion offen.
5. Die Runde wird durch den Admin-Klick noch nicht abgeschlossen.
6. Der bestehende Finish-Flow startet erst nach dem letzten manuellen Eintrag.

## Offene Detailentscheidung
Noch festzulegen ist nur das Verhalten des bewusst offenen Felds, wenn dort vor dem Admin-Klick bereits ein falscher Wert steht.

Empfehlung:
- offenes Feld immer explizit auf `0` setzen
- diese Aenderung ebenfalls loggen, falls sie eine echte Zustandsaenderung ist

Das ist die klarste und am besten testbare Variante.
