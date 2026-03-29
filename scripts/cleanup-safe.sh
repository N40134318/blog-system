#!/usr/bin/env bash
set -e

echo "[INFO] remove exited containers"
docker container prune -f

echo "[INFO] remove dangling images"
docker image prune -f

echo "[INFO] remove unused build cache"
docker builder prune -f

echo "[INFO] remove unused networks"
docker network prune -f

echo "[INFO] done"
