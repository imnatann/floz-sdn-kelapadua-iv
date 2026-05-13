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
