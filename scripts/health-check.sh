#!/usr/bin/env bash
set -e

ENV="$1"

if [ "$ENV" = "dev" ]; then
  BACKEND="http://127.0.0.1:8081/actuator/health"
  FRONTEND="http://127.0.0.1:3001"
elif [ "$ENV" = "prod" ]; then
  BACKEND="http://127.0.0.1:8080/actuator/health"
  FRONTEND="http://127.0.0.1:3000"
else
  echo "Usage: $0 dev|prod"
  exit 1
fi

echo "[INFO] check backend"
curl -fsS "$BACKEND" || echo "[ERROR] backend failed"

echo "[INFO] check frontend"
curl -fsSI "$FRONTEND" || echo "[WARN] frontend failed"

echo "[INFO] done"
