# Backend Deploy Guide (Beginner Friendly)

Dieses Dokument hilft dir, das Parentpeak-Backend zum ersten Mal online zu bringen.

## Ziel

Am Ende hast du eine echte API-Basis-URL wie:

- `https://parentpeak-backend.onrender.com`
- oder `https://parentpeak-backend.up.railway.app`

Diese URL kommt danach in deine `.env` als `BACKEND_BASE_URL`.

## Option A: Render (einfach fuer den Start)

### 1. Konto anlegen

1. Gehe auf `https://render.com`.
2. Login mit GitHub.
3. Render mit deinem Repo verbinden.

### 2. Service erstellen

1. Klicke auf `New +` -> `Blueprint`.
2. Waehle dein Repo `Parentpeak`.
3. Render erkennt `render.yaml` automatisch.
4. Service erstellen und Deploy starten.

### 3. Environment Variablen setzen (Render Dashboard)

Im Service unter `Environment` setze:

- `BACKEND_API_TOKEN` = starker geheimer String
- `CORS_ALLOWED_ORIGINS` = `https://parentpeak.de,https://www.parentpeak.de`
- `STRIPE_WEBHOOK_SECRET` = dein Stripe Webhook Secret (`whsec_...`)

Die folgenden sind schon im Blueprint gesetzt:

- `NODE_ENV=production`
- `REQUIRE_AUTH_FOR_WRITES=1`
- `ALLOW_CLIENT_PROVIDER_EVENTS=0`
- `STRIPE_WEBHOOK_TOLERANCE_SEC=300`
- Rate-Limit Variablen

### 4. URL testen

Nach Deploy findest du deine URL im Render Service.

Teste im Browser:

- `https://<dein-render-service>/health`

Erwartung: JSON Antwort mit `status`.

## Option B: Railway

### 1. Konto anlegen

1. Gehe auf `https://railway.app`.
2. Login mit GitHub.
3. Neues Projekt aus deinem Repo erstellen.

### 2. Deploy nutzen

Das Repo enthält `railway.json` mit Build/Start Befehlen.

### 3. Environment Variablen setzen

Im Railway Service unter `Variables` setzen:

- `NODE_ENV=production`
- `REQUIRE_AUTH_FOR_WRITES=1`
- `ALLOW_CLIENT_PROVIDER_EVENTS=0`
- `STRIPE_WEBHOOK_TOLERANCE_SEC=300`
- `WRITE_RATE_LIMIT_WINDOW_MS=900000`
- `WRITE_RATE_LIMIT_MAX=120`
- `BACKEND_API_TOKEN=<secret>`
- `CORS_ALLOWED_ORIGINS=https://parentpeak.de,https://www.parentpeak.de`
- `STRIPE_WEBHOOK_SECRET=whsec_...`

### 4. URL testen

- `https://<dein-railway-service>/health`

Erwartung: HTTP 200 + JSON.

## Stripe Webhook URL

Nach erfolgreichem Deploy in Stripe Dashboard setzen:

- Endpoint: `https://<deine-backend-url>/payments/stripe/webhook`
- Events:
  - `payment_intent.succeeded`
  - `payment_intent.payment_failed`
  - `charge.refunded`

Dann das Endpoint Secret in `STRIPE_WEBHOOK_SECRET` eintragen.

## App konfigurieren

In der Projektdatei `.env`:

- `BACKEND_BASE_URL=https://<deine-backend-url>`
- `BACKEND_API_TOKEN=<gleiches token wie backend>`

## Smoke Tests

Im Projektordner ausfuehren:

```bash
set -a
source .env
set +a
bash scripts/release_smoke_suite.sh
```

Wenn Stripe Secret in `.env` noch fehlt, nur Security testen:

```bash
set -a
source .env
set +a
RUN_STRIPE_WEBHOOK_SMOKE=0 bash scripts/release_smoke_suite.sh
```

## Troubleshooting (haeufige Fehler)

1. `404 /health`
- Falsche URL verwendet (Website statt Backend-URL).

2. `403` bei Writes
- `BACKEND_API_TOKEN` fehlt in App oder stimmt nicht.

3. Stripe Webhook `400 invalid signature`
- `STRIPE_WEBHOOK_SECRET` passt nicht zum Endpoint in Stripe.

4. CORS Fehler im Web
- `CORS_ALLOWED_ORIGINS` unvollstaendig (www/non-www beachten).
