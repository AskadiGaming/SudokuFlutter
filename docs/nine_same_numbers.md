# Implementierungsplan: Zahlenbutton ausblenden, wenn Zahl 9x gesetzt ist

## Ziel
In der Sudoku-Ansicht soll ein Zahlenbutton automatisch ausgeblendet werden, sobald die zugehoerige Zahl insgesamt 9-mal im aktuellen Grid vorhanden ist.

Wichtig:
- Die Position der anderen Buttons darf sich dabei nicht verschieben.
- An der bisherigen Stelle des ausgeblendeten Buttons soll eine sichtbare Luecke bleiben.
- Wird spaeter wieder eine Zelle geloescht und die Zahl kommt nur noch 8-mal vor, muss der Button automatisch wieder erscheinen.

Beispiel:
- Wenn die `4` im aktuellen Sudoku 9-mal vorkommt, wird der Button `4` verborgen.
- Wenn danach eine `4` entfernt wird, wird der Button `4` wieder sichtbar.

## Ausgangslage
- Die Zahlenleiste wird aktuell in `lib/features/sudoku/presentation/widgets/number_pad.dart` ueber `ToggleButtons` aufgebaut.
- Die Eingaben laufen ueber `PlaySudokuPage` in `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Der aktuelle Spielstand liegt in `SudokuGridData.currentGrid`.
- Es gibt aktuell 10 Slots in der Leiste:
- Zahlen `1` bis `9`
- Loeschen/Backspace als letzter Slot

## Umsetzungsstrategie
Wir teilen die spaetere Umsetzung in 5 Schritte:
1. Regel fuer Sichtbarkeit fachlich definieren
2. Zaehllogik auf Basis des aktuellen Grids einfuehren
3. Number-Pad so umbauen, dass Slots stabil bleiben
4. Wechselwirkungen mit aktiver Auswahl absichern
5. Tests fuer Ausblenden, Luecken und Wiedereinblenden ergaenzen

## Schritt-fuer-Schritt-Plan

### 1. Fachliche Regel eindeutig festziehen
- Grundlage ist ausschliesslich `currentGrid`, also der aktuelle sichtbare Spielstand.
- Es wird ueber alle Zellen gezaehlt:
- vorgegebene Zahlen (`isFixed`)
- vom Nutzer eingetragene Zahlen
- Eine Zahl `n` ist verborgen, wenn sie im `currentGrid` genau 9-mal vorkommt.
- Eine Zahl `n` ist sichtbar, wenn sie 0 bis 8-mal vorkommt.
- Der Loeschen-Button bleibt von dieser Regel unberuehrt und immer sichtbar.

Ergebnis:
Eine klare, deterministische Regel ohne Sonderfaelle in der UI.

### 2. Zaehllogik zentral aus dem Grid ableiten
- In `PlaySudokuPage` oder in einer kleinen Hilfsfunktion im Sudoku-Feature eine Auswertung einfuehren, z. B.:
- `Map<int, int> countDigitsInGrid(List<List<int>> grid)`
- oder `Set<int> fullyUsedDigits(List<List<int>> grid)`
- Die Berechnung sollte immer aus dem aktuellen Grid abgeleitet werden und keinen separaten, manuell gepflegten Zustand verwenden.
- Dadurch reagieren Eintragen, Ueberschreiben per Hinweis und Loeschen automatisch korrekt.
- Die Sichtbarkeit der Buttons wird bei jedem `setState`, das das Grid aendert, neu aus dem Grid gelesen.

Ergebnis:
Kein Risiko fuer inkonsistente Counter-Staende, weil die Information immer aus der Quelle der Wahrheit kommt.

### 3. Number-Pad fuer feste Positionen mit Luecken umbauen
- `ToggleButtons` ist fuer dieses Verhalten wahrscheinlich unguenstig, weil die Komponente auf eine vollstaendige, zusammenhaengende Button-Liste ausgelegt ist.
- Fuer die spaetere Umsetzung ist daher ein Umbau auf eine eigene horizontale Slot-Leiste sinnvoll, z. B. mit:
- `Row`
- `SingleChildScrollView`
- oder `Wrap`, falls die feste Reihenfolge sauber erhalten bleibt
- Jeder der 10 Slots behaelt seine feste Breite:
- Slot 1 bis 9 fuer die Zahlen
- Slot 10 fuer Loeschen
- Wenn eine Zahl verborgen ist, wird nicht der ganze Slot entfernt, sondern nur dessen Inhalt ausgeblendet, z. B. ueber:
- `SizedBox` mit derselben Breite und Hoehe
- optional `Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true)`
- Dadurch bleibt die Position aller anderen Slots unveraendert und die gewuenschte Luecke entsteht.

Ergebnis:
Das Layout bleibt stabil, auch wenn einzelne Zahlen nicht anklickbar sind.

### 4. Aktive Auswahl und Rueckkehr des Buttons absichern
- Wenn ein Button ausgeblendet wird, waehrend diese Zahl gerade aktiv ausgewaehlt ist, muss die Auswahl sauber behandelt werden.
- Empfehlte Regel fuer die Umsetzung:
- Die aktive Zahl darf auf eine unsichtbare Zahl nicht stehen bleiben.
- In diesem Fall auf eine sichere Standardzahl zurueckfallen, z. B. die erste noch sichtbare Zahl von `1` bis `9`.
- Falls ausnahmsweise alle Zahlen `1` bis `9` verborgen waeren, sollte mindestens der Loeschen-Button weiter funktionieren.
- Sobald eine Zahl durch Loeschen wieder unter 9 Vorkommen faellt, erscheint ihr Button automatisch erneut am alten Slot.
- Die Wiedereinblendung darf keine Sonderbehandlung pro Zelle brauchen; sie soll allein aus der erneuten Grid-Auswertung folgen.

Ergebnis:
Keine tote Auswahl und keine zusaetzliche manuelle Synchronisationslogik.

### 5. Tests fuer Verhalten und Layoutschutz ergaenzen
- Unit-Tests fuer die Zaehllogik:
- Zahl kommt 9-mal vor => Zahl gilt als verborgen
- Zahl kommt 8-mal vor => Zahl gilt als sichtbar
- `0` wird nie als normale Zahl behandelt
- Widget-Tests fuer `SudokuNumberPad`:
- verborgener Zahlenbutton rendert keinen klickbaren Inhalt
- Slot-Breite bleibt erhalten
- Nachbar-Buttons behalten ihre Position
- Loeschen-Button bleibt sichtbar
- Widget- oder Page-Tests fuer `PlaySudokuPage`:
- nach Eingabe der 9. gleichen Zahl wird der passende Button ausgeblendet
- nach Loeschen derselben Zahl wird der Button wieder eingeblendet
- aktive Auswahl springt auf eine sichtbare Zahl zurueck, falls noetig

Ergebnis:
Die Fachlogik und das stabile Layout sind gegen Regressionen abgesichert.

## Betroffene Dateien
- `lib/features/sudoku/presentation/widgets/number_pad.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- optional neu: kleine Hilfsdatei fuer Zahlzaehlung im Sudoku-Feature
- `test/` fuer Unit- und Widget-Tests
- `docs/nine_same_numbers.md`

