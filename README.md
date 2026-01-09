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

Screenshots:
- Starte die App im Emulator und nutze `flutter screenshot` oder `adb exec-out screencap -p > screen.png` um Bilder zu erzeugen.

Inhalt dieses Demos:
- Mock‑Daten für Geräte
- Mock Revocation Service (kein Netzwerk) — simuliert Erfolg/Fehler
- Blaues Theme, deutsche Texte

Nächste Schritte:
- Wenn du möchtest, erstelle ich einen PR in deinem Repo oder sende dir ein ZIP mit diesem Demo‑Projekt.
