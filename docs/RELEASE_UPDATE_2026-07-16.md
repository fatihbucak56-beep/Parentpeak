# Release Update - 2026-07-16

## Summary
This release hardens Parentpeak for production-readiness with three core outcomes:
- Stable meal planner backend and app integration
- Reliable local fallback flows for auth and family actions
- Broader resilience UX across key parent journeys, plus AI safety routing refinements

## Included Commits
1. `4415cc9` fix(backend): stabilize meal planner prisma wiring and migration
2. `34a0d43` fix(app): restore local auth fallback and harden offline family flows
3. `9dc1a78` feat(app): add family meal planner models, service, and UI tab
4. `298f286` feat(resilience): roll out fallback routes and local-mode UX across core screens
5. `7cb0952` feat(ai): refine pedagogical safety routing and runtime config
6. `1185ef7` docs(release): add go-live board, monitoring plan, and resilience update
7. `0f15884` chore(platform): enable macOS network client and refresh backend lockfile

## What Changed
### Backend & Data
- Fixed Prisma delegate usage for meal planner operations in `backend/server.js`
- Aligned meal planner migration and schema consistency in:
  - `backend/prisma/schema.prisma`
  - `backend/prisma/migrations/20260722000000_add_meal_planner/migration.sql`

### App Reliability (Fallback / Offline)
- Reintroduced robust local auth fallback and session restore in `lib/logic/auth_service.dart`
- Hardened family-circle offline behavior and backend-tolerant request handling in `lib/logic/family_circle_service.dart`
- Stabilized widget flow tests in `test/widget_test.dart`

### Meal Planner Feature
- Added domain models in `lib/models/meal_plan.dart`
- Added integration service in `lib/services/meal_planner_service.dart`
- Added planner UI tab and interactions in `lib/ui/gemeinsam_satt_screen.dart`

### Resilience UX Rollout
- Extended local fallback routes and resiliency behavior across core screens and logic, including:
  - `lib/ui/home_screen.dart`
  - `lib/ui/chat_screen.dart`
  - `lib/ui/calendar_screen.dart`
  - `lib/ui/events_activities_screen.dart`
  - `lib/ui/photos_screen.dart`
  - `lib/logic/product_metrics_service.dart`

### AI Safety & Runtime Config
- Refined runtime configuration and safety prompt handling in `lib/config/api_config.dart`
- Updated pedagogical backend routing in `lib/logic/pedagogical_chat_backend.dart`
- Added coverage for safety-path behavior in `test/pedagogical_chat_backend_test.dart`

### Platform / Release Ops
- Enabled macOS network client entitlement:
  - `macos/Runner/DebugProfile.entitlements`
  - `macos/Runner/Release.entitlements`
- Updated backend lockfile: `backend/package-lock.json`
- Added release and monitoring docs:
  - `docs/APP_GO_LIVE_OPERATIONS_CHECKLIST.md`
  - `docs/APP_RELEASE_PRIORITY_BOARD.md`
  - `docs/POST_LAUNCH_7_DAY_MONITORING_PLAN.md`
  - `docs/RESILIENCE_FALLBACK_UPDATE_2026-07-15.md`
  - `docs/UX_STRESS_REDUCTION_SPRINT_14D.md`

## Validation Status
- Flutter analyze: clean
- Flutter tests: passing (40/40)
- Backend Prisma schema: valid
- Backend test suite: passing (12/12)
- Prisma deploy: no pending migrations

## Deployment State
- Branch `main` pushed to `origin/main`
- HEAD on remote: `0f15884`

## Risk Notes
- Main code risks addressed in this batch (fallback stability, schema/runtime mismatch, and core UX resilience)
- Remaining release risk is operational discipline during live rollout (monitoring and incident response timing)

## Suggested PR Description (Copy/Paste)
```markdown
## Why
This change set closes critical release-readiness gaps for Parentpeak by stabilizing backend meal-planner persistence, restoring reliable local fallback auth/family flows, and expanding resilient UX behavior across parent-critical journeys.

## What
- Fix meal planner Prisma wiring and migration alignment
- Restore local auth/session fallback and harden family-circle offline behavior
- Add meal planner models, service, and UI tab
- Roll out fallback/local-mode UX across core app surfaces
- Refine pedagogical AI safety routing and runtime config
- Add go-live, priority-board, and 7-day monitoring release docs
- Enable macOS network entitlement and refresh backend lockfile

## Validation
- Flutter analyze: clean
- Flutter tests: 40 passed, 0 failed
- Backend tests: 12 passed, 0 failed
- Prisma validate: success
- Prisma migrate deploy: no pending migrations

## Rollout Notes
- `main` is pushed and up to date on origin
- Execute standard go-live checklist and T+24h monitoring plan from release docs
```
