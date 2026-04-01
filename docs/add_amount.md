# Implementierungsplan: Werbung nur jede 10. gespielte Runde

## Ziel
Es soll nicht mehr vor jeder Runde Werbung kommen, sondern nur noch bei jeder 10. gespielten Runde.
Wichtig: Nach einem App-Neustart muss der Zaehlerstand erhalten bleiben (kein Neustart bei Runde 1).

## Ist-Zustand
- Quickmatch nutzt bereits `ShowAdBeforeRoundUseCase`.
- Die Steuerung passiert ueber `AdPolicy(minRoundsBetweenAds: ...)`.
- Der aktuelle Zaehler liegt im Use Case nur im Speicher (`_roundsSinceLastAd`) und geht bei App-Neustart verloren.

## Fachliche Entscheidung (MVP)
1. Eine Runde gilt als "gespielt", sobald der Nutzer den Start ausloest (Klick auf `Spielen` und Navigation beginnt).
2. Es wird auf Runde 10, 20, 30, ... ein Ad gezeigt.
3. Bei Ad-Fehler startet die Runde trotzdem (Fail-Open bleibt erhalten).
4. Der Rundenzaehler wird persistent gespeichert, damit das Verhalten auch nach App-Neustart korrekt bleibt.

## Umsetzungsschritte

### 1. Konfiguration auf 10 Runden umstellen
- In `QuickmatchPage` die Policy auf `minRoundsBetweenAds: 10` setzen.
- Bestehenden `timingMode: AdTimingMode.beforeRoundStart` unveraendert lassen.

Ergebnis: Innerhalb einer laufenden Session wird maximal jede 10. Runde fuer ein Ad qualifiziert.

### 2. Persistenten Rundenzaehler einfuehren
- Neuen kleinen Store einfuehren, z. B.:
  - `lib/features/ads/application/ad_round_counter_store.dart` (Interface)
  - `lib/features/ads/infrastructure/shared_prefs_ad_round_counter_store.dart` (Implementierung)
- Fester Persistenz-Key definieren, z. B. `ads.rounds_since_last_ad`.
- Methoden:
  - `Future<int> readRoundsSinceLastAd()`
  - `Future<void> writeRoundsSinceLastAd(int value)`
  - optional `Future<void> resetRoundsSinceLastAd()`
- Fallback-Regeln:
  - Wenn noch kein Wert vorhanden ist: Startwert `1` verwenden.
  - Wenn Wert ungueltig/korrupt ist: auf `1` zurueckfallen und sauber ueberschreiben.

Ergebnis: Ad-Frequenz bleibt app-uebergreifend stabil.

### 3. Use Case auf Store umstellen
- `ShowAdBeforeRoundUseCase` um den Store erweitern (Dependency Injection).
- `_roundsSinceLastAd` nicht mehr nur im Speicher halten, sondern:
  - bei `execute()` initial aus Store laden (lazy load/cached)
  - nach jedem Skip/Fail inkrementiert speichern
  - nach `shown` auf `0` setzen und speichern
- `lastAdShownAt` kann vorerst im Speicher bleiben, wenn kein Cooldown genutzt wird; bei spaeterem Cooldown ebenfalls persistieren.

Ergebnis: Die 10er-Logik ist robust gegen App-Neustarts.

### 4. Initialisierung/Composition anpassen
- In `QuickmatchPage` oder zentralem Composition-Root den neuen Store instanziieren und an `ShowAdBeforeRoundUseCase` uebergeben.
- SharedPreferences sauber initialisieren (falls noch nicht vorhanden).

Ergebnis: Alle Abhaengigkeiten sind sauber verdrahtet.

### 5. Telemetrie erweitern
- Bestehende Events um Zaehlerwerte ergaenzen:
  - `rounds_since_last_ad_before`
  - `rounds_since_last_ad_after`
  - `target_interval = 10`
- Damit kann spaeter validiert werden, ob wirklich nur jede 10. Runde Werbung zeigt.

Ergebnis: Verhalten ist in Logs nachvollziehbar.

### 6. Tests
- Unit-Tests fuer `AdPolicy`:
  - `minRoundsBetweenAds=10` zeigt erst ab Runde 10.
- Unit-Tests fuer Use Case + Fake Store:
  - Runden 1-9 => `skipped`, Zaehler steigt.
  - Runde 10 => versucht Ad-Show.
  - Bei `shown` -> Zaehler reset auf 0.
  - Bei `failed/skipped` vom Ad-Service -> Zaehler inkrementiert.
- Persistenz-Test (wichtig fuer Neustart):
  - Runde 1-9 spielen, App beenden, App neu starten, Runde 10 starten => Ad wird weiterhin auf Runde 10 versucht.
- Optional Widget-Test Quickmatch:
  - Klick auf `Spielen` triggert Use Case weiterhin und blockiert Navigation nicht dauerhaft.

Ergebnis: Kernlogik ist regressionssicher.

## Betroffene Dateien (geplant)
- `docs/add_amount.md` (neu)
- `lib/features/quickmatch/presentation/quickmatch_page.dart`
- `lib/features/ads/application/show_ad_before_round_use_case.dart`
- `lib/features/ads/application/ad_round_counter_store.dart` (neu)
- `lib/features/ads/infrastructure/shared_prefs_ad_round_counter_store.dart` (neu)
- ggf. `pubspec.yaml` (nur falls `shared_preferences` noch fehlt)
- `test/...` (Policy- und Use-Case-Tests)

## Akzeptanzkriterien
1. In den ersten 9 gestarteten Runden wird kein Ad angezeigt.
2. Bei der 10. gestarteten Runde wird ein Interstitial versucht anzuzeigen.
3. Danach wiederholt sich das Muster bei Runde 20, 30, ...
4. App-Neustart setzt den Zaehler nicht ungewollt zurueck.
5. Wenn ein Ad fehlschlaegt oder nicht verfuegbar ist, startet die Runde trotzdem.
6. Der gespeicherte Zaehler wird beim App-Start gelesen und vor der Policy-Pruefung verwendet.

## Risiken und Entscheidungen
- Wenn "gespielte Runde" fachlich stattdessen "erfolgreich abgeschlossene Runde" bedeutet, muss die Inkrement-Logik vom Start-Flow in den Round-End-Flow verschoben werden.
- Falls spaeter weitere Modi (nicht nur Quickmatch) mitzaehlen sollen, den Zaehler in einen globalen Game-Start-Hook verlagern.
