#!/usr/bin/env bash
set -e

echo "[INFO] Start prod deploy..."

cd /opt/devplatform/projects/blog-system

echo "[INFO] Pull latest code..."
git pull origin main

echo "[INFO] Stop old prod stack..."
docker compose --env-file deploy/.env.prod -f deploy/compose.prod.yml down || true

echo "[INFO] Start new prod stack..."
docker compose --env-file deploy/.env.prod -f deploy/compose.prod.yml up -d --build

echo "[INFO] Wait backend health..."
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:8080/actuator/health; then
    break
  fi
  sleep 2
done

echo "[INFO] Check backend..."
curl -fsS http://127.0.0.1:8080/actuator/health

echo "[INFO] Check frontend..."
curl -fsSI http://127.0.0.1:3000

echo "[INFO] Prod deploy success"
