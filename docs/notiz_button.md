# Implementierungsplan: Notiz-Button fuer kleine Zellnotizen

## Ziel
In der Sudoku-Ansicht soll ein zusaetzlicher Icon-Button `Notiz` erscheinen.

Verhalten:
- Der Button nutzt ein Stift-Icon.
- Der Button ist ein-/ausschaltbar und zeigt seinen aktiven Zustand klar an.
- Wenn `Notiz` aktiv ist und der Spieler eine Zahl in eine editierbare Zelle eintraegt, wird diese Zahl nicht als normale Hauptzahl gesetzt, sondern als kleine Notiz in der linken unteren Ecke der Zelle angezeigt.
- Wenn spaeter die richtige Hauptzahl fuer diese Zelle eingetragen wird, wird die vorhandene Notiz in dieser Zelle automatisch entfernt.

## Ist-Zustand
- Die zentrale Spielseite ist `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Die untere Aktionsleiste liegt in `lib/features/sudoku/presentation/widgets/sudoku_action_bar.dart`.
- Das Grid wird in `lib/features/sudoku/presentation/widgets/sudoku_grid.dart` gerendert.
- Normale Eingaben laufen aktuell ueber `_writeActiveNumberToCell(...)` und `_writeValueToCell(...)`.
- Es gibt bereits Button-Zustaende fuer `Loeschen`, `Hinweis` und `Undo`.
- Das aktuelle Sudoku-Modell `SudokuGridData` enthaelt nur:
  - `initialGrid`
  - `currentGrid`
  - `solutionGrid`
  - `isFixed`

Wichtige Erkenntnis:
Notizen sind aktuell kein Teil des Grid-Datenmodells. Fuer die spaetere Umsetzung muss neben den Hauptzahlen ein eigener Notiz-State eingefuehrt werden.

## Fachliche Entscheidung fuer das MVP
Empfehlung fuer die erste Umsetzung:
- Pro Zelle wird genau eine kleine Notizzahl gespeichert.
- Die Notiz erscheint unten links in der Zelle.
- Eine neue Notiz in derselben Zelle ersetzt die vorherige Notiz.
- Eine normale Hauptzahl und eine Notiz koennen nicht gleichzeitig sichtbar sein.
- Sobald die eingetragene Hauptzahl der Loesung entspricht, wird die Notiz der Zelle geloescht.

Begruendung:
- Das passt am besten zur aktuellen Anforderung mit "eine ganz kleine Zahl".
- Der State bleibt deutlich einfacher als bei klassischen Mehrfach-Kandidaten.
- Die spaetere Erweiterung auf mehrere Kandidaten pro Zelle bleibt trotzdem moeglich.

## Offene Produktentscheidung vor der Umsetzung
Es sollte vor der eigentlichen Implementierung einmal festgelegt werden, ob Notizen nur waehrend der aktuellen Sitzung gelten oder auch persistiert werden sollen.

Empfehlung:
- MVP zuerst ohne Persistenz fuer Challenge-Fortschritt und Replay planen.
- Falls Notizen spaeter zwischen App-Neustarts erhalten bleiben sollen, braucht es eine Erweiterung der gespeicherten Round-/Challenge-Daten.

Grund:
- `currentGrid` wird heute bereits gespeichert.
- Notizen wuerden eine zusaetzliche serialisierbare Struktur benoetigen.
- Ohne diese Entscheidung droht sonst spaeter ein Umbau an Datenbank, Autosave und Replay.

## Umsetzungsstrategie

### 1. Neuen UI-Button `Notiz` in die Action Bar aufnehmen
- `SudokuActionBar` um einen weiteren Action-Button erweitern.
- Label: `Notiz`
- Icon: `Icons.edit_outlined` oder `Icons.create_outlined`
- Der Button braucht:
  - `isNoteModeSelected`
  - `canSelectNoteMode`
  - `onNoteModeSelected`
- Der aktive Zustand soll analog zum bestehenden `Loeschen`-Modus sichtbar markiert werden.

Wichtig:
- `Loeschen` und `Notiz` sind beides Eingabemodi.
- Es darf immer nur genau ein Spezialmodus aktiv sein:
  - normaler Zahlenmodus
  - Loeschen-Modus
  - Notiz-Modus

Ergebnis:
Die Umschaltung fuer Notizen ist sichtbar und fuegt sich in die vorhandene Aktionsleiste ein.

### 2. Note-Mode-State zentral in `PlaySudokuPage` fuehren
- In `PlaySudokuPage` einen eigenen UI-State einfuehren, z. B.:
  - `bool _isNoteModeEnabled`
- Alternativ moeglich:
  - den Eingabemodus als kleines Enum kapseln, z. B. `normal`, `delete`, `note`

Empfehlung:
- Mittelfristig ist ein Enum sauberer als mehrere lose Bool-/Value-Kombinationen.
- Fuer das MVP ist wichtig, dass die Umschaltung eindeutig bleibt und keine widerspruechlichen Kombinationen entstehen.

Zu beachten:
- Aktiviert der Nutzer `Notiz`, sollte ein bestehender `Loeschen`-Modus deaktiviert werden.
- Aktiviert der Nutzer `Loeschen`, sollte `Notiz` deaktiviert werden.
- Waehlt der Nutzer eine normale Zahl im Number Pad, bleibt `Notiz` aktiv, damit mehrere Notizen hintereinander gesetzt werden koennen.

Ergebnis:
Der Screen hat eine klare Quelle der Wahrheit fuer den aktuellen Eingabemodus.

### 3. Datenstruktur fuer Zellnotizen einfuehren
- Neben `currentGrid` eine separate Notizstruktur einfuehren.
- Empfehlung fuer das MVP:
  - `List<List<int?>> _cellNotes`
- Bedeutung:
  - `null` = keine Notiz
  - `1..9` = kleine Notizzahl fuer diese Zelle

Alternative:
- eigenes kleines Domain-Modell oder Value Object fuer spaetere Erweiterbarkeit

Wichtige Regeln:
- Fixe Zellen duerfen niemals Notizen bekommen.
- Wenn eine Hauptzahl ungleich `0` in einer Zelle steht, soll fuer diese Zelle keine Notiz sichtbar sein.
- Beim Laden einer neuen Runde muss die Notizstruktur mit 9x9 `null` initialisiert werden.

Ergebnis:
Notizen sind technisch von den echten Sudoku-Werten getrennt.

### 4. Schreiblogik fuer normale Zahl vs. Notiz trennen
- `_writeActiveNumberToCell(...)` ist der richtige Einstiegspunkt fuer die spaetere Verzweigung.
- Dort soll unterschieden werden:
  - `Loeschen` aktiv
  - `Notiz` aktiv
  - normaler Zahlenmodus aktiv

Empfohlene Aufteilung:
- normale Hauptzahl weiter ueber `_writeValueToCell(...)`
- neue Hilfsmethode fuer Notizen, z. B.:
  - `_writeNoteToCell(int row, int col, int noteValue)`

Regeln fuer `_writeNoteToCell(...)`:
- nur editierbare Zellen erlauben
- nur Werte `1..9` erlauben
- wenn in der Zelle bereits eine Hauptzahl steht, fachlich entscheiden:
  - Empfehlung: keine Notiz setzen, solange die Zelle befuellt ist
- dieselbe Notiz erneut tippen:
  - Empfehlung: toggelt die Notiz wieder aus

Ergebnis:
Normale Spielzuege und Notiz-Eingaben laufen nicht ueber denselben Schreibpfad und bleiben sauber wartbar.

### 5. Automatisches Entfernen der Notiz bei korrekter Zahl einbauen
- Beim normalen Schreiben einer Hauptzahl muss nach dem Setzen geprueft werden, ob:
  - die Zelle eine Notiz hatte
  - die neue Hauptzahl der `solutionGrid[row][col]` entspricht
- Wenn ja:
  - Notiz der Zelle entfernen

Empfehlung:
- Diese Regel direkt im normalen Zell-Schreibpfad kapseln, damit sie fuer alle Hauptzahlquellen gilt:
  - manuelle Eingabe
  - Hinweis-Flow, falls gewuenscht
  - Admin-Loesen, falls gewuenscht

Wichtige Abgrenzung:
- Laut aktueller Anforderung muss die Notiz nur bei einer richtigen Zahl automatisch verschwinden.
- Bei einer falschen Hauptzahl kann die Notiz entweder erhalten bleiben oder vorsichtshalber entfernt werden.

Empfehlung fuer das MVP:
- nur bei korrekter Zahl automatisch entfernen

Ergebnis:
Das gewuenschte Kernverhalten ist zentral und konsistent umgesetzt.

### 6. Grid-Rendering um kleine Notizen erweitern
- `SudokuGrid` braucht zusaetzliche Eingabedaten fuer Notizen, z. B.:
  - `List<List<int?>> cellNotes`
- In jeder Zelle muss unterschieden werden:
  - Hauptzahl vorhanden
  - keine Hauptzahl, aber Notiz vorhanden
  - weder Hauptzahl noch Notiz vorhanden

Empfohlene Darstellung:
- Hauptzahl bleibt wie bisher zentriert
- Notiz wird als kleiner `Text` unten links positioniert
- Technisch bietet sich innerhalb der Zelle ein `Stack` an

Gestaltungsdetails fuer das MVP:
- kleinere Schriftgroesse als Hauptzahl
- dezente Farbe, z. B. `onSurfaceVariant`
- leichter Innenabstand zur linken und unteren Zellkante

Wichtig:
- Die Darstellung muss mit bestehenden Features zusammenspielen:
  - aktive Zahlenhervorhebung
  - Hinweis-Markierung
  - Rotations-/Split-/Crazy-Mode-Effekte

Empfehlung:
- Notizen visuell einfach halten und zuerst nur im normalen Zell-Layer rendern.
- Bei Text-Rotation sollte vorab entschieden werden, ob kleine Notizen mitrotieren oder bewusst statisch bleiben.

Ergebnis:
Die kleinen Notizzahlen werden sichtbar, ohne die Hauptzahlenlogik zu ersetzen.

### 7. Undo-Verhalten fuer Notizen festlegen
- Da bereits eine Undo-Historie existiert, sollte vor der Umsetzung klar entschieden werden, ob Notiz-Aenderungen undo-faehig sein muessen.

Empfehlung:
- Ja, Notiz-Aenderungen sollten als normale Undo-Schritte behandelt werden.

Dafuer noetig:
- Undo-Modell erweitern, damit nicht nur Hauptzahlen, sondern auch Notiz-Aenderungen rueckgaengig gemacht werden koennen
- moegliche Richtung:
  - bestehendes `_GridWriteResult` erweitern
  - oder zusaetzlichen Write-Typ fuer `value` vs. `note`

Warum das wichtig ist:
- Ohne Undo-Unterstuetzung fuehlt sich der Notizmodus inkonsistent an.
- Nutzer erwarten bei einem Eingabemodus dieselbe Rueckgaengig-Qualitaet wie bei normalen Zahlen.

Ergebnis:
Notiz-Eingaben fuegen sich sauber in die bestehende Interaktionslogik ein.

### 8. Replay, Autosave und Challenge-Persistenz bewusst abgrenzen
- Aktuell werden echte Grid-Aenderungen geloggt und gespeichert.
- Fuer Notizen sollte vorab bewusst entschieden werden, ob sie:
  - nur lokal im laufenden Widget-State leben
  - im Replay auftauchen
  - in Challenge-/Resume-Daten gespeichert werden

Empfehlung fuer das MVP:
- Replay zunaechst nicht um Notiz-Events erweitern
- Challenge-Autosave zunaechst nicht fuer Notizen erweitern
- Notizen beim Neustart oder Fortsetzen einer Runde vorerst verwerfen

Wichtig:
- Diese Einschraenkung sollte spaeter dokumentiert werden, damit das Verhalten nicht wie ein Bug wirkt.

Ergebnis:
Die erste Umsetzung bleibt deutlich kleiner und beruehrt keine Datenmigration.

### 9. Randfaelle und Guard-Rules festlegen
- Tippen auf fixe Zellen:
  - keine Notiz setzen
- Tippen ohne aktive Zahl:
  - keine Notiz setzen
- Notizmodus waehrend `Hint`-Flow oder Finish-Animation:
  - Interaktionssperre wie bei normalen Eingaben beachten
- Korrekte Hauptzahl wird per Hinweis gesetzt:
  - falls in der Zielzelle eine Notiz existiert, sollte sie ebenfalls entfernt werden
- Admin-Loesen fuellt die Zelle:
  - offene Produktentscheidung, Empfehlung ebenfalls Notiz entfernen

Ergebnis:
Das Verhalten bleibt auch an den Uebergaengen zwischen Spielfeatures vorhersehbar.

### 10. Tests fuer die spaetere Umsetzung einplanen
- Unit-Tests:
  - Notiz wird nur in editierbaren Zellen gesetzt
  - neue Notiz ersetzt alte Notiz
  - gleiche Notiz kann optional toggeln
  - korrekte Hauptzahl entfernt die Notiz
- Widget-Tests:
  - `Notiz`-Button sichtbar
  - `Notiz`-Button zeigt aktiven Zustand
  - bei aktivem Notizmodus erscheint kleine Zahl unten links statt Hauptzahl
  - bei normalem Modus wird dieselbe Eingabe als Hauptzahl gesetzt
  - nach korrekter Hauptzahl verschwindet die Notiz
- Manuelle Tests:
  - Zusammenspiel mit `Loeschen`
  - Zusammenspiel mit `Hinweis`
  - Zusammenspiel mit Undo
  - Darstellung in Crazy-Mode mit Rotation/Split

Ergebnis:
Die spaetere Umsetzung ist gegen die wichtigsten Regressionen abgesichert.

## Voraussichtlich betroffene Dateien
- `docs/notiz_button.md`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/features/sudoku/presentation/widgets/sudoku_action_bar.dart`
- `lib/features/sudoku/presentation/widgets/sudoku_grid.dart`
- ggf. neu:
  - `lib/features/sudoku/domain/sudoku_input_mode.dart`
  - oder `lib/features/sudoku/domain/sudoku_cell_note.dart`
