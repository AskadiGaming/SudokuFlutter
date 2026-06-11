# Implementierungsplan: Hinweis-Button mit Werbespot und Blink-Markierung

## Ziel
Es soll in der Sudoku-Ansicht einen Button `Hinweis` geben.

Beim Klick auf diesen Button gilt folgender Ablauf:
- zuerst wird ein Werbespot als Bezahlung fuer den Hinweis abgespielt
- danach wird genau ein noch nicht korrekt ausgefuelltes Sudoku-Feld automatisch mit der richtigen Zahl befuellt
- die betroffene Zelle blinkt 10x, damit der Spieler den Hinweis klar erkennt

Wenn kein Hinweis mehr moeglich ist, soll der Button nicht mehr aktiv sein oder nicht mehr angezeigt werden.

## Ist-Zustand
- Die zentrale Sudoku-Spielseite ist `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Das aktuelle Puzzle liegt dort als `SudokuGridData` in `_gridData`.
- `SudokuGridData` enthaelt bereits:
  - `currentGrid`
  - `solutionGrid`
  - `isFixed`
- Die App hat bereits eine Ads-Struktur unter `lib/features/ads/`.
- Es gibt bereits einen bestehenden Ad-Flow fuer Interstitials vor einem Spielstart.
- Das Grid wird ueber `lib/features/sudoku/presentation/widgets/sudoku_grid.dart` gerendert.

Wichtige Erkenntnis:
Die Logik, welche Zahl korrekt ist, muss nicht neu erfunden werden. Die vollstaendige Loesung liegt schon in `solutionGrid` vor. Fuer den Hinweis muss also nur eine geeignete Zielzelle gefunden und visuell hervorgehoben werden.

## Fachliche Entscheidungen fuer das MVP
1. Der Hinweis ist eine bezahlte Aktion ueber Werbung.
2. Ein Hinweis wird nur vergeben, wenn der Werbespot erfolgreich durchlaufen wurde.
3. Pro Klick wird genau ein Feld automatisch korrekt gesetzt.
4. Es wird nur ein Feld gewaehlt, das aktuell noch nicht korrekt ausgefuellt ist.
5. Bereits fixe Startfelder werden niemals veraendert.
6. Die Zielzelle blinkt genau 10x.
7. Waehrend Ad-Flow und Blink-Animation sollen keine widerspruechlichen Mehrfachklicks moeglich sein.

## Offene Produktentscheidung vor der spaeteren Umsetzung
Es sollte einmal festgelegt werden, wie streng der Ad-Erfolg fuer die Auszahlung des Hinweises bewertet wird.

Empfehlung:
- Fuer dieses Feature mittelfristig einen echten Reward-Flow vorsehen.
- Falls das Unity-Plugin nur mit Interstitial gestartet wird, muss klar dokumentiert sein, dass der Hinweis nur nach einem technisch erfolgreich abgeschlossenen Show-Flow vergeben wird.

Grund:
Ein Hinweis ist eine klar bezahlte Gegenleistung. Fachlich passt dafuer ein Reward-Mechanismus besser als ein reines "Best Effort"-Interstitial.

## Umsetzungsstrategie

### 1. UI-Platz fuer den Hinweis-Button definieren
- In `PlaySudokuPage` einen neuen Button `Hinweis` einplanen.
- Empfohlene Position:
  - zwischen Sudoku-Grid und NumberPad
  - in derselben Aktionszone, in der bereits Dev-Buttons oder Zusatzaktionen liegen
- Der Button braucht einen klaren Disabled-Zustand.

Ergebnis:
Die Aktion ist sichtbar, aber stoert das bestehende Spiel-Layout nicht.

### 2. Hinweis-Verfuegbarkeit zentral berechnen
- Eine kleine Hilfslogik einfuehren, z. B.:
  - `bool get _canRequestHint`
- Diese Logik soll `false` liefern, wenn:
  - `_gridData == null`
  - das Sudoku bereits geloest ist
  - die Interaktion gerade gesperrt ist
  - bereits ein Hinweis-Flow laeuft
  - kein einziges nicht-fixes und noch nicht korrektes Feld mehr existiert

Wichtig:
- Nicht nur leere Felder zaehlen.
- Auch falsch eingetragene Werte muessen als hinweisfaehig gelten, weil der Hinweis laut Ziel ein Feld korrekt ausfuellen soll.

Ergebnis:
Der Button ist nur aktiv, wenn wirklich ein sinnvoller Hinweis vergeben werden kann.

### 3. Zielzelle fuer den Hinweis fachlich festlegen
- Eine Methode in `PlaySudokuPage` einplanen, z. B.:
  - `_findHintTargetCell()`
- Diese Methode soll eine beschreibbare Zelle suchen, bei der:
  - `isFixed == false`
  - `currentGrid[row][col] != solutionGrid[row][col]`
- Fuer das MVP eine deterministische Regel verwenden.

Empfehlung:
- erstes passendes Feld in Leserichtung (`row 0..8`, `col 0..8`)

Warum diese Regel sinnvoll ist:
- einfach testbar
- reproduzierbar
- spaeter leicht austauschbar, falls eine "intelligentere" Hinweislogik gewuenscht ist

Ergebnis:
Der Hinweis trifft immer genau eine klar definierte Zelle.

### 4. Ads-Flow fuer den Hinweis kapseln
- Die bestehende Ads-Struktur nicht direkt in Widget-Code verstreuen.
- Stattdessen einen eigenen Anwendungsfall vorsehen, z. B.:
  - `ShowAdForHintUseCase`
  - oder eine allgemeinere Erweiterung des bestehenden Ad-Service
- Der Flow sollte:
  - Plattform-Support pruefen
  - Ad initialisieren/laden/anzeigen
  - ein klares Ergebnis zurueckgeben (`granted`, `skipped`, `failed`)

Wichtige Abgrenzung:
- Das bestehende `ShowAdBeforeRoundUseCase` ist auf "vor Spielstart" zugeschnitten.
- Der Hinweis ist ein anderer fachlicher Fall und sollte nicht per Copy-Paste in die Spielseite eingebaut werden.

Ergebnis:
Die Werbe-Logik bleibt sauber testbar und austauschbar.

### 5. Klick-Flow fuer den Hinweis-Button definieren
- In `PlaySudokuPage` eine Orchestrierungsmethode einplanen, z. B.:
  - `_requestHint()`
- Empfohlener Ablauf:
  1. Guard-Pruefung: ist ein Hinweis aktuell erlaubt?
  2. Zielzelle vorab bestimmen
  3. Button/Interaktion temporaer sperren
  4. Ad-Flow ausfuehren
  5. Nur bei erfolgreicher Auszahlung den Hinweis anwenden
  6. Blink-Animation starten
  7. Danach normalen Spielzustand wieder freigeben

Wichtig:
- Wenn Ad fehlschlaegt oder nicht verfuegbar ist, darf kein Feld befuellt werden.
- Der State muss auch bei Fehlern oder Timeouts sauber entsperrt werden.

Ergebnis:
Der gesamte Hint-Ablauf ist als eine klar lesbare Aktion gekapselt.

### 6. Korrekte Zahl ins Sudoku schreiben
- Eine eigene Methode einplanen, z. B.:
  - `_applyHintToCell(int row, int col)`
- Diese Methode soll:
  - den Wert aus `solutionGrid[row][col]` lesen
  - `currentGrid[row][col]` auf diesen Wert setzen
  - Replay-Logging und Challenge-Autosave so behandeln wie bei einer normalen Eingabe

Wichtige Detailentscheidung:
- Der Hinweis sollte technisch moeglichst denselben Persistenz- und Prüfpfad nutzen wie ein normaler Zug.
- Falls das bestehende Logging zwischen Nutzerzug und Systemzug unterscheiden soll, kann spaeter ein eigenes Replay-Event noetig werden.

Ergebnis:
Der Hinweis veraendert den Spielstand konsistent und nachvollziehbar.

### 7. Blink-Animation fuer die Hinweiszelle einbauen
- `SudokuGrid` braucht zusaetzliche Information, welche Zelle gerade als Hinweis markiert wird.
- Sinnvoll waere ein kleiner UI-State in `PlaySudokuPage`, z. B.:
  - `int? _hintBlinkCellIndex`
  - `bool _hintBlinkVisible`
- Die Zelle soll 10x blinken.

Empfohlene technische Umsetzung:
- Timer- oder Animationscontroller-gesteuert
- 10 sichtbare Wechsel zwischen hervorgehoben und normal
- waehrenddessen klare, auffaellige Hintergrundfarbe

Wichtig:
- Die Blink-Markierung soll zusaetzlich zur bestehenden `activeValue`-Markierung funktionieren.
- Die Hinweis-Markierung sollte visuell Vorrang haben, solange sie aktiv ist.

Ergebnis:
Der Spieler sieht eindeutig, welches Feld durch den Hinweis befuellt wurde.

### 8. Zusammenspiel mit Finish-Logik absichern
- Nach dem Setzen des Hinweis-Werts soll wie bisher geprueft werden, ob das Sudoku jetzt geloest ist.
- Wenn der Hinweis das letzte noch falsche Feld korrigiert, darf der normale Finish-Flow starten.
- Die Blink-Animation darf dabei den Abschluss nicht kaputt machen.

Empfehlung:
- erst Wert setzen
- dann Blink-Zustand aktivieren
- danach bestehende Solve-Pruefung nutzen

Zu pruefen bei der Umsetzung:
- Soll die Blink-Animation auch noch sichtbar sein, wenn direkt der Solved-Overlay erscheint?
- Falls das stoert, kann der letzte Hinweis vor dem Solve-Zustand visuell verkuerzt oder uebersprungen werden.

Ergebnis:
Der Hinweis fuegt sich sauber in den bestehenden Abschluss-Flow ein.

### 9. Fehler- und Sonderfaelle definieren
- Kein passendes Feld mehr vorhanden:
  - Button deaktivieren
- Ad nicht geladen oder fehlgeschlagen:
  - kein Hinweis vergeben
  - optional kurze Rueckmeldung per SnackBar
- Nutzer klickt mehrfach schnell:
  - nur ein laufender Hint-Flow erlaubt
- Puzzle ist bereits geloest:
  - Button deaktiviert
- Nicht-mobile Plattform:
  - fachlich entscheiden, ob Hinweis dort deaktiviert oder als immer nicht verfuegbar behandelt wird

Ergebnis:
Das Verhalten bleibt auch in Randfaellen stabil und nachvollziehbar.

### 10. Tests fuer die spaetere Umsetzung einplanen
- Unit-Tests:
  - Zielzelle wird korrekt gefunden
  - fixe Felder werden nie als Hinweisziel gewaehlt
  - falsche und leere Werte gelten als hinweisfaehig
- Widget-Tests:
  - `Hinweis`-Button sichtbar und korrekt deaktiviert/aktiviert
  - nach erfolgreichem Flow wird genau ein Feld korrekt gesetzt
  - die gesetzte Zelle blinkt
  - bei Ad-Fehler wird kein Feld veraendert
- Integrations-/Manuelle Tests:
  - Android/iOS mit echtem Ad-Flow
  - kein Hinweis mehr moeglich, wenn alle variablen Felder korrekt sind
  - letzter Hinweis kann das Sudoku regulär abschliessen

Ergebnis:
Das Feature ist funktional und regressionsarm abgesichert.

## Voraussichtlich betroffene Dateien
- `docs/button_hinweis.md`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`
- `lib/features/ads/application/ad_service.dart`
- ggf. neu:
  - `lib/features/ads/application/show_ad_for_hint_use_case.dart`
  - `lib/features/ads/domain/ad_reward_type.dart`
  - `lib/features/sudoku/domain/hint_target_cell.dart`
