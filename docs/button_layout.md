# Implementierungsplan: Neues Button-Layout im Sudoku-Screen

## Ziel
Der untere Bedienbereich der Sudoku-Ansicht soll visuell und funktional erweitert werden:

- Die Zahlen `1` bis `9` bleiben in einer Reihe nebeneinander.
- Jeder Zahlenbutton zeigt kuenftig zusaetzlich an, wie oft diese Zahl noch verwendet werden kann.
- Die Hauptzahl im Button soll optisch kraeftiger wirken als bisher.
- Oberhalb der Zahlenreihe soll eine neue Aktionsleiste mit Icon + Text erscheinen.
- In dieser Aktionsleiste sollen `Rueckgaengig`, `Loeschen`, `Hinweis` und `Admin loesen` angezeigt werden.

Die Referenz fuer das Zielbild liegt in:
- `docs/gui/gui_zahlenbuttons.png`
- `docs/gui/gui_icon_buttons.png`

## Gewuenschtes Verhalten

### Zahlenbuttons
- Es gibt unten nur noch 9 Zahlenslots fuer `1` bis `9`.
- Jeder Button zeigt:
- oben gross die Zahl
- darunter klein die Restanzahl
- Die Restanzahl berechnet sich als `9 - aktuelle Vorkommen im currentGrid`.
- Beispiel:
- Wenn die `1` im aktuellen Grid schon 3-mal vorkommt, zeigt der Button unten `6`.
- Wenn eine Zahl bereits 9-mal vorkommt, zeigt der Button unten `0`.
- Die Buttons sollen weiterhin nebeneinander stehen und sich nicht umbrechen.

### Obere Aktionsleiste
- Oberhalb der Zahlenbuttons erscheint eine eigene Reihe fuer Aktionsbuttons.
- Jeder Aktionsbutton besteht aus:
- einem Icon
- einem Textlabel unter oder neben dem Icon, passend zur finalen Layout-Entscheidung
- Enthaltene Aktionen:
- `Rueckgaengig`
- `Loeschen`
- `Hinweis`
- `Admin loesen` nur wenn die bestehende Dev/Admin-Freigabe aktiv ist

