# Parent Matching Smoke Quick Start

Diese Kurznotiz dokumentiert den optionalen Parent-Matching-Teil in der bestehenden Release-Smoke-Suite.

## Ziel

Der Check stellt sicher, dass Parent-Matching-Aktionen in Produktion DB-basiert gespeichert werden und nicht auf In-Memory-Fallback laufen.

Geprueft werden drei Aktionen:

- like
- block
- report

## Schnellstart

```bash
set -a
source .env
set +a
BACKEND_BASE_URL=https://parentpeak.onrender.com \
RUN_STRIPE_WEBHOOK_SMOKE=0 \
RUN_PARENT_MATCHING_SMOKE=1 \
bash scripts/release_smoke_suite.sh
```

## Erwartetes Ergebnis

- Backend Security Smoke: erfolgreich
- Parent Matching Smoke: alle drei Aktionen mit HTTP 201
- Keine Antwort mit `"source":"in-memory-fallback"`

## Konfigurierbare Variablen

- `RUN_PARENT_MATCHING_SMOKE=1` aktiviert den Parent-Matching-Teil
- `PARENT_MATCHING_SMOKE_USER_ID` optional, Standard: `smoke-user-001`
- `PARENT_MATCHING_SMOKE_FAMILY_ID` optional, Standard: `smoke-family-001`
- `BACKEND_API_TOKEN` erforderlich
- `BACKEND_BASE_URL` erforderlich
