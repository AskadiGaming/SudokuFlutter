# Implementierungsplan: Goat Modifier (fliegende Ziegen)

## Ziel
Ein neuer Crazy-Mode-Modifier mit dem Namen **"Goat Modifier"** soll waehrend der Aktivzeit Ziegen quer ueber den Bildschirm fliegen lassen:

- Flugrichtung **links nach rechts** und **rechts nach links**.
- Dafuer werden zwei Assets verwendet:
  - `goat_left.png`
  - `goat_right.png`
- Jede Ziege hat eine **zufaellige Groesse** innerhalb eines definierten Bereichs.
- Der Effekt ist rein visuell und darf die Sudoku-Logik nicht veraendern.

## Ausgangslage im Code
- Modifier-Lifecycle existiert bereits in `lib/features/sudoku/presentation/play_sudoku_page.dart`.
- Es gibt schon bestehende Modifier (z. B. `shaking`, `rotation360`, ggf. `rotation90`).
- Aktiver Modifier wird im Banner oberhalb der Matrix angezeigt.
- Animationen laufen bereits ueber Controller/Timer-Strukturen.

## Architekturentscheidung fuer Goat Modifier
Der Goat Modifier wird als **Overlay-Effekt** umgesetzt:

1. Modifier aktiviert Goat-Spawn waehrend einer begrenzten Dauer.
2. Jede Ziege ist ein eigenes Animationsobjekt (Position, Richtung, Groesse, Geschwindigkeit).
3. Ziegen werden als `Image.asset(...)` ueber dem Spielbereich gerendert.
4. Nach Verlassen des sichtbaren Bereichs werden Ziegen sauber entfernt.

Wichtig: Das Overlay ist nur visuell und blockiert keine Eingaben auf dem Grid.

## Umsetzungsstrategie (in 10 Schritten)