## Ausgangslage im aktuellen Code
- Die Screen-Komposition liegt in `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Die Zahlenleiste liegt in `lib/features/sudoku/presentation/widgets/number_pad.dart`.
- Aktuell enthaelt das Number Pad 10 Slots:
- `1` bis `9`
- einen Delete-Slot mit Backspace-Icon
- Bereits vorhanden:
- Hinweis-Button als separater `OutlinedButton`
- Admin-Button als separater `OutlinedButton`
- Logik zur Zahlverfuegbarkeit in `lib/features/sudoku/domain/sudoku_number_availability.dart`
- Aktuell werden voll belegte Zahlen ausgeblendet; fuer das neue Layout wird stattdessen eine Restanzahl benoetigt.
- Eine Undo-Funktion ist derzeit fachlich noch nicht im Sudoku-Screen implementiert.

## Umsetzungsstrategie
Die spaetere Umsetzung sollte in 6 Bloecke aufgeteilt werden:
1. Datenbasis fuer Restanzahlen und Undo-Historie vorbereiten
2. Number Pad von 10 Slots auf 9 Zahlenslots mit Counter umbauen
3. Neue Aktionsleiste oberhalb des Number Pads einfuehren
4. Bestehende Aktionen in das neue Layout ueberfuehren
5. Undo fachlich sauber anbinden
6. Tests fuer Layout, Counter und Aktionsverhalten ergaenzen

## Schritt-fuer-Schritt-Plan

### 1. Zahlencounter fachlich sauber aus `currentGrid` ableiten
- Die Quelle der Wahrheit bleibt `SudokuGridData.currentGrid`.
- Statt nur `fullyUsedSudokuDigits(...)` zu berechnen, sollte eine allgemeinere Auswertung eingefuehrt werden, zum Beispiel:
- `Map<int, int> countSudokuDigits(List<List<int>> grid)`
- oder direkt `Map<int, int> remainingSudokuDigitUsages(List<List<int>> grid)`
- Empfehlung:
- die bestehende Datei `lib/features/sudoku/domain/sudoku_number_availability.dart` erweitern
- dort sowohl Zaehlung als auch Restanzahl kapseln
- Restlogik:
- fuer jede Zahl `1..9`: `remaining = 9 - count`
- Werte defensiv auf `0..9` begrenzen
- Der Counter soll automatisch nach jeder Grid-Aenderung stimmen:
- normale Eingabe
- Loeschen
- Hinweis
- Admin-Loesen
- spaeter Undo

Ergebnis:
Das UI liest nur noch vorbereitete Daten und fuehrt keine eigene Zaehllogik im Widget.

### 2. Zahlenbuttons visuell umbauen
- `SudokuNumberPad` in `lib/features/sudoku/presentation/widgets/number_pad.dart` umbauen.
- Der Delete-Slot faellt dort weg; das Widget zeigt nur noch `1` bis `9`.
- Fuer jeden Zahlenbutton werden zusaetzliche Daten benoetigt, z. B.:
- `remainingCount`
- optional `isDepleted`, falls fuer `0` ein eigener Stil gewuenscht ist
- Der Button-Inhalt wird von einer einzeiligen Zahl auf ein kleines vertikales Layout umgestellt:
- grosse Zahl oben
- kleine Restanzahl unten
- Die Zahl selbst soll mit hoeherem `fontWeight` dargestellt werden als bisher.
- Die Restanzahl soll bewusst kleiner und visuell sekundaer sein.
- Das horizontale Verhalten bleibt stabil:
- 9 Buttons nebeneinander
- bei schmalen Breiten weiterhin horizontal scrollbar, falls noetig
- keine Umbrueche in mehrere Reihen

Ergebnis:
Das Number Pad entspricht der Referenz aus `docs/gui/gui_zahlenbuttons.png`.

### 3. Obere Aktionsleiste als eigenes Widget einfuehren
- Oberhalb des Number Pads eine neue Aktionszeile einbauen.
- Empfehlung:
- neues Widget, z. B. `SudokuActionBar` oder `SudokuActionButtons`
- Ort voraussichtlich unter `lib/features/sudoku/presentation/widgets/`
- Jeder Eintrag soll einheitlich aufgebaut sein:
- Icon
- Label
- klarer aktiv/deaktiviert-Zustand
- einheitliche Touch-Flaeche
- Die Leiste sollte nicht direkt aus einer Mischung einzelner `Align`- und `OutlinedButton`-Widgets in `PlaySudokuPage` bestehen, weil das spaeter unuebersichtlich wird.
- Layout-Empfehlung:
- 4 gleich breite Slots in einer `Row`
- bei ausgeblendeter Admin-Aktion entweder:
- Slot komplett ausblenden und verbleibende Buttons neu verteilen
- oder bewusst nur 3 Slots rendern
- keine horizontale Scroll-Leiste fuer diese Aktionsbuttons

Ergebnis:
Das obere Bedienlayout ist als eigene Komponente gekapselt und spaeter leicht erweiterbar.

### 4. Bestehende Aktionen in die neue Leiste migrieren

#### 4.1 Loeschen
- Der bisherige Delete-Slot aus dem Number Pad wird durch einen Aktionsbutton `Loeschen` ersetzt.
- Fachlich soll dieselbe Funktion wie heute erhalten bleiben.
- Das bedeutet nach aktuellem Stand:
- `Loeschen` waehlt den Wert `0` als aktiven Eingabemodus
- anschliessend loescht ein Tap auf eine editierbare Zelle deren Inhalt
- Wichtig fuer die spaetere Umsetzung:
- pruefen, ob die visuelle Auswahl des Delete-Modus in der neuen Aktionsleiste sichtbar markiert werden soll
- Der Zahlenbereich unten enthaelt danach nur noch die Zahlen `1` bis `9`.

#### 4.2 Hinweis
- Die bestehende `Hinweis`-Logik aus `PlaySudokuPage` bleibt fachlich erhalten.
- Geaendert werden sollen nur:
- Position
- Darstellung
- Icon-Ergaenzung
- Der bestehende Loading-Zustand des Hinweis-Buttons muss auch im neuen Design sichtbar bleiben.
- Falls im Mockup gewuenscht, kann das Ad-Badge spaeter als kleine Ueberlagerung am Icon umgesetzt werden.

#### 4.3 Admin loesen
- Der bestehende Admin-Button wird in dieselbe Aktionsleiste verschoben.
- Die bestehende Freigabelogik ueber `_isAdminSolveButtonEnabled` bleibt erhalten.
- Das Label sollte kuerzer gefasst werden als der heutige Buttontext, damit die Aktionsleiste kompakt bleibt.
- Empfehlung:
- UI-Label spaeter z. B. `Loesen`
- interne Methode `_fillSudokuForAdminTestLeavingOneCellOpen()` unveraendert weiterverwenden, solange Undo noch nicht integriert ist

Ergebnis:
Die heute schon vorhandenen Sonderaktionen werden nur umpositioniert und neu gestaltet, ohne ihre Kernlogik neu zu erfinden.

### 5. Rueckgaengig-Funktion neu einfuehren
- Fuer `Rueckgaengig` ist zusaetzlich zur UI neue Fachlogik noetig.
- Zielverhalten laut Wunsch:
- jeder Klick macht die letzte Aktion rueckgaengig
- wiederholte Klicks fuehren schrittweise bis zum leeren Grid zurueck
- Empfehlung fuer die technische Umsetzung:
- eine lokale Undo-Historie in `PlaySudokuPage` aufbauen
- moegliches Modell:
- Liste oder Stack aus Eintraegen mit `row`, `col`, `previousValue`, `nextValue`, Zeitstempel und optional `actionType`
- Die bestehende Struktur `_GridWriteResult` ist dafuer eine gute Grundlage.
- Jeder schreibende Flow muss kuenftig einen Undo-Eintrag erzeugen:
- normale Zahleneingabe
- Loeschen
- Hinweis
- Admin-Loesen

#### Empfohlene fachliche Entscheidung fuer Mehrfachaenderungen
- `Hinweis` aendert genau eine Zelle und ist damit ein Undo-Schritt.
- `Admin loesen` aendert potenziell viele Zellen.
- Empfehlung:
- ein Klick auf `Admin loesen` wird als eine Undo-Gruppe gespeichert
- ein Klick auf `Rueckgaengig` macht dann die komplette Admin-Aktion rueckgaengig
- Begruendung:
- Das Verhalten ist fuer Nutzer besser vorhersehbar
- Ein Admin-Massenfill wuerde sonst sehr viele Undo-Klicks erzeugen

#### Wechselwirkung mit Replay/Autosave
- Undo darf nicht nur das sichtbare Grid zuruecksetzen, sondern muss auch mit bestehenden Nebenwirkungen sauber zusammenspielen.
- Zu pruefen und spaeter bewusst zu entscheiden:
- Soll Undo ebenfalls als Replay-Move geloggt werden?
- Soll Undo bei Challenge-Autosave sofort persistiert werden?
- Empfehlung:
- Undo als normalen Move mit `previousValue` und `nextValue` loggen
- dadurch bleibt der spaetere Replay-Verlauf konsistent

Ergebnis:
Die neue Aktion `Rueckgaengig` wird nicht nur optisch ergaenzt, sondern als vollwertiger Bedienpfad robust in den State-Flow eingebunden.

### 6. `PlaySudokuPage` Layout neu ordnen
- Der untere Teil von `_buildContent(...)` in `play_sudoku_page.dart` wird neu strukturiert.
- Heutiger Aufbau:
- Grid
- Hinweis-Button rechts
- optional Admin-Button rechts
- Number Pad
- Zielaufbau:
- Grid
- neue Aktionsleiste
- Zahlenleiste `1..9`
- Die Aktivierung/Deaktivierung soll zentral aus dem aktuellen Screen-State abgeleitet bleiben:
- `_isInteractionLocked`
- `_canRequestHint`
- `_isAdminSolveButtonEnabled`
- neuer `_canUndo`
- Falls ein eigener Delete-Auswahlzustand sichtbar wird, sollte dieser ebenfalls aus `_activeValue == 0` abgeleitet werden.

Ergebnis:
Die Seite bekommt eine klare, wartbare Struktur statt mehrerer lose platzierter Einzelbuttons.

### 7. Lokalisierung und Benennung nachziehen
- Die neuen Aktionslabels sollten nicht hart codiert bleiben.
- In `lib/l10n/*.arb` neue Keys einplanen, z. B.:
- `sudokuActionUndo`
- `sudokuActionDelete`
- `sudokuActionHint`
- `sudokuActionAdminSolve`
- Falls die bestehende `Sudoku`-Seite bereits weitere statische Texte direkt im Code traegt, kann dies bei der Umsetzung gleich mit bereinigt werden.

Ergebnis:
Die neue UI bleibt kompatibel mit der bestehenden Mehrsprachigkeit.

### 8. Tests erweitern

#### Domain-Tests
- Zaehllogik fuer Zahlen `1..9`
- Restanzahl korrekt bei leerem, teilgefuelltem und vollem Vorkommen
- Werte fuer `0` werden ignoriert

#### Widget-Tests
- `SudokuNumberPad` zeigt 9 Zahlenslots
- jede Zahl rendert Hauptwert und Restcounter
- Delete ist nicht mehr Teil des Number Pads
- Aktionsleiste zeigt Icon + Text
- deaktivierte Buttons sind korrekt nicht klickbar

#### Page-Tests
- Restanzahl aktualisiert sich nach Eingabe
- Restanzahl aktualisiert sich nach Loeschen
- Hinweis bleibt funktional, nur an neuer Position
- Admin-Button erscheint nur bei aktiver Freigabe
- Undo macht den letzten Schritt rueckgaengig
- wiederholtes Undo fuehrt schrittweise zurueck
- Undo einer Admin-Gruppe funktioniert konsistent

Ergebnis:
Die neue UI ist gegen visuelle und fachliche Regressionen abgesichert.

## Betroffene Dateien
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/widgets/number_pad.dart`
- optional neu: `lib/features/sudoku/presentation/widgets/sudoku_action_bar.dart`
- `lib/features/sudoku/domain/sudoku_number_availability.dart`
- optional neu: kleine Undo-Modelle oder Helper im Sudoku-Presentation-Bereich
- `lib/l10n/app_de.arb`
- weitere `lib/l10n/*.arb`
- Tests unter `test/`

## Risiken und Entscheidungen vor der Umsetzung
- Es muss bewusst festgelegt werden, ob `Loeschen` weiter nur den Modus `activeValue = 0` waehlt oder ob der neue obere Button sofort die aktuell selektierte Zelle loeschen soll.
- Empfehlung fuer Konsistenz:
- dieselbe Semantik wie heute beibehalten, also Delete-Modus statt Sofort-Loeschaktion
- Fuer `Rueckgaengig` muss entschieden werden, ob Massenaktionen wie `Admin loesen` als Einzelaktionen oder als Gruppe rueckgaengig gemacht werden.
- Empfehlung:
- gruppiert rueckgaengig machen
- Falls ein Zahlenbutton bei Restwert `0` noch sichtbar bleibt, muss der Stil klar zeigen, dass die Zahl nicht mehr verfuegbar ist oder zumindest vollstaendig ausgeschoepft ist.
- Empfehlung:
- sichtbar lassen, aber visuell schwaecher und weiterhin selektierbar nur dann, wenn das fachlich gewuenscht ist
- Alternativ kann der Button deaktiviert werden, wenn exakt dieselbe UX wie in der Referenz gewuenscht ist

## Akzeptanzkriterien
Das Feature gilt spaeter als erfolgreich umgesetzt, wenn:

- Unter dem Sudoku gibt es zuerst eine Aktionsleiste mit `Rueckgaengig`, `Loeschen`, `Hinweis` und optional `Admin loesen`.
- Jeder Aktionsbutton zeigt ein Icon und einen Text.
- Darunter stehen die 9 Zahlenbuttons weiterhin in einer horizontalen Reihe.
- Jeder Zahlenbutton zeigt die Zahl in etwas dickerer Schrift und darunter die verbleibende Nutzungsanzahl.
- Die Restanzahl entspricht jederzeit `9 - Vorkommen im aktuellen Grid`.
- Der bisherige Delete-Slot ist nicht mehr Teil des unteren Number Pads.
- `Hinweis` funktioniert weiter wie bisher, nur im neuen Design.
- `Admin loesen` funktioniert weiter wie bisher, nur im neuen Design und neuer Position.
- `Rueckgaengig` kann wiederholt genutzt werden und fuehrt Schritt fuer Schritt bis zum leeren Grid zurueck.
