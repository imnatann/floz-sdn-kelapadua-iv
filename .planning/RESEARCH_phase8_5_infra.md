# Phase 8.5 Infrastructure Research

**Date:** 2026-05-09
**Domain:** Production operations — backup, deploy, monitoring, worker supervision
**Confidence:** HIGH (all findings verified from codebase; web research for external tools)

---

## 1. Current Docker State

**docker-compose.yml (production)** — 6 services:

| Service | Image | Notes |
|---------|-------|-------|
| `app` | `docker/php/Dockerfile` (PHP 8.3-FPM) | OPcache validate_timestamps=0 (correct for prod) |
| `nginx` | `nginx:1.25-alpine` | Ports 80+443, static asset cache 30d |
| `postgres` | `postgres:16-alpine` | Healthcheck OK, password from `${DB_PASSWORD}` |
| `redis` | `redis:7-alpine` | Healthcheck OK |
| `horizon` | same PHP image | `php artisan horizon` — queue worker |
| `scheduler` | same PHP image | Busy-loop `schedule:run` every 60s |

**docker-compose.dev.yml** — adds `node` (Vite HMR on 5173), exposes Postgres:5432 + Redis:6379.

**Gaps identified:**
- No `reverb` service in prod compose — Reverb runs inside `app` container or needs its own service.
- `scheduler` container uses busy-loop (`while true; do ... sleep 60; done`) — correct workaround for Docker (no host cron), but consumes a container slot.
- `init.sql` creates `floz_tenant_template` database and installs `uuid-ossp`/`pg_trgm` — **stale tenant artifact**; single-school deployment doesn't need `floz_tenant_template`. Not blocking, but wastes resources.
- No named backup volume or bind mount for backup output.
- No resource limits (memory/CPU) on any container — risky on shared VPS.

**Postgres version:** 16-alpine [VERIFIED: docker-compose.yml line 40]

---

## 2. Existing Operational Configs

### Supervisor (`docker/supervisor/supervisord.conf`)
Runs two programs inside the `app` container:
- `[program:horizon]` — `php artisan horizon`, user=floz, autorestart, stopwaitsecs=3600
- `[program:cron]` — `/usr/sbin/cron -f`, user=root

**Gap:** Supervisor conf is baked into the PHP image but the prod compose runs `horizon` as a *separate container* (`floz-horizon`). Supervisor is therefore **unused in prod** — the `app` container only runs PHP-FPM. Supervisord config is dev/legacy artifact; can be repurposed for Reverb worker.

**No Reverb worker in supervisor config.** Reverb must be added.

### Nginx (`docker/nginx/default.conf`)
- Serves on port 80 only (no TLS termination at Nginx layer)
- PHP-FPM upstream: `app:9000`, timeout 120s
- `client_max_body_size 50M` — matches php.ini
- Static asset cache 30d with `immutable` — correct
- **Gap:** No TLS config — expects TLS at host/reverse-proxy level (Nginx or Caddy on the VPS host). This is acceptable for single-server deploy with Let's Encrypt on the host.

