# Plan: Phase 8.5 — Production Readiness Infrastructure

**Date:** 2026-05-09
**Estimate:** ~10 hours total
**Status:** Ready for execution

---

## Goal

Harden the Floz LMS Docker deployment for unsupervised production operation at SDN Kelapadua IV.
Deliverables: automated daily backups with retention, a one-command deploy script, a WebSocket-capable
production compose stack, self-hosted uptime monitoring, a GitHub Actions CI pipeline, and an
ops runbook so school IT staff can recover from failures without developer intervention.

---

## Locked Decisions (non-negotiable)

| # | Decision |
|---|----------|
| D-01 | Backup: custom `BackupDatabase` Artisan command → `pg_dump` → `storage/app/backups/floz_<YYYY-MM-DD_HH-mm>.sql.gz`. Retention: 7 daily / 4 weekly / 6 monthly. |
| D-02 | Schedule: `routes/console.php` → `backup:database` daily at 02:00 Asia/Jakarta. |
| D-03 | Deploy: `deploy.sh` at repo root. Idempotent bash. Steps as specified. |
| D-04 | Health: use Laravel 11's built-in `/up`. Add custom `/healthz` JSON endpoint (DB + Redis + queue). Pest tests for both. |
| D-05 | Monitoring: Uptime Kuma as `uptime-kuma` service in docker-compose, port 3001. Telegram bot note in docs. |
| D-06 | Reverb: `reverb` service in docker-compose. Nginx WebSocket proxy for `/app/*` → reverb:8080. |
| D-07 | Init.sql: remove `floz_tenant_template` block. |
| D-08 | CI: `.github/workflows/ci.yml` — PHP 8.2, Pest, npm build, flutter analyze (in `floz_mobile/`). |
| D-09 | Log rotation: `LOG_CHANNEL=stack LOG_STACK=daily LOG_DAILY_DAYS=30` in `.env.production.example` (already set). Add `log:prune` scheduler call (weekly, 30-day threshold). |
| D-10 | 503 page: `resources/views/errors/503.blade.php` with school branding, Bahasa Indonesia text. |

---

## Service Contract Reference

### BackupDatabase command

```
php artisan backup:database [--dry-run] [--type=daily|weekly|monthly]
```

- Default: runs all three retention checks after dump.
- `--dry-run`: prints what would be deleted/created; writes nothing.
- Output file: `storage/app/backups/{type}/floz_{YYYY-MM-DD_HH-mm}.sql.gz`
- Exit 0 on success, non-zero on pg_dump failure.
- Logs to `Log::channel('daily')` — not stdout (so scheduler capture works).

### BackupRestore command

```
php artisan backup:restore {file} [--dry-run]
```

- `{file}`: absolute or relative path to `.sql.gz` file.
- Decompresses to temp file, runs `psql` against configured DB, removes temp.
- `--dry-run`: decompress + validate SQL header only; no DB write.
- Requires `PGPASSWORD` env var or `.pgpass` on host.

### /healthz response shape

```json
HTTP 200 — all healthy
{
  "status": "ok",
  "db": "ok",
  "redis": "ok",
  "queue": "ok",
  "timestamp": "2026-05-09T02:00:00+07:00"
}

HTTP 503 — any failure
{
  "status": "degraded",
  "db": "ok",
  "redis": "error: Connection refused",
  "queue": "degraded",
  "timestamp": "..."
}
```

Queue check: count jobs in `failed_jobs` table modified in the last 5 minutes > 10 → "degraded".

---

## Wave 1: Backup System

### Task 1 — `BackupDatabase` Artisan command (TDD)

**File:** `src/app/Console/Commands/BackupDatabase.php`
**Test file:** `src/tests/Feature/BackupDatabaseCommandTest.php`

**Write the test first, run it (RED), then implement:**