### 1. Modifier-Typ erweitern
- Datei: `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- Neues Enum-Element:
  - `goat`

Ergebnis: Goat Modifier ist Teil des vorhandenen Systems.

### 2. Assets anlegen und registrieren
- Neue Dateien ablegen (z. B. unter `assets/images/modifiers/`):
  - `goat_left.png`
  - `goat_right.png`
- In `pubspec.yaml` sicherstellen, dass der Asset-Pfad registriert ist.

Ergebnis: Beide Ziegen-Bilder koennen zur Laufzeit geladen werden.

### 3. Lokalisierung erweitern
- In allen ARB-Dateien neuen Key anlegen:
  - `modifierGoatTitle` (z. B. "Goat Modifier")
- L10n-Regeneration ausfuehren.

Ergebnis: Banner kann den neuen Modifier lokalisiert anzeigen.

### 4. Banner-Mapping in der Spielseite ergaenzen
- Datei: `lib/features/sudoku/presentation/play_sudoku_page.dart`
- In `_buildModifierBanner(...)` neuen Fall aufnehmen:
  - `goat -> l10n.modifierGoatTitle`

Ergebnis: Aktiver Goat Modifier ist fuer den Spieler sichtbar.

### 5. Datenmodell fuer fliegende Ziegen definieren
- In `play_sudoku_page.dart` (oder ausgelagert in eigene Datei) ein internes Modell einfuehren, z. B.:
  - `id`
  - `direction` (`leftToRight` | `rightToLeft`)
  - `sizePx` (zufaellig)
  - `startY` (zufaellige vertikale Position im sichtbaren Bereich)
  - `speedPxPerSecond` (zufaellig in engem Bereich)
  - `spawnTime`

Ergebnis: Jede Ziege hat klar definierte Zustandsdaten.

### 6. Spawn-Logik waehrend aktiver Modifier-Zeit bauen
- Beim Start des Goat Modifiers einen Spawn-Timer aktivieren (z. B. alle 300-900ms zufaellig).
- Pro Spawn:
  - Richtung zufaellig waehlen.
  - Je Richtung das passende Bild waehlen (`goat_right.png` fuer links->rechts, `goat_left.png` fuer rechts->links).
  - Groesse zufaellig setzen (z. B. 36-92 px Breite, Hoehe proportional).
  - Y-Position zufaellig in einem sicheren Bereich waehlen.

Ergebnis: Kontinuierlicher, variabler Ziegenfluss waehrend des Modifiers.

### 7. Rendering als nicht-blockierendes Overlay
- Ueber dem Spielinhalt einen `Stack` verwenden.
- Ziegen in einer Overlay-Layer rendern (`Positioned` + `Image.asset`).
- Eingaben auf Sudoku duerfen nicht blockiert werden:
  - Overlay mit `IgnorePointer(ignoring: true, ...)` kapseln.

Ergebnis: Effekt ist sichtbar, Spiel bleibt normal bedienbar.

### 8. Bewegung und Cleanup implementieren
- Pro Frame/Timer X-Position anhand Geschwindigkeit aktualisieren.
- Sobald Ziege vollstaendig ausserhalb des Screens ist, Objekt entfernen.
- Beim Ende des Modifiers:
  - Spawn stoppen.
  - Bereits fliegende Ziegen optional auslaufen lassen oder direkt clearen (Produktentscheidung, siehe unten).

Ergebnis: Keine Speicherlecks, keine endlosen Listen, sauberes Lebenszyklusverhalten.

### 9. Zusammenspiel mit anderen Modifiern absichern
- Es bleibt bei "maximal ein aktiver Modifier gleichzeitig".
- Beim Wechsel von `goat` zu anderem Modifier:
  - Goat-Spawn garantiert stoppen.
  - Goat-spezifische Animationen/Timer zuruecksetzen.
- In `dispose()` alle Goat-Ressourcen sauber aufraeumen.

Ergebnis: Stabiler Betrieb ohne Seiteneffekte.

### 10. Tests und Abnahme
- Unit-/Widget-Tests:
  - `goat` wird im Banner korrekt gemappt.
  - Bei aktivem Goat Modifier erscheinen Overlay-Elemente.
  - Bei Modifier-Ende stoppt neuer Spawn.
  - Richtung/Bild-Zuordnung ist korrekt.
  - Zufallsgroessen liegen im definierten Min/Max-Bereich.
- Manueller Test:
  - Mehrere Aktivierungen in einer Session.
  - Beide Richtungen sichtbar.
  - Unterschiedliche Groessen klar erkennbar.
  - Keine Touch-Probleme auf dem Grid.

Ergebnis: Funktionalitaet und Stabilitaet sind nachweisbar.

## Technische Leitplanken
- Goat bleibt rein visuell, keine Aenderung an Sudoku-Regeln oder Board-State.
- Zufallsparameter begrenzen, damit Effekt klar, aber nicht chaotisch ist.
- Overlay darf keine Eingabeereignisse konsumieren.
- Timer/Controller immer in `dispose()` stoppen.

## Produktentscheidungen vor Umsetzung
Vor der Implementierung einmal festlegen:
- Sollen Ziegen beim Modifier-Ende sofort verschwinden oder zu Ende fliegen?
- Soll es ein Maximum gleichzeitig sichtbarer Ziegen geben (Empfehlung: ja, z. B. 6-10)?
- Soll die Spawnrate bei kleineren Displays reduziert werden?

## Geplante Dateien
- `docs/goat.md`
- `lib/features/sudoku/domain/sudoku_modifier_type.dart`
- `lib/features/sudoku/presentation/play_sudoku_page.dart`
- `pubspec.yaml`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`
- neue Assets, z. B.:
  - `assets/images/modifiers/goat_left.png`
  - `assets/images/modifiers/goat_right.png`

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Es gibt den neuen Crazy-Mode-Modifier **"Goat Modifier"**.
- Waehrend der Aktivzeit fliegen Ziegen in beide Richtungen ueber den Screen.
- Es werden korrekt zwei Bilder verwendet (`goat_left.png`, `goat_right.png`) passend zur Flugrichtung.
- Ziegen erscheinen in zufaelligen Groessen innerhalb definierter Grenzen.
- Sudoku bleibt waehrenddessen normal bedienbar.
- Beim Modifier-Wechsel und in `dispose()` bleiben keine Goat-Timer/Animationen offen.
