# Implementierungsplan: Theme-Auswahl entfernen, nur Dunkelblau behalten

## Ziel
Die App soll zukünftig nur noch ein einziges Theme verwenden: **Dunkelblau**.  
Die Auswahlmöglichkeit für Themes in den Einstellungen entfällt vollständig.

## Ausgangslage
Aktuell unterstützt die App mehrere Themes über:
- `lib/app/theme/app_theme.dart` (`AppThemeKey` + `appThemes`)
- `lib/app/app.dart` (Theme-State + Persistenz über `shared_preferences`)
- `lib/features/settings/presentation/settings_page.dart` (Dropdown zur Theme-Auswahl)

## Umsetzungsstrategie
Die Umstellung erfolgt in vier Schritten:
1. Theme-System auf ein festes Dunkelblau-Theme reduzieren
2. Theme-State und Theme-Persistenz entfernen
3. Theme-Auswahl aus den Einstellungen entfernen
4. UI/Regression prüfen und Altlasten bereinigen

## Schritt-für-Schritt-Plan

### 1. Festes Dunkelblau-Theme definieren
- In `lib/app/theme/app_theme.dart` die Mehrfach-Struktur auf ein einziges Theme reduzieren.
- `AppThemeKey` und `appThemes` entfernen oder durch eine direkte Konstante ersetzen (z. B. `appTheme` oder `darkBlueTheme`).
- Sicherstellen, dass das verbleibende Theme inhaltlich dem bisherigen `darkBlue`-Theme entspricht.

Ergebnis:
Es existiert nur noch eine Theme-Definition.

### 2. Theme-State und Persistenz entfernen
- In `lib/app/app.dart` alle Theme-bezogenen Zustände und Callbacks entfernen:
  - `_currentTheme`
  - `_updateTheme(...)`
  - Laden/Speichern von `_themePreferenceKey`
- `MaterialApp.theme` direkt auf das feste Dunkelblau-Theme setzen.
- Theme-Preference-Key optional einmalig löschen (`remove('app_theme')`) oder komplett ignorieren.

Ergebnis:
Die App nutzt immer dasselbe Theme, ohne Theme-State und ohne Theme-Persistenzlogik.

### 3. Einstellungen vereinfachen
- In `lib/features/settings/presentation/settings_page.dart` Theme-abhängige Parameter entfernen:
  - `currentTheme`
  - `onThemeChanged`
- Theme-Abschnitt inklusive Dropdown entfernen.
- Falls notwendig: Einstellungen-Navigation und Konstruktor-Aufrufe in `lib/app/main_navigation_page.dart` anpassen.

Ergebnis:
In den Einstellungen wird keine Theme-Auswahl mehr angezeigt.

### 4. Bereinigung und Validierung
- Nicht mehr benötigte Imports und Typen entfernen.
- Falls nach der Umstellung `shared_preferences` nur noch für Sprache/andere Features benötigt wird, Dependency beibehalten; sonst optional später separat aufräumen.
- Manuelle Prüfung durchführen:
  - App-Start
  - Navigation zwischen Hauptseiten
  - Einstellungen öffnen
  - Neustart der App (Theme bleibt dunkelblau, ohne Auswahl)

Ergebnis:
Keine toten Codepfade, keine UI-Regressionen, konsistentes Theme-Verhalten.

## Betroffene Dateien (geplant)
- `lib/app/theme/app_theme.dart`
- `lib/app/app.dart`
- `lib/app/main_navigation_page.dart`
- `lib/features/settings/presentation/settings_page.dart`
- Optional: Tests unter `test/` (falls vorhanden und angepasst werden müssen)

## Risiken und Hinweise
- Konstruktor-Signaturen können sich entlang der Navigationskette ändern (Compile-Fehler möglich, bis alle Aufrufe angepasst sind).
- Falls Tests auf Theme-Auswahl abzielen, müssen diese entfernt oder auf das feste Theme umgestellt werden.
- Persistierte Altwerte (`app_theme`) dürfen die App nicht beeinflussen; nach Entfernen der Auswahllogik muss dieser Wert wirkungslos sein.

## Akzeptanzkriterien
Das Ticket gilt als abgeschlossen, wenn:
- Es nur noch ein aktives Theme gibt: Dunkelblau.
- In den Einstellungen gibt es keine Theme-Auswahl mehr.
- Beim Start und nach Neustart bleibt das Erscheinungsbild unverändert dunkelblau.
- Es existiert keine Laufzeitlogik mehr zum Wechseln zwischen mehreren Themes.
- Die App kompiliert ohne ungenutzte Theme-Wechsel-Parameter oder Referenzen auf entfernte Theme-Enums.