- ggf. Tests:
  - Widget-Tests fuer `SudokuActionBar`
  - Widget-/Page-Tests fuer `PlaySudokuPage`

## Akzeptanzkriterien fuer die spaetere Umsetzung
1. In der Action Bar gibt es einen weiteren Button `Notiz` mit Stift-Icon.
2. Der Button kann ein- und ausgeschaltet werden.
3. Wenn `Notiz` aktiv ist, fuehrt eine Zahleneingabe in einer editierbaren Zelle zu einer kleinen Notiz unten links statt zu einer grossen Hauptzahl.
4. Normale Hauptzahl-Eingaben funktionieren ausserhalb des Notizmodus weiterhin wie bisher.
5. Eine korrekte Hauptzahl entfernt die vorhandene Notiz dieser Zelle automatisch.
6. Fixe Sudoku-Zellen koennen nicht mit Notizen beschrieben werden.
7. Das Feature stoert bestehende Flows wie `Hinweis`, `Undo`, `Loeschen` und Finish-Check nicht.

## Empfohlene Reihenfolge fuer die spaetere Umsetzung
1. Zuerst den neuen Eingabemodus und den `Notiz`-Button einfuehren.
2. Danach die separate Notizdatenstruktur im Screen-State anlegen.
3. Anschliessend die Zell-Schreiblogik fuer Notizen und normale Zahlen trennen.
4. Danach das Grid visuell um kleine Notizen erweitern.
5. Zum Schluss Undo, Randfaelle und Tests nachziehen.

So bleibt die Umsetzung klein genug fuer sauberes Debugging und erfordert nicht sofort Eingriffe in Persistenz oder Datenbank.
