# Implementierungsplan: 90° Modifier (viertelweise rotierende Sudoku-Matrix)

## Ziel
Ein neuer Crazy-Mode-Modifier mit dem Namen **"90° Modifier"** soll die Sudoku-Matrix langsam um genau **90 Grad** drehen.

Pflichtanforderungen:
- Die Runde bleibt waehrend der Animation normal spielbar (Zellen antippen, Zahlen setzen/loeschen).
- Nach Abschluss der 90°-Drehung bleibt das Board in der neuen Ausrichtung bestehen.
- Die Zahlen muessen nach der Drehung korrekt mitgedreht sein, sodass das gedrehte Board konsistent und lesbar bleibt.
- Der Modifier darf mehrfach auftreten und muss auch nach 2x/3x/4x Anwendung stabil funktionieren.

## Ausgangslage im Code
- Modifier-Lifecycle existiert bereits in `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Vorhandene Modifier: `shaking`, `rotation360`.
- Der aktive Modifier wird oberhalb der Matrix im Banner angezeigt.
- Es existiert bereits eine Rotationsanimation ueber `AnimationController`.

## Architekturentscheidung fuer 90°
Der 90° Modifier braucht zusaetzlich zur reinen Animation eine **persistente Board-Rotation**:

1. **Visuelle Rotation (waehrend der Animation)**
- Die Matrix rotiert langsam von 0 auf 90 Grad.

2. **Strukturelle Rotation (am Ende der Animation)**
- `currentGrid` und `isFixed` werden als 9x9-Matrix um 90 Grad rotiert, damit Logik und Anzeige wieder deckungsgleich sind.
- Danach wird die visuelle Zusatzrotation auf 0 zurueckgesetzt.

3. **Akkumulierte Orientierung fuer Mehrfachanwendung**
- Interner Zustand `quarterTurns` (0..3) verwaltet die Gesamtrotation ueber mehrere Aktivierungen.
- Nach jeder abgeschlossenen 90°-Drehung: `quarterTurns = (quarterTurns + 1) % 4`.

## Umsetzungsstrategie (in 10 Schritten)

### 1. Modifier-Typ erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Neues Enum-Element einfuegen:
  - `rotation90`

Ergebnis: Der neue Modifier ist Teil des bestehenden Systems.

### 2. Lokalisierung erweitern
- In allen ARB-Dateien neuen Key anlegen:
  - `modifier90Title` (z. B. "90° Modifier")
- L10n-Regeneration durchfuehren.

Ergebnis: Banner zeigt den neuen Modifier lokalisiert an.

### 3. Banner-Mapping ergaenzen
- Datei: `lib/features/sudoku/presentation/play_sudoku_page.dart`
- In `_buildModifierBanner(...)` neuen Fall aufnehmen:
  - `rotation90 -> l10n.modifier90Title`

Ergebnis: Aktiver 90° Modifier ist sichtbar.

### 4. Zustandsfelder fuer persistente Rotation einfuehren
- In `_PlaySudokuPageState` ergaenzen:
  - `int _quarterTurns = 0;` (akkumulierte Endausrichtung)
  - `AnimationController _rotation90Controller` (0..1 fuer 0..pi/2)
  - optional `bool _isApplying90Commit = false` als Guard gegen Doppel-Commit.

Ergebnis: Dauerhafte Ausrichtung und laufende Animation sind getrennt modelliert.

### 5. Modifier-Auswahl im Lifecycle erweitern
- In `_activateRandomModifier()` `rotation90` in die Kandidatenliste aufnehmen.
- Dauer fuer `rotation90` auf einen festen, gut spielbaren Bereich setzen (Empfehlung: 6-9 Sekunden).

Ergebnis: 90° Modifier kann zufaellig erscheinen.

### 6. 90°-Animation starten und waehrenddessen spielbar bleiben
- Beim Start von `rotation90`:
  - Controller auf 0 setzen, bis 1 animieren (Curves.linear oder leicht eased).
  - Grid in `Transform.rotate` mit Winkel `controller.value * (pi / 2)` rendern.
  - `transformHitTests: true` aktiv lassen, damit Touch auf transformierter Matrix funktioniert.

Ergebnis: Langsame Vierteldrehung bei durchgaengiger Interaktion.

### 7. Datenrotation am Animationsende committen
- Beim Abschluss der 90°-Animation exakt einmal:
  - `currentGrid` um 90 Grad drehen.
  - `isFixed` um 90 Grad drehen.
  - Falls vorhanden: weitere positionsgebundene Strukturen ebenfalls drehen (z. B. Notizen, Highlights, Konfliktmarker).
- Danach:
  - `_quarterTurns` inkrementieren.
  - 90°-Controller auf 0 resetten.

Empfohlene Rotationsformel (clockwise):
- `rotated[newRow][newCol] = source[8 - newCol][newRow]`

Ergebnis: Board-Zustand passt zur neuen Ausrichtung und bleibt konsistent.

### 8. Zahlen-Lesbarkeit und Darstellungsregel festlegen
- Um Lesbarkeit sicherzustellen, Zahlen-Glyphen in jeder Endlage aufrecht rendern.
- Dafuer Zellinhalt (Text) relativ zur Board-Rotation gegenrotieren, falls noetig.

Pragmatische Regel:
- Positionen der Zahlen rotieren immer mit dem Board (Pflicht).
- Glyphen bleiben fuer den Spieler lesbar (kein dauerhaft seitlicher Text).

Ergebnis: Anforderung "Zahlen sind am Ende korrekt gedreht" plus gute Lesbarkeit wird gleichzeitig erfuellt.

### 9. Zusammenspiel mit bestehenden Modifiern absichern
- `shaking` und `rotation360` duerfen keine persistenten Rotationsdaten ueberschreiben.
- Beim Wechsel zwischen Modifiern visuelle Effekte strikt stoppen/resetten, ohne `quarterTurns` zu verlieren.
- Reihenfolgebeispiel testen: `rotation90 -> shaking -> rotation90 -> rotation360`.

Ergebnis: Modifier bleiben kombinierbar ohne Seiteneffekte.

### 10. Tests und Abnahme
- Unit-Tests fuer Matrixrotation:
  - 1x 90 Grad, 2x 90 Grad, 3x 90 Grad, 4x 90 Grad (4x == Ursprungszustand).
- Widget-Tests:
  - Banner zeigt `modifier90Title`.
  - Eingabe waehrend laufender 90°-Animation funktioniert.
  - Nach Animationsende sind Zellwerte an den erwarteten rotierten Positionen.
- Manueller Test (mind. 5 Minuten Crazy Mode):
  - Mehrfaches Auftreten des 90° Modifiers.
  - Keine Inkonsistenz bei Touch, Highlighting, Number-Buttons.

Ergebnis: Stabilitaet bei Wiederholung und Modifier-Kombinationen ist nachgewiesen.

## Technische Leitplanken
- Weiterhin maximal ein aktiver Modifier gleichzeitig.
- Persistente Logik-Aenderung erst am Ende der Animation committen.
- Commit-Operation muss idempotent gegen doppelte Listener-Aufrufe abgesichert sein.
- Alle Timer/Controller in `dispose()` sauber aufraeumen.

## Geplante Dateien
- `docs/90_modifier.md`
- `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`
- optional Tests: `test/` fuer Rotations- und Widget-Faelle

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Es gibt den neuen Crazy-Mode-Modifier **"90° Modifier"**.
- Die Sudoku-Matrix dreht bei Aktivierung langsam und genau um 90 Grad.
- Das Spiel bleibt waehrend der Drehung normal bedienbar.
- Nach Abschluss sind Werte/Positionen korrekt rotiert und weiterhin lesbar.
- Mehrfache Aktivierung funktioniert robust (insb. 4x Anwendung ergibt wieder Ausgangslage).
