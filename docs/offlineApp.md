# Implementierungsplan: Vollstaendige Offline-App

## Zielbild
Die App soll nach dem Umbau keinerlei Internetverbindung mehr benoetigen.
Alle Funktionen muessen lokal auf dem Geraet laufen.
Es gibt keine Anmeldung, keine Registrierung, kein Gastkonto und keine externe API mehr.
Beim Klick auf das Profil-Icon soll direkt die normale Profilseite erscheinen.
Der Standardname soll `SudokuPlayer` sein.
Ausnahme: Unity Ads duerfen bestehen bleiben, auch wenn diese fuer ihre Funktion eine Online-Verbindung benoetigen.

## Aktueller Stand
- Das Profil ist bereits lokal angelegt, verwendet aber noch eine Auth-/Session-Struktur mit `AuthController`, `AuthRepository`, `LocalAuthRepository` und `UserSession`.
- Der aktuelle Fallback-Name ist `SudokuPlayer#123123` und muss auf `SudokuPlayer` umgestellt werden.
- In der Profilseite gibt es noch Logik fuer Session-, Fehler- und Fotoanzeige.
- Auch das globale Profil-Icon verwendet noch Foto-Logik ueber externe URLs.
- Unter dem Usernamen steht aktuell noch ein statischer Text statt einer Bearbeiten-Funktion.
- In `lib/features/ads/` und `lib/features/quickmatch/` existiert noch Anbindung an Unity Ads.
- `pubspec.yaml` enthaelt mit `unity_ads_plugin` weiterhin eine bewusst beibehaltene Online-Abhaengigkeit.

## Architektur-Ziel nach dem Umbau
- Profil wird zu einem rein lokalen UI-/State-Feature ohne Auth-Begrifflichkeiten.
- Es gibt genau ein lokales Standardprofil.
- Externe Dienste werden vollstaendig entfernt statt nur deaktiviert, sofern sie nicht ausdruecklich als Ausnahme definiert sind.
- Persistenz bleibt nur dort bestehen, wo sie fuer echte Offline-Funktionen sinnvoll ist, z. B. lokale Einstellungen oder lokale Spielstaende.
- Unity Ads bleiben als explizite Ausnahme erhalten.
- Der Username ist lokal bearbeitbar.

## Umsetzungsphasen

### 1. Online-Abhaengigkeiten inventarisieren und abgrenzen
- Alle direkten und indirekten Online-Pfade erfassen.
- Fokusbereiche:
  - Profil/Auth
  - moegliche API-Clients oder HTTP-Zugriffe
  - externe Konfiguration ueber `--dart-define`
  - Abgrenzung zwischen zu entfernenden Online-Funktionen und erlaubter Unity-Ads-Ausnahme
- Ergebnis dieser Phase:
  - Liste der Dateien, die entfernt, vereinfacht oder ersetzt werden.
  - Entscheidung, welche Features komplett entfallen.

### 2. Profil-Konzept auf reines Offline-Profil umstellen
- Authentifizierung fachlich komplett streichen.
- Das Profil nicht mehr als Session modellieren, sondern als einfaches lokales Profil.
- Zielzustand:
  - kein `isAuthenticated`
  - kein `userId`
  - kein Gaststatus
  - kein Unterschied zwischen Gast und normalem Profil
- Standardname auf `SudokuPlayer` setzen.
- Username lokal editierbar machen.

### 3. Profil-Architektur vereinfachen
- `AuthController` entfernen.
- `AuthRepository` entfernen.
- `LocalAuthRepository` entfernen oder in deutlich einfachere lokale Profil-Persistenz ueberfuehren, falls spaeter weitere Profildaten lokal gespeichert werden sollen.
- `UserSession` entfernen.
- `ProfileController` so umbauen, dass er ohne Session-Synchronisierung arbeitet.
- `ProfileState` auf das wirklich noetige Minimum reduzieren.
- Falls der Username editierbar wird, eine einfache lokale Profil-Persistenz fuer den Namen vorsehen.

