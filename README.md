Trusted Circle Demo
====================

Kurzanleitung zur Demo‑App (Blau / DE / Phone)

Voraussetzungen:
- Flutter SDK installiert
- Ein Android‑Emulator oder Gerät

Starten:
1. `flutter pub get`
2. `.env` aus `.env.example` anlegen und `ABACUS_API_KEY` ersetzen (oder Platzhalter belassen für Demo)
3. `flutter run` um die App zu starten

Wichtige .env Variablen:
- `GEMINI_API_KEY`: API Key fuer den Paedagogik-Chat
- `BACKEND_BASE_URL`: Basis-URL deines Backends (z. B. `https://api.example.com`)
- `BACKEND_API_TOKEN`: Bearer Token fuer geschuetzte Endpunkte
- `BACKEND_FAMILY_ID`: Familienkontext fuer Requests (z. B. `demo-family-001`)
- `BACKEND_API_VERSION`: Version des Request-Schemas (Standard: `v1`)
- `BACKEND_TODOS_PATH`, `BACKEND_SHOPPING_PATH`, `BACKEND_CALENDAR_EVENTS_PATH`, `BACKEND_HEALTH_PATH`: optionale Endpoint-Overrides

Screenshots:
- Starte die App im Emulator und nutze `flutter screenshot` oder `adb exec-out screencap -p > screen.png` um Bilder zu erzeugen.

Inhalt dieses Demos:
- Mock‑Daten für Geräte
- Mock Revocation Service (kein Netzwerk) — simuliert Erfolg/Fehler
- Blaues Theme, deutsche Texte

Nächste Schritte:
- Wenn du möchtest, erstelle ich einen PR in deinem Repo oder sende dir ein ZIP mit diesem Demo‑Projekt.
# Demo-Branch: cleanup/security-and-demo

\nParentpeak MVP-Erweiterung\n--------------------------\n
Hinzugefügt in dieser Sitzung:
- Pädagogik‑Chat (Platzhalter) mit Eingabefeld und Senden‑Button
- Familienkalender (Platzhalter) mit einfacher Terminliste und "Termin hinzufügen"
- Geräteverwaltung bleibt als dritter Tab
 

Starten (Android per USB empfohlen):
1. `flutter pub get`
2. `flutter run -d <deviceId>` (z. B. `RFCY30GWBEB`)

Lokalisierung: en, de
