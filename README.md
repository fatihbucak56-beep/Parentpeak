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

Apple Build Hinweis (iOS/macOS)
-------------------------------

Einige Plugins (z. B. `printing`, `flutter_tts`) melden aktuell in Flutter nur eine
SPM-Warnung. Um Builds stabil zu halten, nutze den CocoaPods-Workflow:

1. `bash scripts/prepare_apple_build.sh`
2. Danach normal bauen, z. B.:
	- `flutter build ios --no-codesign`
	- `flutter build macos`

Was das Script macht:
- Deaktiviert Flutter-Swift-Package-Manager-Plugin-Integration (falls von deiner Flutter-Version unterstuetzt)
- Fuehrt `flutter pub get` aus
- Fuehrt `pod install --repo-update` fuer iOS und macOS aus

Finale Backend Verkabelung (Android + iOS)
------------------------------------------

Ziel: Firebase Auth und Backend-Konfiguration so setzen, dass die App auf Android und iOS produktionsnah laeuft.

Exakte Reihenfolge:

1. Firebase Projekt und Apps anlegen
- In Firebase ein Projekt anlegen oder bestehendes nutzen.
- Android App mit Paketname com.parentpeak.app anlegen.
- iOS App mit Bundle ID com.parentpeak.app anlegen.

2. Firebase Auth aktivieren
- In Firebase Authentication den Provider E-Mail/Passwort aktivieren.

3. Native Firebase Dateien herunterladen und einlegen
- Android Datei nach android/app/google-services.json legen.
- iOS Datei nach ios/Runner/GoogleService-Info.plist legen.

4. FlutterFire Konfiguration generieren
- FlutterFire CLI installieren: dart pub global activate flutterfire_cli
- Dann im Projekt ausfuehren:
	flutterfire configure --android-package-name com.parentpeak.app --ios-bundle-id com.parentpeak.app
- Ergebnis pruefen: lib/firebase_options.dart muss existieren.

5. Umgebungswerte auf Produktion setzen
- In .env folgende Werte setzen:
	- GEMINI_API_KEY
	- BACKEND_API_TOKEN
	- BACKEND_BASE_URL (https URL, keine lokale Emulator-URL)

6. Apple Build-Prep ausfuehren
- bash scripts/prepare_apple_build.sh

7. Produktions-Check im Repo ausfuehren
- bash scripts/verify_prod_backend_setup.sh

8. Build und Lauf testen
- flutter analyze
- Android: flutter run -d android
- iOS: flutter run -d ios

9. Release Smoke-Test
- Android: flutter build appbundle
- iOS: flutter build ios --release

Hinweis:
- Wenn scripts/verify_prod_backend_setup.sh Fehler zeigt, zuerst diese beheben, dann erneut pruefen.

iOS Signing Readiness (Release)
-------------------------------

Bevor du einen echten signierten iOS-Release/Archive-Build machst, pruefe lokal:

1. `bash scripts/verify_ios_signing_readiness.sh`

Wenn der Check fehlschlaegt, in Xcode korrigieren:
1. `ios/Runner.xcworkspace` in Xcode oeffnen
2. Target `Runner` -> `Signing & Capabilities`
3. Team setzen und automatische Provisionierung aktiv lassen
4. Check erneut ausfuehren

Optional per CLI (wenn du deine Team-ID kennst):
1. `bash scripts/set_ios_development_team.sh ABCDE12345`
2. `bash scripts/verify_ios_signing_readiness.sh`

Empfohlene finale Reihenfolge:
1. `bash scripts/verify_prod_backend_setup.sh`
2. `bash scripts/verify_ios_signing_readiness.sh`
3. `flutter build apk --release`
4. `flutter build ios --release` (mit aktivem Signing)
