# W-05 Production Hardening — Complete

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers
**Commit:** 1b5687b

## Files Created

- `src/.env.production.example` — production env template, no secrets
- `docs/DEPLOYMENT_CHECKLIST.md` — full deploy runbook incl. smoke tests
- `src/tests/Feature/ProductionConfigTest.php` — Pest sanity test (1 assertion)

## Env Keys Verified (config audit)

| File | Key | Value / Fallback | Status |
|------|-----|-----------------|--------|
| config/app.php | `debug` | `env('APP_DEBUG', false)` | OK — fallback is false |
| config/session.php | `secure` | `env('SESSION_SECURE_COOKIE')` | OK — no default; must be set explicitly |
| config/session.php | `same_site` | `env('SESSION_SAME_SITE', 'lax')` | OK — lax dev default, strict in prod template |
| config/logging.php | `single.level` | `env('LOG_LEVEL', 'debug')` | NOTE — default is debug; prod template sets warning |
| .env.example | APP_DEBUG | true | OK — intentional local default |
| .env.example | APP_ENV | local | OK — intentional local default |

## Pest Results

```
Tests: 1 passed (1 assertions)
Duration: 0.38s
```

## Config Issues Found

- `config/logging.php`: all channel drivers default `LOG_LEVEL` to `'debug'`. Not a code bug — env override is the correct mechanism. Mitigated in prod template with `LOG_LEVEL=warning`.
- `config/session.php` `secure` key has no fallback (evaluates to `null`/falsy if env absent). Acceptable — prod template explicitly sets `SESSION_SECURE_COOKIE=true`. No code change needed.

## W-05 Root Cause Summary

419 CSRF stack trace leaked because `APP_DEBUG=true` was active. Fix: `APP_DEBUG=false` in production `.env`. The deployment checklist smoke test (section 6.4) will catch any regression.