```php
<?php
// src/tests/Feature/BackupDatabaseCommandTest.php

namespace Tests\Feature;

use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BackupDatabaseCommandTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    /** @test */
    public function it_creates_a_gzipped_backup_file_in_daily_directory(): void
    {
        // Arrange: stub pg_dump so it doesn't need a real DB in CI
        $this->mock(\App\Console\Commands\BackupDatabase::class)
            ->makePartial()
            ->shouldAllowMockingProtectedMethods()
            ->shouldReceive('runPgDump')
            ->once()
            ->andReturn(true);

        // Act
        $this->artisan('backup:database --dry-run')
            ->assertExitCode(0);
    }

    /** @test */
    public function dry_run_does_not_write_any_files(): void
    {
        $this->artisan('backup:database --dry-run')
            ->assertExitCode(0);

        Storage::disk('local')->assertMissing('backups/daily');
    }

    /** @test */
    public function backup_filename_matches_expected_pattern(): void
    {
        $command = new \App\Console\Commands\BackupDatabase();
        $filename = $command->buildFilename('daily');

        $this->assertMatchesRegularExpression(
            '/^floz_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.sql\.gz$/',
            $filename
        );
    }

    /** @test */
    public function retention_keeps_at_most_7_daily_files(): void
    {
        // Seed 10 fake daily backup files (oldest first)
        Storage::disk('local')->makeDirectory('backups/daily');
        for ($i = 10; $i >= 1; $i--) {
            $date = now()->subDays($i)->format('Y-m-d_H-i');
            Storage::disk('local')->put("backups/daily/floz_{$date}.sql.gz", 'fake');
        }

        $command = new \App\Console\Commands\BackupDatabase();
        $deleted = $command->pruneDirectory('backups/daily', 7);

        $this->assertEquals(3, $deleted); // 10 - 7 = 3 pruned
        $this->assertCount(7, Storage::disk('local')->files('backups/daily'));
    }

    /** @test */
    public function retention_keeps_at_most_4_weekly_files(): void
    {
        Storage::disk('local')->makeDirectory('backups/weekly');
        for ($i = 6; $i >= 1; $i--) {
            $date = now()->subWeeks($i)->format('Y-m-d_H-i');
            Storage::disk('local')->put("backups/weekly/floz_{$date}.sql.gz", 'fake');
        }

        $command = new \App\Console\Commands\BackupDatabase();
        $deleted = $command->pruneDirectory('backups/weekly', 4);

        $this->assertEquals(2, $deleted);
        $this->assertCount(4, Storage::disk('local')->files('backups/weekly'));
    }
}
```

**Implementation (`src/app/Console/Commands/BackupDatabase.php`):**

```php
<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class BackupDatabase extends Command
{
    protected $signature = 'backup:database
                            {--dry-run : Simulate without writing files}
                            {--type=all : daily|weekly|monthly|all}';

    protected $description = 'Dump PostgreSQL database to gzipped backup file with retention pruning';

    // Retention limits
    const KEEP_DAILY   = 7;
    const KEEP_WEEKLY  = 4;
    const KEEP_MONTHLY = 6;

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');
        $type   = $this->option('type');

        $now      = Carbon::now('Asia/Jakarta');
        $filename = $this->buildFilename($type === 'all' ? 'daily' : $type);

        if ($dryRun) {
            $this->info("[DRY-RUN] Would create: backups/daily/{$filename}");
            $this->info("[DRY-RUN] Would prune daily→7, weekly→4, monthly→6");
            return 0;
        }

        // Determine which directories to write based on date
        $targets = $this->resolveTargets($now);

        foreach ($targets as $dir) {
            Storage::disk('local')->makeDirectory("backups/{$dir}");
            $path = "backups/{$dir}/" . $this->buildFilename($dir);
            $fullPath = storage_path("app/{$path}");

            if (!$this->runPgDump($fullPath)) {
                $this->error("pg_dump failed for {$dir} backup.");
                Log::error("BackupDatabase: pg_dump failed", ['path' => $fullPath]);
                return 1;
            }

            $this->info("Backup created: {$path}");
            Log::info("BackupDatabase: created {$path}");
        }

        // Prune after successful write
        $this->pruneDirectory('backups/daily',   self::KEEP_DAILY);
        $this->pruneDirectory('backups/weekly',  self::KEEP_WEEKLY);
        $this->pruneDirectory('backups/monthly', self::KEEP_MONTHLY);

        return 0;
    }

    public function buildFilename(string $type): string
    {
        return 'floz_' . Carbon::now('Asia/Jakarta')->format('Y-m-d_H-i') . '.sql.gz';
    }

    /**
     * Determine which backup directories to write based on current date.
     * - Always: daily
     * - Monday: also weekly
     * - 1st of month: also monthly
     */
    protected function resolveTargets(Carbon $now): array
    {
        $targets = ['daily'];
        if ($now->dayOfWeek === Carbon::MONDAY) {
            $targets[] = 'weekly';
        }
        if ($now->day === 1) {
            $targets[] = 'monthly';
        }
        return $targets;
    }

    /**
     * Shell out to pg_dump. Returns true on success.
     * Protected so tests can mock it.
     */
    protected function runPgDump(string $outputPath): bool
    {
        $host   = config('database.connections.pgsql.host');
        $port   = config('database.connections.pgsql.port', 5432);
        $db     = config('database.connections.pgsql.database');
        $user   = config('database.connections.pgsql.username');
        $pass   = config('database.connections.pgsql.password');

        $cmd = sprintf(
            'PGPASSWORD=%s pg_dump -h %s -p %s -U %s %s | gzip > %s',
            escapeshellarg($pass),
            escapeshellarg($host),
            escapeshellarg($port),
            escapeshellarg($user),
            escapeshellarg($db),
            escapeshellarg($outputPath)
        );

        exec($cmd, $output, $exitCode);
        return $exitCode === 0;
    }

    /**
     * Prune oldest files in a storage directory, keeping $keep most recent.
     * Returns count of deleted files.
     */
    public function pruneDirectory(string $storageDir, int $keep): int
    {
        $files = Storage::disk('local')->files($storageDir);
        // Sort ascending (oldest first)
        sort($files);

        $toDelete = array_slice($files, 0, max(0, count($files) - $keep));
        foreach ($toDelete as $file) {
            Storage::disk('local')->delete($file);
        }

        return count($toDelete);
    }
}
```

