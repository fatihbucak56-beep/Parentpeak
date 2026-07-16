# Resilience Fallback Update (2026-07-15)

## Ziel

Nutzerinnen und Nutzer sollen bei Lade- oder Provider-Problemen ohne Friktion weitermachen koennen.
Statt Sackgassen gibt es pro Kernscreen direkte One-Tap-Ausweichpfade.

## Umgesetzte Fallback-Routen

### Home

- Direkt Entwicklung (ohne Wochenimpuls-Abhaengigkeit)
- Fallback Kalender -> KI
- Fallback KI -> Entwicklung

## KI Elternberatung

- Bei Provider-Ausfallnachricht im Chat:
  - Erneut versuchen
  - Zu Entwicklung
  - Zum Kalender
- Bei Init-Fehler (KI nicht verfuegbar):
  - Zu Entwicklung
  - Zum Kalender

## Wochenimpuls

- Bei Wochenimpuls nicht verfuegbar:
  - Erneut laden
  - Mit Entwicklung weitermachen
  - Zur KI-Beratung
  - Zum Kalender

## Kalender

- Bei Server-Sync fehlgeschlagen:
  - Retry
  - Zu Entwicklung
  - Zur KI-Beratung

## Utility-Screens (To-do, Einkauf, Fotos, Organisation)

- Bei Server-Sync Problemen:
  - Statusleiste "Lokaler Modus aktiv"
  - Hinweis: lokale Speicherung + automatisches Nachsenden beim naechsten Sync
  - Erneut versuchen
  - Zur KI-Beratung
  - Zu Entwicklung
  - Zum Kalender

## Events & Aktivitaeten

- Bei Feed-Fehler:
  - Erneut laden
  - Zur KI-Beratung
  - Zu Entwicklung
  - Zum Kalender

## Neue Produkt-Metriken

Die folgenden Event-Keys wurden ergaenzt, um Fallback-Nutzung sichtbar zu machen:

- home_development_direct_cta_tap
- home_fallback_route_tap
- chat_fallback_route_tap
- weekly_impulse_fallback_route_tap
- calendar_fallback_route_tap
- utility_fallback_route_tap

## Technische Wirkung

- Gleiche UX-Strategie ueber mehrere Screens: Fehler -> klarer Ausweichpfad
- One-Tap-Navigation reduziert Abbruchrisiko im Elternalltag
- Metriken erlauben schnelle Bewertung, welche Fallback-Pfade wirklich genutzt werden

## Validierung

- Geaenderte Dateien sind fehlerfrei (Datei-Checks)
- Flutter analyze (repo-safe): unveraendert nur bekannte Info-Hinweise, keine neuen blocker-relevanten Probleme durch diese Aenderungen

## Betroffene Dateien (Auszug)

- lib/ui/home_screen.dart
- lib/ui/chat_screen.dart
- lib/ui/entwicklung_impulse_screen.dart
- lib/ui/calendar_screen.dart
- lib/ui/todo_screen.dart
- lib/ui/shopping_screen.dart
- lib/ui/photos_screen.dart
- lib/ui/organization_screen.dart
- lib/ui/events_activities_screen.dart
- lib/services/meal_planner_service.dart
- lib/ui/gemeinsam_satt_screen.dart
- lib/logic/product_metrics_service.dart
