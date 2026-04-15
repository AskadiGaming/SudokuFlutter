# Implementierungsplan: Globales Profil mit festem Username

## Ziel
Die App zeigt dauerhaft oben rechts ein Profil-Element (kreisfoermiges Profilbild), unabhaengig vom aktuell geoeffneten Screen.
Beim Klick auf das Profilbild oeffnet sich ein eigener Profil-Screen.
Der Username ist fest vorgegeben und aktuell nicht editierbar.

## Architekturentscheidung
Das Profil-Feature ist in vier Schichten strukturiert:
- `domain`: Session-/Profilmodelle
- `application`: Controller fuer Session- und Profilzustand
- `data`: lokale Session-Wiederherstellung ueber `SharedPreferences`
- `presentation`: globaler Avatar-Trigger + Profilseite

Es gibt keinen Drittanbieter-Login und keinen OAuth/OIDC-Flow.

## Umsetzungsstrategie
1. Session- und Profil-Domain definieren
2. Lokale Session-Infrastruktur anbinden
3. Globalen State bereitstellen
4. Globales Profilbild auf allen Screens einbauen
5. Profil-Screen als reine Anzeige umsetzen
6. UX/Fehlerfaelle absichern
7. Tests und Wartbarkeit

## Schritt-fuer-Schritt-Plan

### 1. Domaenenmodell
- `UserSession` mit `isAuthenticated`, `userId`, `displayName`, `photoUrl`
- `ProfileState` mit `effectiveUsername`

### 2. Lokale Infrastruktur
- `AuthRepository` fuer Session-Restore
- `LocalAuthRepository` auf Basis `SharedPreferences`

### 3. Globaler State
- `AuthController` und `ProfileController` als globale `ChangeNotifier`
- App-Start: Session restaurieren, Profilzustand synchronisieren

### 4. Globales Profilbild
- `MaterialApp.builder` als Shell mit `Stack`
- Avatar oben rechts in `SafeArea`
- Klick oeffnet `ProfilePage` ueber Root-Navigator-Key

### 5. Profilseite
- Username-Anzeige
- Keine Eingabe und kein Speichern
- Klarer Hinweis, dass der Username aktuell nicht geaendert werden kann

### 6. UX und Stabilitaet
- Lade-/Fehlerzustaende sichtbar
- Avatar mit Semantics-Label
- Defensive Initialisierung, damit Startfehler keinen Red-Screen ausloesen

### 7. Tests
- Controller-Tests fuer Profilzustand
- Repository-Tests fuer lokale Session-Wiederherstellung

## Umsetzungsstand (15. April 2026)

### Erledigt
- Globaler Avatar und Profilseite sind integriert.
- Username-Editierung ist entfernt.
- Der angezeigte Standardname ist `SudokuPlayer#123123`.
- Social-Login wurde vollstaendig entfernt.
- Die Session wird lokal als Profil-Session verwaltet.
- Relevante Profil-Tests sind vorhanden.

### Dateien (Ist-Stand)
- `lib/features/profile/domain/user_session.dart`
- `lib/features/profile/domain/profile_state.dart`
- `lib/features/profile/data/auth_repository.dart`
- `lib/features/profile/data/local_auth_repository.dart`
- `lib/features/profile/application/auth_controller.dart`
- `lib/features/profile/application/profile_controller.dart`
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/presentation/widgets/profile_avatar_button.dart`
- `lib/app/app.dart`
- `test/profile_controller_test.dart`
- `test/local_auth_repository_test.dart`

## Akzeptanzkriterien
- Ein kreisfoermiges Profilbild ist dauerhaft oben rechts sichtbar.
- Klick auf das Profilbild oeffnet den Profil-Screen.
- Username `SudokuPlayer#123123` ist sichtbar.
- Es gibt keine Moeglichkeit, den Username zu bearbeiten.
- Keine Drittanbieter-Login-Funktionalitaet ist vorhanden.
- Fehler- und Ladezustaende sind fuer Nutzer nachvollziehbar.