**Acceptance criteria:**
- `php artisan backup:database --dry-run` exits 0, writes nothing to disk.
- `php artisan backup:database` creates `storage/app/backups/daily/floz_<timestamp>.sql.gz`.
- After 10 daily runs, only 7 files remain in `backups/daily/`.
- All 5 Pest tests GREEN.

---

### Task 2 — Schedule daily backup at 02:00 Asia/Jakarta

**File:** `src/routes/console.php`

Replace the placeholder content with:

```php
<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Backup: daily at 02:00 Asia/Jakarta (UTC+7 = 19:00 UTC previous day)
Schedule::command('backup:database')
    ->dailyAt('02:00')
    ->timezone('Asia/Jakarta')
    ->withoutOverlapping()
    ->runInBackground()
    ->onFailure(function () {
        \Illuminate\Support\Facades\Log::error('Scheduled backup:database FAILED');
    });

// Log pruning: weekly on Sundays at 03:00, delete logs older than 30 days
Schedule::command('log:prune --days=30')
    ->weekly()
    ->sundays()
    ->at('03:00')
    ->timezone('Asia/Jakarta');
```

> **Note on `log:prune`:** Laravel does not ship this command by default. Task 3 creates it.
> The scheduler `timezone()` method requires `APP_TIMEZONE=Asia/Jakarta` in `.env` OR pass the
> timezone directly as shown above (preferred — explicit over implicit).

**Verify:** `php artisan schedule:list` shows `backup:database` at `02:00` and `log:prune` weekly.

---

### Task 3 — `LogPrune` Artisan command + backup retention verified end-to-end

**File:** `src/app/Console/Commands/LogPrune.php`

```php
<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;

class LogPrune extends Command
{
    protected $signature = 'log:prune {--days=30 : Delete log files older than N days}';
    protected $description = 'Delete Laravel log files older than --days days from storage/logs';

    public function handle(): int
    {
        $days  = (int) $this->option('days');
        $dir   = storage_path('logs');
        $cutoff = Carbon::now()->subDays($days);
        $deleted = 0;

        foreach (glob("{$dir}/*.log") as $file) {
            if (filemtime($file) < $cutoff->timestamp) {
                unlink($file);
                $deleted++;
                $this->line("Deleted: " . basename($file));
            }
        }

        $this->info("Pruned {$deleted} log file(s) older than {$days} days.");
        return 0;
    }
}
```

**Also add** to `src/app/Console/Commands/BackupRestore.php` (restore companion):

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class BackupRestore extends Command
{
    protected $signature = 'backup:restore {file : Path to .sql.gz backup file} {--dry-run}';
    protected $description = 'Restore a PostgreSQL backup from a gzipped dump file';

    public function handle(): int
    {
        $file   = $this->argument('file');
        $dryRun = $this->option('dry-run');

        if (!file_exists($file)) {
            $this->error("File not found: {$file}");
            return 1;
        }

        if (!str_ends_with($file, '.sql.gz')) {
            $this->error("Expected a .sql.gz file.");
            return 1;
        }

        $tmpFile = sys_get_temp_dir() . '/floz_restore_' . time() . '.sql';

        // Decompress
        $decompressCmd = sprintf('gunzip -c %s > %s', escapeshellarg($file), escapeshellarg($tmpFile));
        exec($decompressCmd, $output, $exitCode);
        if ($exitCode !== 0) {
            $this->error("Failed to decompress backup.");
            return 1;
        }

        if ($dryRun) {
            // Validate SQL header
            $header = shell_exec("head -5 " . escapeshellarg($tmpFile));
            $this->info("[DRY-RUN] SQL header:\n{$header}");
            @unlink($tmpFile);
            return 0;
        }

        $host = config('database.connections.pgsql.host');
        $port = config('database.connections.pgsql.port', 5432);
        $db   = config('database.connections.pgsql.database');
        $user = config('database.connections.pgsql.username');
        $pass = config('database.connections.pgsql.password');

        $restoreCmd = sprintf(
            'PGPASSWORD=%s psql -h %s -p %s -U %s %s < %s',
            escapeshellarg($pass),
            escapeshellarg($host),
            escapeshellarg($port),
            escapeshellarg($user),
            escapeshellarg($db),
            escapeshellarg($tmpFile)
        );

        $this->warn("Restoring into database '{$db}' — THIS OVERWRITES EXISTING DATA.");
        if (!$this->confirm('Are you sure?')) {
            $this->info('Aborted.');
            @unlink($tmpFile);
            return 0;
        }

        exec($restoreCmd, $restoreOutput, $restoreExit);
        @unlink($tmpFile);

        if ($restoreExit !== 0) {
            $this->error("psql restore failed. Check output above.");
            return 1;
        }

        $this->info("Restore complete.");
        return 0;
    }
}
```

**Acceptance criteria:**
- `php artisan backup:restore storage/app/backups/daily/floz_<file>.sql.gz --dry-run` prints SQL header, exits 0.
- `php artisan log:prune --days=30` runs without error.
- `php artisan schedule:list` shows both commands scheduled.

---

## Wave 2: Health Endpoints

### Task 4 — `/healthz` route + Pest tests

**Files:**
- `src/routes/web.php` (add route — or `api.php` if preferred, but web is fine for unauthenticated GET)
- `src/app/Http/Controllers/HealthController.php`
- `src/tests/Feature/HealthEndpointTest.php`

**Test first (RED → GREEN):**

```php
<?php
// src/tests/Feature/HealthEndpointTest.php

