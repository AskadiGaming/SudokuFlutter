# Implementierungsplan: Unity Ads vor dem Start einer Runde

## Ziel
Vor jedem Start einer Quickmatch-Runde soll ein Unity Interstitial Ad angezeigt werden.  
Danach startet die Runde wie gewohnt. Wenn kein Ad verfuegbar ist oder ein Fehler auftritt, soll die Runde trotzdem starten (Fail-Open).

## Ausgangslage
- Der Spielstart passiert aktuell in `QuickmatchPage` (`lib/main.dart`) direkt beim Klick auf `quickmatchPlay`.
- Eine Ads-Feature-Struktur ist vorhanden (`lib/features/ads/{domain,application,infrastructure}`), aber noch ohne Implementierung.
- Es gibt bereits eine Trennung in Domain/Application/Infrastructure, die wir fuer eine saubere Integration nutzen.

## Grundprinzip fuer den Flow
1. User klickt auf `Spielen`.
2. App fragt die Ads-Policy, ob ein Ad vor diesem Start gezeigt werden soll.
3. Wenn ja: Interstitial laden/anzeigen und auf Abschluss warten.
4. Unabhaengig vom Ad-Ergebnis (gesehen, fehlgeschlagen, kein Fill) startet danach die Runde.

## Umsetzungsstrategie (in 7 Schritten)

### 1. Abhaengigkeiten und Plattform-Setup
- `pubspec.yaml`: Unity Ads Flutter Plugin hinzufuegen.
- Android:
  - Unity Game ID und Placement IDs fuer `debug`/`release` hinterlegen.
  - Netzwerk/Manifest-Anforderungen des SDK pruefen.
- iOS:
  - Game ID/Placement IDs hinterlegen.
  - Info.plist-Eintraege laut Unity SDK.
- Build pruefen auf Android und iOS.

Ergebnis: SDK ist technisch eingebunden und initialisierbar.

### 2. Domain-Modelle fuer Ad-Regeln definieren
- `lib/features/ads/domain/ad_timing_mode.dart`
  - z. B. `beforeRoundStart`, `off`.
- `lib/features/ads/domain/ad_policy.dart`
  - Regeln wie Cooldown, max. Frequenz, ggf. nur ab bestimmter Spielanzahl.
- Policy bewusst UI-unabhaengig halten.

Ergebnis: Es gibt eine zentrale, testbare Regelbasis, wann Ads gezeigt werden.

### 3. Application-Layer fuer Orchestrierung bauen
- `lib/features/ads/application/analytics_service.dart` als Interface finalisieren.
- Neuer Use Case, z. B. `ShowAdBeforeRoundUseCase`:
  - prueft Policy
  - triggert Ad-Show im Infrastructure-Layer
  - loggt Events (requested, shown, failed, skipped)
  - liefert ein einfaches Ergebnisobjekt zurueck (`shown/skipped/failed`)

Ergebnis: Der UI-Flow bekommt genau einen Einstiegspunkt fuer "Ad vor Spielstart".

### 4. Infrastructure fuer Unity Ads implementieren
- Neue Klasse, z. B. `unity_ads_service.dart`:
  - `initialize()`
  - `isAdReady()`
  - `showInterstitialAndWait()`
- Event-Callbacks robust behandeln:
  - success/completed
  - failed/no fill/timeout
- Timeout-Absicherung einbauen, damit der Spielstart nie blockiert.
- `debug_analytics_service.dart` fuer Logging in Dev weiterverwenden.

Ergebnis: Technische Unity-Integration ist gekapselt und austauschbar.

### 5. Integration in den Quickmatch-Startflow
- In `QuickmatchPage` den direkten `Navigator.push(...)` ersetzen durch:
  - `await showAdBeforeRoundUseCase.execute()`
  - danach immer Navigation zur `PlaySudokuPage`
- Optional: waehrenddessen kurzer Loading-Zustand auf dem Play-Button, um Doppelklicks zu vermeiden.