### 4. Profil-UI bereinigen
- Profilseite so umbauen, dass nur noch das normale lokale Profil gezeigt wird.
- Entfernen:
  - Hinweise auf Session oder Laden einer Session
  - Fehlermeldungen rund um Session-Restore
  - Anzeige/Logik fuer externes Profilfoto per `NetworkImage` in Profilseite und Avatar-Button
- Beibehalten:
  - direkter Einstieg ueber das Profil-Icon
  - Anzeige des aktuellen lokalen Usernamens
- Textlich angleichen:
  - keine Begriffe wie `Gast`, `Anmeldung`, `Registrierung`, `Login` oder `Session`
- UI-Anpassung unter dem Usernamen:
  - Text `Lokales Profil` entfernen
  - kleines Stift-Icon anzeigen
  - daneben oder darunter kleinen Text `bearbeiten` anzeigen
  - Klick oeffnet eine lokale Bearbeiten-Funktion fuer den Usernamen

### 5. Globale App-Initialisierung entkoppeln
- `lib/app/app.dart` von der Profil-Initialisierung mit Auth loesen.
- App-Start vereinfachen:
  - keine Auth-Initialisierung
  - kein Warten auf Session-Restore
  - Profil direkt lokal bereitstellen
- `ProfileScope` pruefen:
  - falls nur noch ein `ProfileController` gebraucht wird, Scope entsprechend vereinfachen
  - falls der Scope keinen Mehrwert mehr hat, durch direktere Bereitstellung ersetzen

### 6. Unity Ads als definierte Online-Ausnahme absichern
- Unity Ads bleiben im Projekt und werden nicht entfernt.
- Dokumentieren, dass Unity Ads die einzige bewusst akzeptierte Online-Ausnahme in der App sind.
- Pruefen, dass andere Features funktional nicht von Netzwerk oder externen Diensten abhaengen.
- Sicherstellen, dass ein Ausfall oder fehlende Verbindung fuer Ads nicht Profil, Navigation oder Spielfluss blockiert.
- Bestehende Integration pruefen:
  - `lib/features/ads/`
  - Unity-Ads-Integration in `lib/features/quickmatch/`
  - `unity_ads_plugin` in `pubspec.yaml`
- Dokumentation aktualisieren, damit Unity Ads nicht versehentlich in spaeteren Offline-Schritten entfernt werden.

### 7. Externe API- und Netzwerk-Begriffe systematisch entfernen
- Codebasis gezielt durchsuchen nach:
  - `http`
  - `dio`
  - `api`
  - `network`
  - `auth`
  - `guest`
  - `register`
  - `login`
- Nicht nur Implementierungen, sondern auch:
  - Kommentare
  - Dokumentation
  - Fehlermeldungen
  - Namen von Klassen, Dateien und Tests
- Ziel ist eine konsistente Offline-Sprache in der gesamten App.

### 8. Persistenzstrategie nach dem Umbau festziehen
- Lokale Speicherung nur fuer echte Offline-Daten nutzen:
  - Sprache
  - Einstellungen
  - lokale Spielstaende
  - lokaler Username
  - optional spaetere lokale Profilfelder
- Entscheiden, ob das Profil ueberhaupt gespeichert werden muss.
- Da der Username kuenftig bearbeitbar ist, sollte der geaenderte Name lokal persistent gespeichert werden.

### 9. Tests umbauen
- Bestehende Tests fuer Auth-/Session-Verhalten entfernen oder ersetzen.
- Neue Tests fuer den Offline-Zielzustand anlegen:
  - Profil zeigt initial `SudokuPlayer`
  - bearbeiteter Username wird korrekt gespeichert und wieder geladen
  - Profilseite ist ohne Login-Zustand erreichbar
  - App startet ohne Netzwerkannahmen ausserhalb der Unity-Ads-Ausnahme
  - Quickmatch/Spielfluss bleibt trotz Ads-Fehlern oder fehlender Verbindung stabil
- Widget-Tests fuer die Profil-UI:
  - `Lokales Profil` ist nicht mehr sichtbar
  - Stift-Icon und Text `bearbeiten` sind sichtbar
  - Bearbeiten aktualisiert den angezeigten Usernamen