## Technische Hinweise fuer die spaetere Umsetzung
- Die Sichtbarkeit sollte nicht auf Basis der Anfangsbelegung (`initialGrid`) bestimmt werden, sondern immer auf Basis von `currentGrid`.
- Die Regel muss auch mit bestehenden Zusatzfunktionen wie `Hinweis` und Admin-Loesen konsistent bleiben, weil diese ebenfalls `currentGrid` veraendern.
- Falls `ToggleButtons` beibehalten werden soll, muss vorab geprueft werden, ob ausgeblendete Kinder dort wirklich ohne Layout-Verschiebung und ohne Selection-Probleme moeglich sind.
- Wahrscheinlicher ist, dass eine eigene Slot-Implementierung langfristig robuster und leichter testbar ist.

## Akzeptanzkriterien
Das Feature gilt spaeter als korrekt umgesetzt, wenn:
- Eine Zahl von `1` bis `9` bei genau 9 Vorkommen im aktuellen Grid nicht mehr als klickbarer Button sichtbar ist.
- Die restlichen Buttons ihre bisherigen Positionen behalten.
- An der Stelle des verborgenen Buttons eine Luecke bleibt.
- Wird dieselbe Zahl wieder auf 8 oder weniger Vorkommen reduziert, erscheint der Button wieder an exakt derselben Position.
- Der Loeschen-Button bleibt sichtbar und benutzbar.
- Die Logik funktioniert gleichermassen fuer Startzahlen, manuelle Eingaben und spaetere Zell-Loeschungen.
