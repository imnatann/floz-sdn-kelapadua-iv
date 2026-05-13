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
