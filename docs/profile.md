# Profil-Feature: Vollstaendig lokales Offline-Profil

## Ziel
Die App zeigt dauerhaft oben rechts ein Profil-Icon.
Beim Klick darauf oeffnet sich direkt die normale Profilseite.
Das Profil ist rein lokal, benoetigt keine Anmeldung und keinen externen Dienst.

## Architektur
- `domain`
  - `ProfileState` mit dem aktuell angezeigten `username`
- `application`
  - `ProfileController` laedt und speichert den lokalen Usernamen
- `data`
  - `ProfileRepository` als kleine Persistenzschnittstelle
  - `LocalProfileRepository` auf Basis `SharedPreferences`
- `presentation`
  - globales Profil-Icon
  - Profilseite mit lokaler Bearbeiten-Funktion

## Verhalten
- Standardname ist `SudokuPlayer`.
- Es gibt keinen Login-, Registrierungs-, Gast- oder Session-Flow.
- Es gibt kein externes Profilfoto und keine `NetworkImage`-Logik.
- Der Username kann lokal bearbeitet werden.
- Ein leer gespeicherter Name faellt wieder auf `SudokuPlayer` zurueck.

## Relevante Dateien
- `lib/app/app.dart`
- `lib/features/profile/application/profile_controller.dart`
- `lib/features/profile/data/profile_repository.dart`
- `lib/features/profile/data/local_profile_repository.dart`
- `lib/features/profile/domain/profile_state.dart`
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/presentation/profile_scope.dart`
- `lib/features/profile/presentation/widgets/profile_avatar_button.dart`
- `test/profile_controller_test.dart`
- `test/local_profile_repository_test.dart`
- `test/profile_page_test.dart`
- `test/sudoku_app_profile_test.dart`

## Akzeptanzkriterien
- Das Profil-Icon ist global sichtbar.
- Das Profil-Icon oeffnet direkt die Profilseite.
- Initial wird `SudokuPlayer` angezeigt.
- Unter dem Usernamen stehen Stift-Icon und `bearbeiten`.
- `Lokales Profil` ist nicht mehr sichtbar.
- Der Username bleibt nach dem Bearbeiten lokal gespeichert.