Ergebnis: Vor jeder Runde wird der Ad-Flow sauber durchlaufen, ohne den Start zu verlieren.

### 6. Konfiguration, Environment und Sicherheit
- IDs fuer `debug` und `release` trennen (kein Hardcoding in Widgets).
- Umschalter fuer Testmodus vorsehen.
- Fallback fuer nicht unterstuetzte Plattformen (Web/Desktop): immer `skipped`.
- Dokumentieren, wo IDs gepflegt werden.

Ergebnis: Betrieb ist stabil, nachvollziehbar und release-faehig.

### 7. Tests und Abnahme
- Unit-Tests:
  - Policy-Entscheidungen (`show` vs `skip`)
  - Use-Case-Verhalten bei Erfolg/Fehler/Timeout
- Widget-/Integrationstest:
  - Klick auf `Spielen` fuehrt auch bei Ad-Fehler zur Navigation.
- Manuelle Tests:
  - Android Debug (Test-Ad wird gezeigt)
  - iOS Debug (Test-Ad wird gezeigt)
  - Offline/No-Fill-Fall startet trotzdem Runde

Ergebnis: Das Verhalten ist abgesichert und regressionsarm.

## Geplante Dateien
- `docs/adds.md`
- `pubspec.yaml`
- `lib/main.dart`
- `lib/features/ads/domain/ad_timing_mode.dart`
- `lib/features/ads/domain/ad_policy.dart`
- `lib/features/ads/application/analytics_service.dart`
- `lib/features/ads/application/show_ad_before_round_use_case.dart` (neu)
- `lib/features/ads/infrastructure/debug_analytics_service.dart`
- `lib/features/ads/infrastructure/unity_ads_service.dart` (neu)
- ggf. plattformspezifisch:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`

## Akzeptanzkriterien
Das Ziel gilt als erreicht, wenn:
- Beim Klick auf `Spielen` in Quickmatch wird zuerst der Ad-Flow gestartet.
- Wenn ein Interstitial verfuegbar ist, wird es vor dem Rundenstart angezeigt.
- Nach Ad-Ende startet die Runde automatisch.
- Wenn Ad nicht verfuegbar ist oder fehlschlaegt, startet die Runde trotzdem.
- Verhalten ist auf Android/iOS getestet, und auf nicht mobilen Plattformen blockiert nichts.

## Optionaler Ausbau nach MVP
- Frequenzsteuerung (z. B. nur jede 2. oder 3. Runde).
- Segmentierung nach Schwierigkeit oder Sessiondauer.
- Erweiterte Analytics (Impression-Rate, Fill-Rate, Start-Abbruchquote vor/nach Ad).

## Ist-Stand im Code (umgesetzt)
- Quickmatch startet nun ueber `ShowAdBeforeRoundUseCase` und navigiert danach immer in die Runde (Fail-Open).
- Ads-Logik ist getrennt in Domain/Application/Infrastructure unter `lib/features/ads/`.
- Nicht-mobile Plattformen (Web/Desktop) werden automatisch als `skipped` behandelt.
- Android-Netzwerk-Permissions sind gesetzt (`INTERNET`, `ACCESS_NETWORK_STATE`).

## Dart-Defines fuer Unity Ads
Die IDs werden zur Laufzeit per `--dart-define` injiziert. Genutzte Schluessel:

- `UNITY_ADS_ANDROID_GAME_ID_DEBUG`
- `UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG`
- `UNITY_ADS_ANDROID_GAME_ID_RELEASE`
- `UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE`
- `UNITY_ADS_IOS_GAME_ID_DEBUG`
- `UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG`
- `UNITY_ADS_IOS_GAME_ID_RELEASE`
- `UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE`
- `UNITY_ADS_TEST_MODE` (`true` oder `false`)

## Windows PowerShell Beispiel (Session-Variablen setzen)
```powershell
$env:UNITY_ADS_ANDROID_GAME_ID_DEBUG="DEINE_ANDROID_GAME_ID_DEBUG"
$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG="DEIN_ANDROID_INTERSTITIAL_DEBUG"
$env:UNITY_ADS_ANDROID_GAME_ID_RELEASE="DEINE_ANDROID_GAME_ID_RELEASE"
$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE="DEIN_ANDROID_INTERSTITIAL_RELEASE"

