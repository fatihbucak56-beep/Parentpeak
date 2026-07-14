Trusted Circle Demo
====================

Kurzanleitung zur Demo‑App (Blau / DE / Phone)

Voraussetzungen:
- Flutter SDK installiert
- Ein Android‑Emulator oder Gerät

Starten:
1. `bash scripts/flutter_repo.sh pub get`
2. `.env` aus `.env.example` anlegen und `ABACUS_API_KEY` ersetzen (oder Platzhalter belassen für Demo)
3. `bash scripts/flutter_repo.sh run` um die App zu starten

Wichtige .env Variablen:
- `GEMINI_API_KEY`: API Key fuer den Paedagogik-Chat
- `BACKEND_BASE_URL`: Basis-URL deines Backends (z. B. `https://api.example.com`)
- `BACKEND_API_TOKEN`: Bearer Token fuer geschuetzte Endpunkte
- `BACKEND_FAMILY_ID`: Familienkontext fuer Requests (z. B. `demo-family-001`)
- `BACKEND_API_VERSION`: Version des Request-Schemas (Standard: `v1`)
- `BACKEND_TODOS_PATH`, `BACKEND_SHOPPING_PATH`, `BACKEND_CALENDAR_EVENTS_PATH`, `BACKEND_HEALTH_PATH`: optionale Endpoint-Overrides

Backend Deploy (Anfaenger)
--------------------------

Wenn du noch keine echte Backend-URL hast, starte hier:

1. `docs/BACKEND_DEPLOY_BEGINNER_GUIDE.md`

Repo enthaelt bereits Starter-Configs:
- `render.yaml` (Render Blueprint)
- `railway.json` (Railway Build/Start)

Backend-Hardening (Produktion):
- `REQUIRE_AUTH_FOR_WRITES=1`: Schuetzt Schreibzugriffe (POST/PUT/PATCH/DELETE) per Bearer-Token.
- `CORS_ALLOWED_ORIGINS`: Kommagetrennte Origin-Allowlist, z. B. `https://parentpeak.de,https://www.parentpeak.de`.
- `WRITE_RATE_LIMIT_WINDOW_MS` und `WRITE_RATE_LIMIT_MAX`: Begrenzen Schreibanfragen pro Zeitfenster.

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

Standard fuer lokale Flutter-Kommandos im Repo:
1. `bash scripts/flutter_repo.sh <flutter-kommando>`

Beispiele:
	- `bash scripts/flutter_repo.sh analyze`
	- `bash scripts/flutter_repo.sh run -d ios`
	- `bash scripts/flutter_repo.sh build macos`

1. `bash scripts/prepare_apple_build.sh`
2. Danach normal bauen, z. B.:
	- `bash scripts/flutter_repo.sh build ios --no-codesign`
	- `bash scripts/flutter_repo.sh build macos`

Was das Script macht:
- Deaktiviert Flutter-Swift-Package-Manager-Plugin-Integration (falls von deiner Flutter-Version unterstuetzt)
- Fuehrt `flutter pub get` aus
- Fuehrt `pod install --repo-update` fuer iOS und macOS aus

CI Hinweis (Analyzer)
---------------------

Fuer CI wird ein robuster Analyzer-Wrapper verwendet:
1. `bash scripts/ci_flutter_analyze.sh`

Der Wrapper bricht bei echten Analyzer-Problemen weiterhin ab, toleriert aber die bekannten
SPM-Plugin-Hinweise von Flutter, solange keine Analyzer-Issues vorliegen.

Zusaetzlich prueft CI das Backend-Sicherheits-Baseline-Profil:
1. `bash scripts/verify_backend_security_baseline.sh`

Weitere Details und Migrationskriterien stehen in:
- `docs/SPM_PLUGIN_STATUS.md`

Crash Reporting (Firebase Crashlytics)
-------------------------------------

Crash-Monitoring ist im App-Startpfad zentral verdrahtet und nutzt Firebase Crashlytics,
wenn Firebase auf der Plattform verfuegbar ist.

- Release-Builds: Crashlytics ist aktiv.
- Debug-Builds: Crashlytics ist standardmaessig aus.
- Optional fuer Debug-Tests: mit `--dart-define=PP_ENABLE_CRASHLYTICS_DEBUG=true` aktivierbar.

Der Hook deckt Flutter-Framework-Fehler, Platform-Dispatcher-Fehler und Zone-Fehler ab.

SPM-Plugin-Warnungen: Ticketpaket
---------------------------------

Das priorisierte Massnahmenpaket fuer die aktuellen Apple-SPM-Plugin-Warnungen ist hier gepflegt:
- `docs/SPM_PLUGIN_STATUS.md` (Abschnitt: Work package)

Security Smoke Test (gegen laufendes Backend)
---------------------------------------------

Mit diesem Script kannst du nach Deployments schnell die wichtigsten Security-Pfade validieren:
1. `BACKEND_BASE_URL=https://api.example.com bash scripts/backend_security_smoke_test.sh`

Optional:
- `BACKEND_API_TOKEN=...` fuer authentifizierten Write-Test
- `EXPECT_WRITE_AUTH=0` falls Write-Auth in der Zielumgebung bewusst deaktiviert ist
- `SMOKE_ORIGIN=https://parentpeak.de` um CORS mit echter Origin zu testen

Stripe Webhook Smoke Test (Produktion)
--------------------------------------

Zur Verifikation von Stripe-Signaturpruefung und Provider-Event-Haertung:

1. `BACKEND_BASE_URL=https://api.example.com STRIPE_WEBHOOK_SECRET=whsec_... bash scripts/stripe_webhook_smoke_test.sh`

Optional:
- `STRIPE_TEST_PAYMENT_INTENT_REF=pi_...` um eine konkrete Referenz zu testen
- `EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED=0` wenn Client-Provider-Events bewusst offen sind

Release Smoke Suite (Ein Befehl)
--------------------------------

Führt Security + Stripe Webhook Smoke Tests hintereinander aus:

1. `BACKEND_BASE_URL=https://api.example.com BACKEND_API_TOKEN=... STRIPE_WEBHOOK_SECRET=whsec_... bash scripts/release_smoke_suite.sh`

Optionale Schalter:
- `RUN_BACKEND_SECURITY_SMOKE=0` nur Stripe Test
- `RUN_STRIPE_WEBHOOK_SMOKE=0` nur Security Test
- `EXPECT_WRITE_AUTH=0` falls Write-Auth bewusst deaktiviert ist
- `EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED=0` falls Provider-Events bewusst offen sind

Release Hub (Empfohlen)
-----------------------

Fuer die finale Veroeffentlichung und den Betrieb nach Launch:

1. Priorisierung vor/nach Release:
	- `docs/APP_RELEASE_PRIORITY_BOARD.md`
2. Operative Go-Live Checkliste mit Ownern:
	- `docs/APP_GO_LIVE_OPERATIONS_CHECKLIST.md`
3. 7-Tage Monitoring und Eskalation nach Launch:
	- `docs/POST_LAUNCH_7_DAY_MONITORING_PLAN.md`
4. Kompakte Meeting-Seite fuer Go/No-Go:
	- `docs/APP_GO_NO_GO_DECISION_PAGE.md`
5. Druckbare 1-Seiten Uebersicht fuer Management/Partner:
	- `docs/RELEASE_EXEC_SUMMARY.md`
6. Ultrakurzer Investor-Brief (DE):
	- `docs/RELEASE_INVESTOR_BRIEF_DE.md`
7. Ultra-short investor brief (EN):
	- `docs/RELEASE_INVESTOR_BRIEF_EN.md`

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