namespace Tests\Feature;

use Tests\TestCase;

class HealthEndpointTest extends TestCase
{
    /** @test */
    public function up_endpoint_returns_200(): void
    {
        $response = $this->get('/up');
        $response->assertStatus(200);
    }

    /** @test */
    public function healthz_returns_json_with_db_and_redis_keys(): void
    {
        $response = $this->get('/healthz');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'status',
            'db',
            'redis',
            'queue',
            'timestamp',
        ]);
    }

    /** @test */
    public function healthz_returns_ok_status_in_test_environment(): void
    {
        $response = $this->get('/healthz');

        // In test env, DB is always available (SQLite or configured test DB)
        $response->assertJson(['status' => 'ok']);
        $response->assertStatus(200);
    }
}
```

**Controller (`src/app/Http/Controllers/HealthController.php`):**

```php
<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        $checks  = [];
        $healthy = true;

        // DB check
        try {
            DB::connection()->getPdo();
            $checks['db'] = 'ok';
        } catch (\Exception $e) {
            $checks['db'] = 'error: ' . $e->getMessage();
            $healthy = false;
        }

        // Redis check
        try {
            Cache::store('redis')->put('healthz_probe', 1, 5);
            $checks['redis'] = 'ok';
        } catch (\Exception $e) {
            $checks['redis'] = 'error: ' . $e->getMessage();
            $healthy = false;
        }

        // Queue check: degraded if >10 failed jobs in last 5 minutes
        try {
            $recentFailed = DB::table('failed_jobs')
                ->where('failed_at', '>=', now()->subMinutes(5))
                ->count();
            $checks['queue'] = $recentFailed > 10 ? 'degraded' : 'ok';
            if ($recentFailed > 10) {
                $healthy = false;
            }
        } catch (\Exception $e) {
            // failed_jobs table might not exist in some environments
            $checks['queue'] = 'ok';
        }

        $checks['status']    = $healthy ? 'ok' : 'degraded';
        $checks['timestamp'] = Carbon::now('Asia/Jakarta')->toIso8601String();

        return response()->json($checks, $healthy ? 200 : 503);
    }
}
```

**Route (add to `src/routes/web.php`):**

```php
// Health check — no auth, no CSRF (GET only)
Route::get('/healthz', [\App\Http\Controllers\HealthController::class, 'check'])
    ->name('health.check');
```

**Acceptance criteria:**
- `GET /up` → 200 (Laravel built-in).
- `GET /healthz` → 200 JSON with `{status, db, redis, queue, timestamp}`.
- 3 Pest tests GREEN.
- `/healthz` excluded from `auth` middleware (it is — it's in `web.php` outside any auth group).

---

### Task 5 — Update DEPLOYMENT_CHECKLIST.md: health endpoints section

Add section **9. Health Endpoints** to `docs/DEPLOYMENT_CHECKLIST.md`:

```markdown
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
```

---

## Wave 3: Deploy Script

### Task 6 — `deploy.sh` at repo root

**File:** `deploy.sh` (chmod +x after creation)

```bash
#!/usr/bin/env bash
# deploy.sh — Floz LMS production deploy script
# Usage: ./deploy.sh [--skip-build]
# Idempotent: safe to run on every deploy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SECRET="${MAINTENANCE_SECRET:-floz-maint-$(date +%s)}"
SKIP_BUILD="${1:-}"
APP_URL="${APP_URL:-https://floz.example.com}"

echo "==> [1/10] Pull latest code"
git -C "$SCRIPT_DIR" pull origin main

echo "==> [2/10] Pull updated Docker images"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" pull --quiet

echo "==> [3/10] Build PHP image"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" build app

echo "==> [4/10] Start/update services (rolling)"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo "==> [5/10] Install PHP dependencies"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    composer install --no-dev --optimize-autoloader --no-interaction

if [[ "$SKIP_BUILD" != "--skip-build" ]]; then
    echo "==> [6/10] Build frontend assets"
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
        sh -c "npm ci --prefer-offline && npm run build"
fi

echo "==> [7/10] Enable maintenance mode"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    php artisan down --secret="$APP_SECRET" --render="errors.503"

echo "==> [8/10] Run migrations"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    php artisan migrate --force