- Widget-Tests fuer das Profil-Icon und den direkten Navigationseinstieg ergaenzen.

### 10. Abschluss und Verifikation
- `flutter analyze`
- bestehende und angepasste Tests ausfuehren
- manuelle Smoke-Tests:
  - App-Start ohne Internet
  - Profil-Icon oeffnet direkt die Profilseite
  - nirgends Login/Registrierung/Gastkonto sichtbar
  - unter dem Usernamen sind Stift-Icon und `bearbeiten` sichtbar
  - Username laesst sich lokal aendern und bleibt nach Neustart erhalten
  - keine Laufzeitfehler durch entfernte Auth- oder API-Initialisierung
  - Ads-Ausfall fuehrt nicht zu einem Blocker fuer die restliche App

## Empfohlene technische Reihenfolge
1. Profil-Standardname auf `SudokuPlayer` umstellen.
2. Lokale Persistenz fuer den editierbaren Usernamen definieren.
3. Auth-/Session-Modelle und Controller aus dem Profilfluss entfernen.
4. `app.dart` und `ProfileScope` vereinfachen.
5. Profilseite textlich und technisch bereinigen sowie Bearbeiten-UI einbauen.
6. Unity-Ads-Ausnahme dokumentarisch und technisch absichern.
7. Suchlauf ueber das gesamte Projekt auf Online-/Auth-Begriffe.
8. Tests und Doku nachziehen.

## Betroffene Dateien und Bereiche
- `lib/app/app.dart`
- `lib/features/profile/application/auth_controller.dart`
- `lib/features/profile/application/profile_controller.dart`
- `lib/features/profile/data/auth_repository.dart`
- `lib/features/profile/data/local_auth_repository.dart`
- `lib/features/profile/domain/user_session.dart`
- `lib/features/profile/domain/profile_state.dart`
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/presentation/profile_scope.dart`
- `lib/features/profile/presentation/widgets/profile_avatar_button.dart`
- `lib/features/ads/` als bewusst beibehaltene Ausnahme
- `lib/features/quickmatch/application/quickmatch_round_starter.dart`
- `pubspec.yaml`
- `test/profile_controller_test.dart`
- `test/local_auth_repository_test.dart`
- `test/show_ad_before_round_use_case_test.dart`
- `test/ad_policy_test.dart`
- bestehende Doku unter `docs/`

## Akzeptanzkriterien fuer die spaetere Umsetzung
- Die App ist funktional ohne Internet nutzbar.
- Ausnahme: Unity Ads duerfen fuer ihre Funktion weiterhin Internet benoetigen.
- Es gibt keinen Login-, Registrierungs- oder Gastkonto-Flow mehr.
- Das Profil-Icon oeffnet direkt die normale Profilseite.
- Der angezeigte Standardname ist initial ueberall `SudokuPlayer`.
- Unter dem Usernamen steht nicht mehr `Lokales Profil`, sondern eine kleine Bearbeiten-Aktion mit Stift-Icon und Text `bearbeiten`.
- Der Username kann lokal geaendert werden und bleibt nach Neustart erhalten.
- Es gibt keine externe API-Integration mehr im produktiven Code, abgesehen von der bewusst beibehaltenen Unity-Ads-Ausnahme.
- Projekttexte, Klassen und Tests verwenden keine missverstaendlichen Online-/Auth-Begriffe mehr.

## Offene Entscheidungen vor der Umsetzung
- Soll ein lokales Profilfoto kuenftig komplett entfallen oder spaeter durch ein rein lokales Asset ersetzt werden?
- Wie soll sich die App verhalten, wenn Unity Ads offline nicht verfuegbar sind?
  - Empfohlen ist ein fail-safe Verhalten ohne Blockade der Kernfunktionen.
- Wie soll die Username-Bearbeitung UX-seitig umgesetzt werden?
  - Empfehlenswert ist zunaechst ein einfacher Dialog oder Bottom-Sheet mit Textfeld und Speichern-Aktion.
