# Auth Hardening Runbook (Production)

This runbook secures Parentpeak write authorization after moving the app to Firebase user-bound tokens.

## Scope

Applies to:
- mobile and web write requests (`POST`, `PUT`, `PATCH`, `DELETE`)
- Render production backend
- token rotation and post-change validation

## Target State

1. Client writes are authorized by verified Firebase ID tokens.
2. No privileged backend bearer token is embedded in app builds.
3. Backend CORS is explicit and fail-closed in production.
4. Legacy shared backend token is rotated and retained only for backend/admin use.

## A. Render Environment Configuration

Set in Render service environment:

- `NODE_ENV=production`
- `REQUIRE_AUTH_FOR_WRITES=1`
- `CORS_ALLOWED_ORIGINS=https://parentpeak.de,https://www.parentpeak.de`
- `FIREBASE_SERVICE_ACCOUNT_JSON={...}` (full service account JSON, single line)
- `FIREBASE_REQUIRE_AUTH=1`
- `BACKEND_API_TOKEN=<new-strong-random-token>`

Notes:
- Keep `BACKEND_API_TOKEN` for admin/service paths and emergency break-glass only.
- Do not expose `BACKEND_API_TOKEN` in Flutter/Web compile-time defines.

## B. Immediate Token Rotation

Rotate now if any token was previously committed or logged.

1. Generate a new token (example):

```bash
openssl rand -hex 32
```

2. Replace Render `BACKEND_API_TOKEN` with the new value.
3. Redeploy service.
4. Update only trusted server-side consumers/tests that still require this token.
5. Invalidate old token in all secret stores.

## C. Deploy Verification Checklist

Run after Render deploy is live.

1. Health endpoint:

```bash
curl -i https://parentpeak.onrender.com/health
```

Expected: `200`.

2. Unauthenticated write must be blocked:

```bash
curl -i -X POST https://parentpeak.onrender.com/api/food-feed/recipes \
  -H "Content-Type: application/json" \
  -d '{"userId":"u1","title":"x","category":"snack","difficulty":"leicht","servings":1,"ingredients":[],"instructions":[]}'
```

Expected: `401`.

3. CORS allowlist enforcement:

```bash
curl -i https://parentpeak.onrender.com/health \
  -H "Origin: https://evil.example"
```

Expected: blocked CORS origin (no successful browser CORS allow).

4. Authenticated write with valid Firebase user token (manual/API client) succeeds.

Expected: `200/201` on a write endpoint with a valid user token.

5. Optional backend-token smoke (server-side only):

```bash
BACKEND_BASE_URL=https://parentpeak.onrender.com \
BACKEND_API_TOKEN=<new-token> \
bash scripts/backend_security_smoke_test.sh
```

## D. App Build Guardrails

1. Ensure no privileged token is passed to app builds:
- remove `BACKEND_API_TOKEN` from mobile/web CI build defines
- avoid `.env` asset bundling of privileged secrets

2. Keep only public/safe client config in app runtime values.

## E. Go / No-Go Criteria

Go when all are true:

1. `401` for anonymous write calls.
2. Valid Firebase token writes succeed.
3. CORS allowlist accepts only intended origins.
4. New `BACKEND_API_TOKEN` is active; old token invalid.
5. No privileged token present in app runtime config.

No-Go if any criterion fails.

## F. Rollback (Time-boxed Emergency)

If release is blocked by auth misconfiguration:

1. Keep `REQUIRE_AUTH_FOR_WRITES=1`.
2. Fix Firebase service account config first.
3. Use backend token only for temporary operational continuity.
4. Revert to Firebase-only client writes before resuming rollout.
