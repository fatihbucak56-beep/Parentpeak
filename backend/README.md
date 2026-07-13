# Parentpeak Marktplatz Backend

## Installation

1. **Node.js installieren** (falls nicht vorhanden)
   - https://nodejs.org/ (Version 16+)

2. **Dependencies installieren:**
   ```bash
   cd backend
   npm install
   ```

3. **Backend starten:**
   ```bash
   npm start
   ```

Das Backend läuft dann auf: **http://localhost:3000**

## Produktions-Hardening

Für produktionsnahe Nutzung setze folgende Umgebungsvariablen vor dem Start:

- `BACKEND_API_TOKEN`: Erwarteter Bearer-Token für Schreibzugriffe
- `REQUIRE_AUTH_FOR_WRITES=1`: Aktiviert Auth-Pflicht für `POST/PUT/PATCH/DELETE`
- `CORS_ALLOWED_ORIGINS`: Kommagetrennte Origin-Allowlist
- `WRITE_RATE_LIMIT_WINDOW_MS`: Zeitfenster für Write-Rate-Limit (ms)
- `WRITE_RATE_LIMIT_MAX`: Max. Schreibanfragen pro Fenster und Client
- `STRIPE_WEBHOOK_SECRET`: Stripe Endpoint Signing Secret (`whsec_...`)
- `STRIPE_WEBHOOK_TOLERANCE_SEC`: erlaubte Zeitabweichung fuer Stripe Signaturen
- `ALLOW_CLIENT_PROVIDER_EVENTS=0`: deaktiviert clientseitige Provider-Statusupdates

Beispiel:

```bash
export BACKEND_API_TOKEN="..."
export REQUIRE_AUTH_FOR_WRITES=1
export CORS_ALLOWED_ORIGINS="https://parentpeak.de,https://www.parentpeak.de"
export STRIPE_WEBHOOK_SECRET="whsec_..."
export STRIPE_WEBHOOK_TOLERANCE_SEC=300
export ALLOW_CLIENT_PROVIDER_EVENTS=0
node server.js
```

## Stripe Webhook (Produktion)

Sichere Stripe-Integration laeuft ueber:

```bash
POST /payments/stripe/webhook
```

Wichtig:
- Dieser Endpoint erwartet `application/json` Raw Body und den Header `Stripe-Signature`.
- Die Signatur wird serverseitig gegen `STRIPE_WEBHOOK_SECRET` geprueft.
- `completed` und `refunded` werden nur aus verifizierten Provider-Events akzeptiert.
- Der Legacy-Dev-Pfad `POST /payments/provider-events` sollte in Produktion deaktiviert sein (`ALLOW_CLIENT_PROVIDER_EVENTS=0`).

Empfohlene Stripe Event-Abos fuer den Endpoint:
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `charge.refunded`

## Post-Deploy Smoke Checks

1. Health pruefen:

```bash
curl -i https://api.example.com/health
```

2. Client-Provider-Events muessen in Produktion geblockt sein:

```bash
curl -i -X POST https://api.example.com/payments/provider-events \
   -H "Content-Type: application/json" \
   -d '{"provider":"stripe","providerTransactionRef":"pi_test","status":"completed","verified":true}'
```

Erwartung: `403`.

Automatisiert (empfohlen):

```bash
BACKEND_BASE_URL=https://api.example.com \
STRIPE_WEBHOOK_SECRET=whsec_... \
bash scripts/stripe_webhook_smoke_test.sh
```

Kombiniert (Security + Stripe in einem Lauf):

```bash
BACKEND_BASE_URL=https://api.example.com \
BACKEND_API_TOKEN=... \
STRIPE_WEBHOOK_SECRET=whsec_... \
bash scripts/release_smoke_suite.sh
```

Schneller Smoke-Test gegen eine laufende Instanz:

```bash
BACKEND_BASE_URL=https://api.example.com \
BACKEND_API_TOKEN=... \
bash scripts/backend_security_smoke_test.sh
```

## API Endpoints

### 📋 Alle Anbieter abrufen
```
GET /api/providers
```

### 🔍 Nach Kategorie filtern
```
GET /api/providers/category/{category}
```

### 👤 Einzelnen Anbieter abrufen
```
GET /api/providers/{id}
```

### 🔎 Suchen
```
GET /api/search?q={suchtext}
```

### 📊 Alle Kategorien
```
GET /api/categories
```

### ⭐ Bewertung hinzufügen
```
POST /api/providers/{id}/review
Body: { "rating": 5, "comment": "...", "parentName": "..." }
```

### 🎯 Erweiterte Filter
```
POST /api/providers/filter
Body: { 
  "categories": ["Mathe", "Deutsch"],
  "maxPrice": 30,
  "minRating": 4.5
}
```

### 💚 Health Check
```
GET /health
```

## Testdaten

Die `providers.json` enthält 10 Beispiel-Anbieter:
- 6 Nachhilfelehrer (Mathe, Deutsch, Englisch, etc.)
- 4 Betreuer/Nannys (Kleinkinder, Schulkinder, Fahrdienste, etc.)

## Für Flutter-App konfigurieren

In der Flutter-App, update die Backend-URL:
```dart
const String backendUrl = 'http://192.168.x.x:3000';  // IP des Computers
```

## Optional: Für extern erreichbar machen

Um die App auf dem physischen Handy zu testen:
1. Finde deine Computer-IP: `ipconfig` (Windows) oder `ifconfig` (Mac/Linux)
2. Starte Backend mit: `npm start`
3. In der Flutter-App: `http://{DEINE_IP}:3000`