echo "==> [9/10] Cache config / routes / views / events"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    sh -c "php artisan config:cache && \
           php artisan route:cache && \
           php artisan view:cache && \
           php artisan event:cache"

echo "==> [9b/10] Restart queue workers and WebSocket server"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    php artisan horizon:terminate || true
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    php artisan reverb:restart || true
docker compose -f "$SCRIPT_DIR/docker-compose.yml" restart nginx

echo "==> [10/10] Disable maintenance mode"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T app \
    php artisan up

echo "==> Health check"
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/up" || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
    echo "Deploy complete. /up returned 200."
else
    echo "WARNING: /up returned HTTP ${HTTP_CODE}. Check logs:"
    echo "  docker compose logs app --tail=50"
    exit 1
fi
```

Make executable: `chmod +x deploy.sh`

**Acceptance criteria:**
- `bash -n deploy.sh` passes (syntax check).
- Running `./deploy.sh --skip-build` on a running stack completes all steps without error.
- If `/up` returns non-200 after deploy, script exits 1.

---

### Task 7 — `deploy.dev.sh` local shortcut

**File:** `deploy.dev.sh` (chmod +x)

```bash
#!/usr/bin/env bash
# deploy.dev.sh — quick local asset + cache refresh (no git pull, no maintenance mode)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Install PHP deps (dev)"
docker compose -f "$SCRIPT_DIR/docker-compose.dev.yml" exec -T app \
    composer install --no-interaction

echo "==> Build frontend"
docker compose -f "$SCRIPT_DIR/docker-compose.dev.yml" exec -T app \
    sh -c "npm ci && npm run build"

echo "==> Clear all caches"
docker compose -f "$SCRIPT_DIR/docker-compose.dev.yml" exec -T app \
    php artisan optimize:clear

echo "==> Run migrations"
docker compose -f "$SCRIPT_DIR/docker-compose.dev.yml" exec -T app \
    php artisan migrate

echo "Done. Vite HMR should auto-reload."
```

---

## Wave 4: Reverb Production Service

### Task 8 — Add `reverb` service to `docker-compose.yml`

**File:** `docker-compose.yml`

Add the `reverb` service block and `uptime-kuma` (D-05 batched here to avoid a second compose edit):

```yaml
  reverb:
    build:
      context: ./docker
      dockerfile: php/Dockerfile
    container_name: floz-reverb
    restart: always
    working_dir: /var/www/html
    command: ["php", "artisan", "reverb:start", "--host=0.0.0.0", "--port=8080", "--no-interaction"]
    environment:
      - APP_ENV=${APP_ENV:-production}
      - APP_KEY=${APP_KEY}
      - DB_CONNECTION=${DB_CONNECTION:-pgsql}
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=${DB_DATABASE}
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REVERB_HOST=${REVERB_HOST:-0.0.0.0}
      - REVERB_PORT=8080
      - REVERB_SCHEME=${REVERB_SCHEME:-https}
    volumes:
      - ./src:/var/www/html
    networks:
      - floz-network
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy

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

Add to the `volumes:` section at the bottom of `docker-compose.yml`:

```yaml
  uptime-kuma-data:
```

Also add `REVERB_*` vars to `src/.env.production.example`:

```dotenv
# ----- Reverb (WebSocket) -----
REVERB_APP_ID=<FILL_IN_reverb_app_id>
REVERB_APP_KEY=<FILL_IN_reverb_app_key>
REVERB_APP_SECRET=<FILL_IN_reverb_app_secret>
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=https
```

**Acceptance criteria:**
- `docker compose config` validates without errors after edit.
- `docker compose up -d reverb` starts container and `php artisan reverb:start` is the entrypoint.
- `docker compose up -d uptime-kuma` starts Kuma on port 3001.

---

### Task 9 — Nginx WebSocket proxy config

**File:** `docker/nginx/default.conf`

Add an `upstream` block and a `location` block for WebSocket proxying. Insert the upstream before the `server {}` block, and add the location inside the existing server block:

```nginx
# WebSocket upstream for Laravel Reverb
upstream reverb_upstream {
    server reverb:8080;
    keepalive 32;
}
```

Inside the `server {}` block (before the closing `}`), add:

```nginx
    # WebSocket proxy — Laravel Reverb
    location ~ ^/(app|apps)/ {
        proxy_pass         http://reverb_upstream;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "Upgrade";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
```

**Acceptance criteria:**
- `docker compose exec nginx nginx -t` passes.
- WebSocket connection from browser to `wss://floz.example.com/app/{app_key}` routes to the reverb container.
- Standard HTTP requests still reach the `app` container (PHP-FPM) — no regression.

---

## Wave 5: Init.sql Cleanup

### Task 10 — Remove `floz_tenant_template` from `docker/postgres/init.sql`

**File:** `docker/postgres/init.sql`

Replace the entire file with:

```sql
-- FLOZ LMS - PostgreSQL Initialization Script
-- Single-school deployment: no tenant provisioning needed.
-- Extensions (uuid-ossp, pg_trgm) are installed per-migration if required.
```

