# Deployment Checklist — Floz SDN Kelapadua IV

Use this checklist for every production deployment. Run commands as the app's system user (not root) unless noted otherwise.

---

## 1. Pre-Deploy: Environment Hardening

### 1.1 Verify `.env` is configured from the production template

```bash
# Must NOT be committed — confirm it is gitignored
git check-ignore -v .env
```

Expected: `.gitignore:.env`

### 1.2 Confirm `APP_DEBUG=false`

```bash
grep APP_DEBUG .env
# Expected output: APP_DEBUG=false
```

Also verify the runtime value after config:cache (see section 6):

```bash
php artisan tinker --execute="echo config('app.debug') ? 'DEBUG ON — BAD' : 'debug off — good';"
```

Expected: `debug off — good`

### 1.3 Confirm `APP_ENV=production`

```bash
grep APP_ENV .env
# Expected output: APP_ENV=production
```

### 1.4 Confirm session cookie hardening

```bash
grep SESSION_SECURE_COOKIE .env   # must be: true
grep SESSION_SAME_SITE .env       # must be: strict
```

### 1.5 Confirm log level is not `debug`

```bash
grep LOG_LEVEL .env
# Expected: warning or error (never debug in production)
```

---

## 2. Database Migrations

Run pending migrations before switching traffic.

```bash
php artisan migrate --force
```

If a migration fails, roll back and investigate before proceeding:

```bash
php artisan migrate:rollback
```

---

## 3. Frontend Assets

```bash
npm ci --omit=dev
npm run build
```

Verify the `public/build/` directory is populated:

```bash
ls public/build/assets/ | wc -l
# Should be non-zero
```

---

## 4. Config & Route Cache

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

To clear all caches (use if a deployment rolls back):

```bash
php artisan optimize:clear
```

---

## 5. Storage & Permissions

```bash
php artisan storage:link          # creates public/storage symlink if missing
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache   # adjust user to match your web server
```

---

## 6. Production Readiness Smoke Tests

Run these from the server or a network-accessible machine. Replace `https://floz.example.com` with the actual URL.

### 6.1 Login page loads (no debug trace exposed)

```bash
curl -s -o /dev/null -w "%{http_code}" https://floz.example.com/login
# Expected: 200
```

### 6.2 API auth endpoint responds

```bash
curl -s -o /dev/null -w "%{http_code}" -X POST https://floz.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"bad@example.com","password":"wrong"}'
# Expected: 401 or 422 (NOT 419 with a stack trace, NOT 500)
```

### 6.3 Year-transition route redirects unauthenticated users to login

```bash
curl -s -o /dev/null -w "%{http_code}" https://floz.example.com/year-transition
# Expected: 302 (redirect to /login)
```

### 6.4 CSRF error page is generic (no stack trace)

```bash
# POST without a CSRF token — should return a generic 419 page, NOT a Laravel debug trace
curl -s -c /tmp/csrf_cookies.txt https://floz.example.com/login > /dev/null
curl -s -o /tmp/csrf_response.html -w "%{http_code}" -X POST https://floz.example.com/login \
  -b /tmp/csrf_cookies.txt \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=test@example.com&password=test"
grep -i "tokaf\|vendor\|stack trace\|Whoops" /tmp/csrf_response.html && echo "LEAK DETECTED" || echo "OK — no trace leaked"
```

Expected: `OK — no trace leaked`

This test directly addresses the W-05 finding: a 419 CSRF response leaked the full Laravel stack trace including local filesystem paths because `APP_DEBUG=true`. With `APP_DEBUG=false`, Laravel returns a generic error page.

---

## 7. Post-Deploy Verification

```bash
# Confirm runtime debug value
php artisan tinker --execute="echo config('app.debug') ? 'DEBUG ON' : 'debug off';"

# Confirm environment
php artisan tinker --execute="echo app()->environment();"

# Tail logs briefly to check for startup errors
tail -f storage/logs/laravel.log
```

---

## 8. Known Issues — Reference

See the e2e audit report for edge cases discovered during testing:

- **W-05:** CSRF 419 stack trace leak — resolved by `APP_DEBUG=false` in production.
  Audit report: `docs/superpowers/plans/` (phase 7 e2e audit plans).

- **Year-transition auth gate:** `/year-transition` must redirect unauthenticated users; verify with smoke test 6.3.

---

## 9. Health Endpoints

Two endpoints are available for monitoring:

### 9.1 `/up` — Laravel built-in (use for Uptime Kuma primary monitor)

Checks that the application boots and the default DB connection is ready.

```bash
curl -s -o /dev/null -w "%{http_code}" https://floz.example.com/up
# Expected: 200
```

### 9.2 `/healthz` — Custom (DB + Redis + queue check)

Returns JSON with per-service status. Use for alerting dashboards.

```bash
curl -s https://floz.example.com/healthz | jq .
# Expected:
# {
#   "status": "ok",
#   "db": "ok",
#   "redis": "ok",
#   "queue": "ok",
#   "timestamp": "2026-05-09T02:00:00+07:00"
# }
```

HTTP 503 means at least one service is degraded — check logs immediately:

```bash
docker compose logs app --tail=50
docker compose logs horizon --tail=20
```

---

## Rollback Procedure

```bash
# 1. Revert to previous release directory (if using releases/current symlink pattern)
# 2. Clear caches
php artisan optimize:clear
# 3. Rollback last migration batch if schema changed
php artisan migrate:rollback
# 4. Restore previous .env if config changed
```
