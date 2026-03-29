#!/usr/bin/env bash
set -e

echo "===== RUNNING CONTAINERS ====="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo
echo "===== ALL CONTAINERS ====="
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo
echo "===== VOLUMES ====="
docker volume ls

echo
echo "===== IMAGES ====="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}"

echo
echo "===== MYSQL DEV MOUNTS ====="
docker inspect blog-mysql-dev --format '{{json .Mounts}}' 2>/dev/null || echo "blog-mysql-dev not found"

echo
echo "===== MYSQL PROD MOUNTS ====="
docker inspect blog-mysql-prod --format '{{json .Mounts}}' 2>/dev/null || echo "blog-mysql-prod not found"

echo
echo "===== FRONTEND DEV MOUNTS ====="
docker inspect blog-frontend-dev --format '{{json .Mounts}}' 2>/dev/null || echo "blog-frontend-dev not found"

echo
echo "===== FRONTEND PROD MOUNTS ====="
docker inspect blog-frontend-prod --format '{{json .Mounts}}' 2>/dev/null || echo "blog-frontend-prod not found"

echo
echo "===== RESTART POLICIES ====="
docker inspect -f '{{.Name}} -> {{.HostConfig.RestartPolicy.Name}}' $(docker ps -aq) 2>/dev/null || true