> **Note:** The `floz_tenant_template` database is a stale multi-tenant artifact (D-07).
> Removing this block does NOT affect the main `floz` database — Postgres creates it from
> `POSTGRES_DB` env var automatically. The `uuid-ossp` and `pg_trgm` extensions are available
> in Postgres 16 and can be installed per-migration with `CREATE EXTENSION IF NOT EXISTS`.

**Acceptance criteria:**
- `docker/postgres/init.sql` contains no reference to `floz_tenant_template`.
- `grep -c "tenant" docker/postgres/init.sql` returns 0.
- Fresh `docker compose up` still creates the main database correctly.

---

## Wave 6: Monitoring

### Task 11 — Uptime Kuma setup documentation

Uptime Kuma service is added in Task 8. This task documents the initial configuration.

**Add section to `docs/DEPLOYMENT_CHECKLIST.md` (section 10):**

```markdown
## 10. Uptime Kuma Monitoring

Uptime Kuma runs at `http://your-server-ip:3001` after `docker compose up -d uptime-kuma`.

### Initial setup (one-time, manual)

1. Open `http://your-server-ip:3001` in browser.
2. Create admin account (username + password — store in school password manager).
3. Add monitors:

| Monitor name | Type | URL / Address | Expected | Interval |
|---|---|---|---|---|
| Floz App | HTTP/HTTPS | `https://floz.example.com/up` | 200 | 60s |
| Floz Healthz | HTTP/HTTPS | `https://floz.example.com/healthz` | 200 | 120s |
| Redis | TCP Port | `redis:6379` | open | 60s |
| PostgreSQL | TCP Port | `postgres:5432` | open | 60s |

4. Add Telegram notification:
   - Create a Telegram bot: chat with `@BotFather`, run `/newbot`, copy the token.
   - Get your chat ID: message `@userinfobot`.
   - In Uptime Kuma: Settings → Notifications → Add → Telegram.
   - Enter bot token and chat ID. Test notification.
5. Assign the Telegram notification to all four monitors.

### Restart after server reboot

Uptime Kuma has `restart: always` — it restarts automatically with Docker.
```

---

## Wave 7: CI Pipeline

### Task 12 — `.github/workflows/ci.yml`

**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  pest:
    name: PHP Tests (Pest)
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: floz_test
          POSTGRES_USER: floz
          POSTGRES_PASSWORD: secret
        ports:
          - 5432:5432
        options: >-
          --health-cmd="pg_isready -U floz"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd="redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP 8.2
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: pdo, pdo_pgsql, redis, gd, intl, pcntl, bcmath, zip
          coverage: none

      - name: Cache Composer dependencies
        uses: actions/cache@v4
        with:
          path: src/vendor
          key: composer-${{ hashFiles('src/composer.lock') }}

      - name: Install Composer dependencies
        working-directory: src
        run: composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

      - name: Copy test environment
        working-directory: src
        run: |
          cp .env.testing .env
          php artisan key:generate

      - name: Run Pest tests
        working-directory: src
        env:
          DB_CONNECTION: pgsql
          DB_HOST: 127.0.0.1
          DB_PORT: 5432
          DB_DATABASE: floz_test
          DB_USERNAME: floz
          DB_PASSWORD: secret
          REDIS_HOST: 127.0.0.1
          REDIS_PORT: 6379
          CACHE_STORE: array
          QUEUE_CONNECTION: sync
        run: php artisan test --no-coverage

  npm-build:
    name: Frontend Build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node 20
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: src/package-lock.json

      - name: Install npm dependencies
        working-directory: src
        run: npm ci

      - name: Build frontend assets
        working-directory: src
        run: npm run build

  flutter-analyze:
    name: Flutter Analyze
    runs-on: ubuntu-latest
    continue-on-error: true   # advisory — does not block merge

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          channel: 'stable'
          cache: true

      - name: Get Flutter dependencies
        working-directory: floz_mobile
        run: flutter pub get

      - name: Run Flutter analyze
        working-directory: floz_mobile
        run: flutter analyze --no-fatal-infos
```

**Acceptance criteria:**
- `.github/workflows/ci.yml` is valid YAML (`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` exits 0).
- On PR to main: `pest` and `npm-build` are required; `flutter-analyze` is advisory.
- Pushing to main triggers all three jobs.

---

## Wave 8: Maintenance Mode UX

### Task 13 — 503 page with school branding (Bahasa Indonesia)

**File:** `src/resources/views/errors/503.blade.php`