$env:UNITY_ADS_IOS_GAME_ID_DEBUG="DEINE_IOS_GAME_ID_DEBUG"
$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG="DEIN_IOS_INTERSTITIAL_DEBUG"
$env:UNITY_ADS_IOS_GAME_ID_RELEASE="DEINE_IOS_GAME_ID_RELEASE"
$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE="DEIN_IOS_INTERSTITIAL_RELEASE"
```

## Manuelle Flutter-Befehle
Android Debug mit Test-Ads:
```powershell
flutter run -d android --dart-define=UNITY_ADS_TEST_MODE=true `
  --dart-define=UNITY_ADS_ANDROID_GAME_ID_DEBUG=$env:UNITY_ADS_ANDROID_GAME_ID_DEBUG `
  --dart-define=UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG=$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG `
  --dart-define=UNITY_ADS_IOS_GAME_ID_DEBUG=$env:UNITY_ADS_IOS_GAME_ID_DEBUG `
  --dart-define=UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG=$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG
```

iOS Debug mit Test-Ads:
```powershell
flutter run -d ios --dart-define=UNITY_ADS_TEST_MODE=true `
  --dart-define=UNITY_ADS_ANDROID_GAME_ID_DEBUG=$env:UNITY_ADS_ANDROID_GAME_ID_DEBUG `
  --dart-define=UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG=$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG `
  --dart-define=UNITY_ADS_IOS_GAME_ID_DEBUG=$env:UNITY_ADS_IOS_GAME_ID_DEBUG `
  --dart-define=UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG=$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG
```

Android Release:
```powershell
flutter run -d android --release --dart-define=UNITY_ADS_TEST_MODE=false `
  --dart-define=UNITY_ADS_ANDROID_GAME_ID_RELEASE=$env:UNITY_ADS_ANDROID_GAME_ID_RELEASE `
  --dart-define=UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE=$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE `
  --dart-define=UNITY_ADS_IOS_GAME_ID_RELEASE=$env:UNITY_ADS_IOS_GAME_ID_RELEASE `
  --dart-define=UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE=$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE
```

iOS Release:
```powershell
flutter run -d ios --release --dart-define=UNITY_ADS_TEST_MODE=false `
  --dart-define=UNITY_ADS_ANDROID_GAME_ID_RELEASE=$env:UNITY_ADS_ANDROID_GAME_ID_RELEASE `
  --dart-define=UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE=$env:UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE `
  --dart-define=UNITY_ADS_IOS_GAME_ID_RELEASE=$env:UNITY_ADS_IOS_GAME_ID_RELEASE `
  --dart-define=UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE=$env:UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE
```

## VS Code Startkonfiguration
Es wurde `.vscode/launch.json` angelegt mit:
- `Flutter Android Debug (Unity Ads)`
- `Flutter iOS Debug (Unity Ads)`
- `Flutter Android Release (Unity Ads)`
- `Flutter iOS Release (Unity Ads)`

Die Konfigurationen lesen IDs aus Environment-Variablen (`${env:...}`).

## Build-Script fuer Production
Es gibt jetzt ein Script:

- `scripts/build_release.ps1`

Das Script:
- validiert die benoetigten Release-Environment-Variablen
- fuehrt optional `flutter pub get` aus
- baut Android als `appbundle` (optional zusaetzlich APK)
- baut iOS als `ipa` (nur auf macOS, sonst wird iOS sauber uebersprungen)

### Aufruf
Alles bauen (Android + iOS, falls macOS):
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Platform all
```

Nur Android:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Platform android
```

Android zusaetzlich als APK:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Platform android -BuildApk
```

Ohne `flutter pub get`:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Platform android -SkipPubGet
```
