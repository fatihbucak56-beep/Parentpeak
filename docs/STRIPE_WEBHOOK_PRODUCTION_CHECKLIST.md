# Stripe Webhook Production Checklist

This checklist is for a secure Parentpeak go-live where payment completion is only accepted from verified Stripe webhook events.

## 1. Required environment variables

Set these variables in your backend runtime environment:

- `BACKEND_API_TOKEN=<strong-random-token>`
- `REQUIRE_AUTH_FOR_WRITES=1`
- `CORS_ALLOWED_ORIGINS=https://parentpeak.de,https://www.parentpeak.de`
- `STRIPE_WEBHOOK_SECRET=whsec_...`
- `STRIPE_WEBHOOK_TOLERANCE_SEC=300`
- `ALLOW_CLIENT_PROVIDER_EVENTS=0`

Optional but recommended:

- `NODE_ENV=production`
- `WRITE_RATE_LIMIT_WINDOW_MS=900000`
- `WRITE_RATE_LIMIT_MAX=120`

## 2. Stripe Dashboard endpoint setup

1. Open Stripe Dashboard -> Developers -> Webhooks.
2. Add endpoint URL:
   - `https://<your-backend-domain>/payments/stripe/webhook`
3. Choose API version (pin one version for stability).
4. Subscribe to these events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.refunded`
5. Copy endpoint signing secret (`whsec_...`) into `STRIPE_WEBHOOK_SECRET`.
6. Redeploy backend.

## 3. Backend behavior expectations

Expected secure behavior:

- `/payments/confirm` creates transactions as `pending` for provider flows.
- `completed` is rejected unless provider verification is present.
- `/payments/stripe/webhook` validates `Stripe-Signature`.
- `/payments/provider-events` is blocked in production with HTTP `403` when `ALLOW_CLIENT_PROVIDER_EVENTS=0`.

## 4. Functional smoke tests

Run after deployment:

1. Health check:

```bash
curl -i https://<your-backend-domain>/health
```

Expected: HTTP `200`.

2. Provider-events client endpoint blocked:

```bash
curl -i -X POST https://<your-backend-domain>/payments/provider-events \
  -H "Content-Type: application/json" \
  -d '{"provider":"stripe","providerTransactionRef":"pi_test","status":"completed","verified":true}'
```

Expected: HTTP `403`.

3. Webhook signature check is enforced:

```bash
curl -i -X POST https://<your-backend-domain>/payments/stripe/webhook \
  -H "Content-Type: application/json" \
  -d '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test"}}}'
```

Expected: HTTP `400` (missing/invalid Stripe signature).

Automated option (recommended):

```bash
BACKEND_BASE_URL=https://<your-backend-domain> \
STRIPE_WEBHOOK_SECRET=whsec_... \
bash scripts/stripe_webhook_smoke_test.sh
```

Combined option (security + stripe):

```bash
BACKEND_BASE_URL=https://<your-backend-domain> \
BACKEND_API_TOKEN=... \
STRIPE_WEBHOOK_SECRET=whsec_... \
bash scripts/release_smoke_suite.sh
```

## 5. App-side release expectations

In release mode, the app should:

- create payment as `pending`,
- wait for backend transaction state update,
- only continue event publication once status becomes `completed`.

If status stays `pending`, verify Stripe webhook delivery logs in Stripe Dashboard.

## 6. Rollback plan (if checkout breaks)

Temporary emergency fallback steps:

1. Keep webhook endpoint enabled.
2. For short-term mitigation only, set:
   - `ALLOW_CLIENT_PROVIDER_EVENTS=1`
3. Redeploy and monitor.
4. Revert to `ALLOW_CLIENT_PROVIDER_EVENTS=0` immediately after incident resolution.

## 7. Security notes

- Never commit `STRIPE_WEBHOOK_SECRET`.
- Rotate webhook secret if leaked or after major incident.
- Restrict dashboard access and use least privilege.
- Keep event subscriptions minimal and explicit.