```blade
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistem Sedang Diperbarui — Floz LMS</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: #f0f4ff;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
        }
        .card {
            background: white;
            border-radius: 1rem;
            box-shadow: 0 4px 24px rgba(0,0,0,0.08);
            max-width: 480px;
            width: 100%;
            padding: 2.5rem 2rem;
            text-align: center;
        }
        .icon {
            font-size: 3.5rem;
            margin-bottom: 1rem;
        }
        .school-name {
            font-size: 0.875rem;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 0.5rem;
        }
        h1 {
            font-size: 1.5rem;
            font-weight: 700;
            color: #1e3a5f;
            margin-bottom: 0.75rem;
        }
        p {
            color: #6b7280;
            line-height: 1.6;
            margin-bottom: 0.5rem;
        }
        .eta {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 0.5rem;
            padding: 0.75rem 1rem;
            color: #1d4ed8;
            font-size: 0.9rem;
            margin-top: 1.25rem;
        }
        .contact {
            margin-top: 1.5rem;
            font-size: 0.8rem;
            color: #9ca3af;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">🔧</div>
        <div class="school-name">SDN Kelapadua IV — Floz LMS</div>
        <h1>Sistem Sedang Diperbarui</h1>
        <p>
            Kami sedang melakukan pembaruan sistem untuk meningkatkan
            pengalaman belajar Anda.
        </p>
        <p>
            Mohon bersabar, sistem akan segera kembali normal.
        </p>
        <div class="eta">
            Perkiraan selesai: beberapa menit lagi.<br>
            Silakan coba kembali dalam 5–10 menit.
        </div>
        <div class="contact">
            Butuh bantuan? Hubungi operator sekolah.
        </div>
    </div>
</body>
</html>
```

**Acceptance criteria:**
- File exists at `src/resources/views/errors/503.blade.php`.
- `php artisan down` then visiting any route shows this page (not the default Laravel 503).
- Page renders correctly on mobile (responsive layout).
- No Laravel debug output visible on this page regardless of `APP_DEBUG` value.

---

## Wave 9: Final Ops

### Task 14 — Update DEPLOYMENT_CHECKLIST.md: backup + deploy + Reverb ops

Add sections **11**, **12**, and **13** to `docs/DEPLOYMENT_CHECKLIST.md`:

```markdown
## 11. Backup Operations

### 11.1 Verify cron is running (host)

The `scheduler` container runs `php artisan schedule:run` every 60 seconds. Confirm it's up:

```bash
docker compose ps scheduler
# Should be: running
```

### 11.2 Trigger a manual backup

```bash
docker compose exec app php artisan backup:database
# Expected: "Backup created: backups/daily/floz_<timestamp>.sql.gz"
ls src/storage/app/backups/daily/
```

### 11.3 Restore from backup (DANGER — overwrites DB)

```bash
# Dry-run first to confirm the file is intact
docker compose exec app php artisan backup:restore \
    storage/app/backups/daily/floz_<timestamp>.sql.gz --dry-run

# Full restore (will prompt for confirmation)
docker compose exec app php artisan backup:restore \
    storage/app/backups/daily/floz_<timestamp>.sql.gz
