#!/usr/bin/env bash
set -e

PROJECT_DIR="/opt/devplatform/projects/blog-system"
COMPOSE_FILE="$PROJECT_DIR/deploy/compose.dev.yml"

echo "[INFO] Start deploy..."

cd "$PROJECT_DIR"

echo "[INFO] Pull latest code..."
git pull origin main

echo "[INFO] Build blog-system..."
docker compose -f "$COMPOSE_FILE" build

echo "[INFO] Restart blog-system..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[INFO] Done"