- ggf. Tests:
  - neuer Widget-Test fuer den Hinweis-Button
  - Erweiterungen bestehender Sudoku-Tests

## Akzeptanzkriterien fuer die spaetere Umsetzung
1. In der Sudoku-Ansicht gibt es einen Button `Hinweis`.
2. Beim Klick wird zuerst ein Werbespot-Flow gestartet.
3. Nur nach erfolgreichem Ad-Ergebnis wird genau ein Feld korrekt gesetzt.
4. Das gesetzte Feld war vorher nicht fix und nicht bereits korrekt.
5. Die gesetzte Zelle blinkt 10x.
6. Waehrend des Flows sind widerspruechliche Mehrfachausloesungen verhindert.
7. Wenn kein Hinweis mehr moeglich ist, ist der Button deaktiviert oder nicht sichtbar.
8. Wenn der Hinweis das letzte fehlende Feld setzt, bleibt der bestehende Sudoku-Abschluss korrekt funktionsfaehig.

## Empfehlung fuer die Reihenfolge der spaeteren Umsetzung
1. Zuerst die reine Sudoku-Hinweislogik ohne Ads bauen und testen.
2. Danach den Ad-Flow fuer den Hinweis kapseln.
3. Anschliessend die Blink-Animation integrieren.
4. Zum Schluss Edge Cases und End-to-End-Tests absichern.

So bleibt die Umsetzung gut debugbar, weil Fachlogik, Monetarisierung und Animation nacheinander eingefuehrt werden.