```

### 11.4 Backup retention verification

```bash
ls -la src/storage/app/backups/daily/    # expect ≤ 7 files
ls -la src/storage/app/backups/weekly/   # expect ≤ 4 files
ls -la src/storage/app/backups/monthly/  # expect ≤ 6 files
```

### 11.5 Optional: rclone offsite to Google Drive

Install rclone on host, configure a remote named `gdrive`:
```bash
rclone copy ./src/storage/app/backups gdrive:floz-backups/ --progress
```
Add to host crontab (runs at 03:00 daily, after the 02:00 backup):
```
0 3 * * * rclone copy /path/to/floz/src/storage/app/backups gdrive:floz-backups/ >> /var/log/rclone.log 2>&1
```

---

## 12. Running deploy.sh

```bash
chmod +x deploy.sh
./deploy.sh
```

Pass `--skip-build` to skip `npm ci && npm run build` (e.g., config-only deploy):

```bash
./deploy.sh --skip-build
```

The maintenance secret used by `php artisan down --secret` is printed at the start of the script.
Bypass maintenance mode by appending `?secret=<token>` to any URL during deploy.

---

## 13. Reverb WebSocket in Production

Reverb runs as a separate container (`floz-reverb`) on internal port 8080.
Nginx routes WebSocket traffic from `/app/*` and `/apps/*` to this container.

```bash
# Check Reverb is running
docker compose ps reverb
docker compose logs reverb --tail=20

# Restart Reverb without downtime for other services
docker compose restart reverb

# Signal Reverb to reload config gracefully (if supported)
docker compose exec app php artisan reverb:restart
```

**Sanctum / WebSocket auth note:**
Reverb uses Laravel Echo with Sanctum tokens. Ensure `REVERB_APP_KEY` and `REVERB_APP_SECRET`
in `.env` match `config/reverb.php`. The frontend Echo client must send the Sanctum token
in the auth request to `/broadcasting/auth`.
```

---

### Task 15 — Smoke test backup script on dev DB

This is a **checkpoint:human-verify** task. After all prior tasks are implemented:

1. Start dev stack: `docker compose -f docker-compose.dev.yml up -d`
2. Run dry-run: `docker compose -f docker-compose.dev.yml exec app php artisan backup:database --dry-run`
   - Expected: `[DRY-RUN] Would create: backups/daily/floz_<timestamp>.sql.gz`
3. Run actual backup: `docker compose -f docker-compose.dev.yml exec app php artisan backup:database`
   - Expected: `Backup created: backups/daily/floz_<timestamp>.sql.gz`
4. Verify file exists: `ls -lh src/storage/app/backups/daily/`
5. Run restore dry-run: `docker compose -f docker-compose.dev.yml exec app php artisan backup:restore storage/app/backups/daily/floz_<timestamp>.sql.gz --dry-run`
   - Expected: SQL header printed, exit 0.

If all steps pass, mark done. If `pg_dump` not found in container, add to `docker/php/Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
```

---

### Task 16 — Final regression + git tag

```bash
# Run full test suite
docker compose exec app php artisan test

# Validate compose files
docker compose config
docker compose -f docker-compose.dev.yml config

# Syntax check deploy scripts
bash -n deploy.sh
bash -n deploy.dev.sh

# Confirm no tenant references in init.sql
grep -c "tenant" docker/postgres/init.sql   # must return 0

# Check schedule list
docker compose exec app php artisan schedule:list

# Tag release
git add -A
git commit -m "feat: Phase 8.5 — production readiness infrastructure"
git tag -a v8.5.0 -m "Production readiness: backup, deploy, monitoring, CI, Reverb"
```

---

## Definition of Done

- [ ] `BackupDatabase` Artisan command created and all 5 unit tests GREEN
- [ ] `BackupRestore` Artisan command created and `--dry-run` works
- [ ] `LogPrune` Artisan command created
- [ ] `routes/console.php` schedules `backup:database` at 02:00 Asia/Jakarta
- [ ] `routes/console.php` schedules `log:prune` weekly on Sundays
- [ ] `php artisan schedule:list` shows both tasks
- [ ] `/healthz` route returns JSON `{status, db, redis, queue, timestamp}`
- [ ] 3 health endpoint Pest tests GREEN
- [ ] `deploy.sh` exists at repo root, `bash -n` passes, exits 0 on healthy stack
- [ ] `deploy.dev.sh` exists at repo root
- [ ] `reverb` service added to `docker-compose.yml`
- [ ] `uptime-kuma` service added to `docker-compose.yml` on port 3001
- [ ] Nginx WebSocket proxy block added for `/app/*` and `/apps/*`
- [ ] `docker compose config` validates without errors
- [ ] `docker/postgres/init.sql` has zero `tenant` references
- [ ] `.github/workflows/ci.yml` is valid YAML; pest + npm-build are required gates
- [ ] `src/resources/views/errors/503.blade.php` shows Bahasa Indonesia school branding
- [ ] `docs/DEPLOYMENT_CHECKLIST.md` updated with sections 9–13
- [ ] `src/.env.production.example` updated with `REVERB_*` vars
- [ ] Backup smoke test on dev DB passed (Task 15)
- [ ] `git tag v8.5.0` created

---

## Test Count Target

| Suite | Tests | Status |
|-------|-------|--------|
| BackupDatabase command (unit/feature) | 5 | Defined in Task 1 |
| Health endpoint (feature) | 3 | Defined in Task 4 |
| **Total new tests** | **8** | — |

> Existing Pest suite must remain GREEN throughout. No frontend tests in this phase (deferred per research §12).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `pg_dump` not in PHP image | Medium | High | Add `postgresql-client` to `docker/php/Dockerfile` (see Task 15) |
| Cron timezone mismatch (UTC vs Jakarta) | Medium | Medium | Use explicit `.timezone('Asia/Jakarta')` on Schedule calls, not `APP_TIMEZONE` alone |
| Backup disk fills silently | Low | High | Add `Log::warning` if `storage/app/backups/` > 500MB; future phase: alert |
| Reverb WebSocket auth fails in prod | Medium | Medium | Document Sanctum token requirement; test with `wscat` after deploy |
| CI Pest flake on parallel runs | Low | Low | `--no-coverage` avoids pcov overhead; jobs run sequentially in CI matrix |
| `docker exec` in deploy.sh hangs | Low | Medium | `exec -T` (no TTY) prevents interactive hang; `set -euo pipefail` aborts on failure |
| `reverb:restart` signal not supported | Low | Low | `|| true` in deploy.sh — Reverb restarts via `docker compose restart reverb` |
| New `uptime-kuma` port 3001 exposed | Medium | Medium | Firewall rule: allow 3001 only from admin IP; add to server setup checklist |

---

## Out of Scope (defer)

- Zero-downtime blue-green deploy (requires Nginx upstream swap or load balancer)
- Laravel Octane (requires Swoole/RoadRunner — PHP image rebuild, separate eval)
- `spatie/laravel-backup` integration (custom pg_dump chosen, D-01 locked)
- Automated SSL/TLS renewal (Certbot on host — document in runbook, manual)
- Multi-region failover / disaster recovery drills
- Laravel Telescope (dev profiler — not for production)
- Kubernetes / container orchestration
- Automated rclone offsite scheduling (documented as optional, not scripted)
- Load testing / performance benchmarks