### PHP-FPM (`docker/php/Dockerfile` + `php.ini`)
- PHP 8.3-FPM, extensions: pdo_pgsql, redis, gd, intl, opcache, pcntl, bcmath, zip
- `upload_max_filesize=50M`, `memory_limit=256M`, `max_execution_time=120`
- `date.timezone=Asia/Jakarta` — correct for Indonesia
- `opcache.revalidate_freq=0`, `opcache.validate_timestamps=1` in php.ini (dev-safe default)
- Prod compose overrides with `PHP_OPCACHE_VALIDATE_TIMESTAMPS=0` via env — correct, but note php.ini file still says `1`; env var only works if Dockerfile wires it to `opcache.validate_timestamps` dynamically (it doesn't — this is a gap; php.ini should set `validate_timestamps=0` for prod image, or use a prod-specific php.ini).

### Postgres Init (`docker/postgres/init.sql`)
- Creates `floz_tenant_template` + installs uuid-ossp/pg_trgm on it
- **Stale tenant artifact** — safe to ignore or clean up in Phase 8.5

---

## 3. Existing Scripts & Artisan Commands

- **No** `bin/`, `scripts/`, or `deploy/` directory at root [VERIFIED]
- **No** `src/app/Console/Commands/` directory — zero custom Artisan commands [VERIFIED]
- `composer.json` scripts present: `setup`, `dev` (concurrently runs serve+queue+pail+vite), `test`
- **No** backup script, health script, or deploy script anywhere in repo

**Packages relevant to Phase 8.5:**
- `laravel/horizon` ^5.44 [VERIFIED]
- `laravel/reverb` ^1.7 [VERIFIED]
- `spatie/laravel-backup` — **NOT installed** [VERIFIED: not in composer.json]

---

## 4. Health Endpoint Status

Laravel 11's `health: '/up'` is configured in `src/bootstrap/app.php` line 13. [VERIFIED]

The `/up` route returns HTTP 200 if app boots successfully (checks DB connectivity via default health checks). This is sufficient for basic uptime monitoring.

**What `/up` checks by default (Laravel 11):** ApplicationIsRunning (app boots), DatabaseIsReady (default DB connection), RedisIsReady (if Redis configured). [CITED: laravel.com/docs/11.x/configuration#health-check-route]

**Recommendation for Phase 8.5:** `/up` is sufficient. No need for a custom `/healthz` endpoint. Uptime monitor should GET `/up` and expect HTTP 200.

---

## 5. Backup Strategy Recommendations

**Decision: custom `pg_dump` script via Laravel Scheduler, NOT spatie/laravel-backup**

Rationale:
- `spatie/laravel-backup` supports PostgreSQL but adds ~15 package dependencies, requires S3/disk driver config, and the backup UI/notifications add complexity for a 1-person school IT staff.
- A cron-driven `pg_dump` shell script is auditable, dependency-free, and easy to restore from.
- For single-school with one Postgres DB, pg_dump is the correct primitive.

**Backup design:**
```
/var/backups/floz/
  daily/   YYYY-MM-DD.sql.gz   (keep 7)
  weekly/  YYYY-WW.sql.gz      (keep 4)
  monthly/ YYYY-MM.sql.gz      (keep 6)
```

**Schedule:** Laravel Scheduler calls a custom Artisan command `backup:database` at 02:00 Asia/Jakarta daily. The command shells out to `pg_dump` inside the `postgres` container via `docker exec`.

**Offsite:** `rclone` to Google Drive (free 15GB, sufficient for school). Rclone runs on host (not in container). Planner should add `rclone` setup to deploy checklist but make it optional — local-only backup is the minimum viable target.

**Retention script:** Prune logic in the Artisan command (PHP `glob` + `unlink` by date pattern).

---

## 6. Deploy Script Recommendations

**Decision: `deploy.sh` (not Makefile)**

Rationale: School IT staff on Indonesian VPS (likely Ubuntu) will find a plain bash script more accessible than `make`. Makefile adds a dependency and `make` may not be installed on minimal VPS images.

**Deploy steps (in order):**
```bash
git pull origin main
docker compose pull          # pull updated base images if any
docker compose build app     # rebuild PHP image on code change
docker compose up -d         # rolling restart
docker compose exec app composer install --no-dev --optimize-autoloader
docker compose exec app npm ci
docker compose exec app npm run build
docker compose exec app php artisan migrate --force
docker compose exec app php artisan config:cache
docker compose exec app php artisan route:cache
docker compose exec app php artisan view:cache
docker compose exec app php artisan event:cache
docker compose exec app php artisan horizon:terminate  # horizon auto-restarts
docker compose exec app php artisan reverb:restart     # if signal supported
docker compose restart nginx  # reload nginx config if changed
```

**Note:** npm build runs inside `app` container (Node 20 is baked into PHP image). No separate Node container needed for deploy.

---

## 7. Monitoring Recommendations

**Decision: Uptime Kuma (self-hosted on same VPS)**

Rationale for school context:
- UptimeRobot free tier (50 monitors, 5-min interval) is viable but adds external dependency and signup friction for school IT.
- Better Stack: requires account, English UI, overkill.
- **Uptime Kuma**: Docker container, Indonesian-friendly web UI, push/pull monitors, Telegram notifications (WhatsApp-adjacent — school staff use Telegram/WA). One-command install.

```yaml
# Add to docker-compose.yml
uptime-kuma:
  image: louislam/uptime-kuma:1
  container_name: floz-uptime-kuma
  restart: always
  ports:
    - "3001:3001"
  volumes:
    - uptime-kuma-data:/app/data
  networks:
    - floz-network
```

Monitor targets:
1. `http://localhost/up` — Laravel app health (HTTP 200)
2. TCP port 6379 — Redis
3. TCP port 5432 (internal) — Postgres
4. `http://localhost/` — Nginx response

Notification: Telegram bot (free, instant, works on Indonesian mobile networks). [ASSUMED: Telegram is primary for school staff — verify with client]

---

## 8. Supervisor Config Recommendations

Current supervisor conf runs `horizon` + `cron` but is **unused in prod** (horizon runs as separate container). Phase 8.5 should either:

**Option A (recommended):** Keep Docker-native approach — add a `reverb` container to `docker-compose.yml`, parallel to `horizon` container.

```yaml
reverb:
  build:
    context: ./docker
    dockerfile: php/Dockerfile
  container_name: floz-reverb
  restart: always
  working_dir: /var/www/html
  command: php artisan reverb:start --host=0.0.0.0 --port=8080
  ports:
    - "8080:8080"
  volumes:
    - ./src:/var/www/html
  networks:
    - floz-network
  depends_on:
    redis:
      condition: service_healthy
```

Nginx then proxies WebSocket connections to `reverb:8080`.

**Option B:** Consolidate horizon + reverb + scheduler into `app` container via supervisord. Reduces container count but complicates restart granularity.

**Recommendation: Option A.** Independent containers allow `docker compose restart reverb` without touching the app.

**Queue workers:** Horizon manages queue workers internally. Default Horizon config (already in `src/config/horizon.php` if installed) should set `balance=auto`, `minProcesses=1`, `maxProcesses=3` for a single-school load.

---

## 9. Log Rotation

**Current state:**
- Default channel: `stack` → resolves to `single` (from `LOG_STACK` env default)
- `daily` channel configured: `storage/logs/laravel.log`, 14-day retention, level from `LOG_LEVEL` env
- **For production:** set `LOG_CHANNEL=daily` in `.env` — Monolog handles rotation automatically (keeps 14 files by default, configurable via `LOG_DAILY_DAYS`)

**Recommendation:**
- Set `LOG_CHANNEL=daily` and `LOG_DAILY_DAYS=30` in `.env.production`
- Add host-level logrotate config for `./src/storage/logs/*.log` as belt-and-suspenders:

```
/path/to/floz/src/storage/logs/*.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
}
```

No custom rotation script needed — Laravel daily driver + logrotate covers it.

---

## 10. CI Pipeline (Optional)

No `.github/workflows/` directory exists. [VERIFIED]

**Recommended minimal GitHub Actions (`.github/workflows/ci.yml`):**

Triggers: push to `main`, PR to `main`

Jobs:
1. **pest** — `docker compose -f docker-compose.dev.yml run --rm app php artisan test --parallel`
   Or: native PHP 8.3 + pgsql service + `composer install` + `php artisan test`
2. **npm-build** — `node:20`, `npm ci && npm run build`
3. **flutter-analyze** — `flutter analyze` in `floz_mobile/` using `subosito/flutter-action`

Mark pest as required; flutter + npm as advisory (can fail without blocking merge) until test coverage improves.

---

## 11. Concrete File Manifest for Phase 8.5

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Add `reverb` service + `uptime-kuma` service + resource limits |
| `docker/nginx/default.conf` | Add WebSocket proxy for Reverb (`/app`, `/apps`) |
| `deploy.sh` | Root-level deploy script (chmod +x) |
| `src/app/Console/Commands/BackupDatabase.php` | Artisan command: pg_dump + retention prune |
| `src/routes/console.php` | Schedule `backup:database` at 02:00 Asia/Jakarta |
| `docker/logrotate/floz` | Logrotate config for storage/logs |
| `.github/workflows/ci.yml` | Optional CI: pest + npm build + flutter analyze |
| `docs/RUNBOOK.md` | Operations runbook: how to restore backup, restart services, read logs |

**Files to modify:**
| File | Change |
|------|--------|
| `docker/postgres/init.sql` | Remove stale `floz_tenant_template` creation |
| `docker/php/php.ini` | Set `opcache.validate_timestamps=0` for prod image |
| `src/.env.production.example` | Add `LOG_CHANNEL=daily`, `LOG_DAILY_DAYS=30`, `REVERB_*` vars |

---

## 12. Out of Scope (defer)

- Zero-downtime blue-green deploy (requires load balancer or Nginx upstream swap)
- Laravel Octane (requires Swoole/RoadRunner — meaningful change to PHP image)
- Kubernetes / container orchestration
- Multi-region or CDN asset distribution
- Telescope (debug profiler — not for production school server)
- Automated SSL certificate renewal setup (Certbot on host — document in runbook, not scripted)
- `spatie/laravel-backup` integration (custom pg_dump chosen instead)

---

## Sources

- `docker-compose.yml`, `docker-compose.dev.yml` — [VERIFIED: direct file read]
- `docker/supervisor/supervisord.conf` — [VERIFIED]
- `docker/nginx/default.conf` — [VERIFIED]
- `docker/php/Dockerfile`, `docker/php/php.ini` — [VERIFIED]
- `docker/postgres/init.sql` — [VERIFIED]
- `src/bootstrap/app.php` line 13 — [VERIFIED]
- `src/config/logging.php` — [VERIFIED]
- `src/composer.json` — [VERIFIED: horizon ^5.44, reverb ^1.7, no spatie/backup]
- Laravel 11 health route behavior — [CITED: laravel.com/docs/11.x]
- Uptime Kuma — [ASSUMED: suitable for school context; verify Telegram preference with client]
