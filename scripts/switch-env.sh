#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/opt/devplatform/projects/blog-system"
NGINX_CONTAINER="blog-nginx"
NGINX_DIR="/opt/devplatform/nginx"

usage() {
  echo "Usage:"
  echo "  $0 dev"
  echo "  $0 prod"
  echo "  $0 status"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

TARGET="${1:-}"

DEV_COMPOSE="$PROJECT_DIR/deploy/compose.dev.yml"
PROD_COMPOSE="$PROJECT_DIR/deploy/compose.prod.yml"
DEV_ENV="$PROJECT_DIR/deploy/.env.dev"
PROD_ENV="$PROJECT_DIR/deploy/.env.prod"

DEV_BACKEND_HEALTH="http://127.0.0.1:8081/actuator/health"
DEV_FRONTEND_URL="http://127.0.0.1:3001"

PROD_BACKEND_HEALTH="http://127.0.0.1:8080/actuator/health"
PROD_FRONTEND_URL="http://127.0.0.1:3000"

DEV_NGINX_CONF="$NGINX_DIR/blog.dev.conf"
PROD_NGINX_CONF="$NGINX_DIR/blog.prod.conf"
ACTIVE_NGINX_CONF="$NGINX_DIR/blog.conf"

docker version >/dev/null
docker compose version >/dev/null

require_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "[ERROR] file not found: $f"
    exit 1
  fi
}

container_running() {
  local name="$1"
  docker ps --format '{{.Names}}' | grep -q "^${name}$"
}

wait_http_ok() {
  local url="$1"
  local label="$2"
  local tries="${3:-90}"

  for i in $(seq 1 "$tries"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "[ERROR] ${label} not ready: $url"
  return 1
}

wait_http_head_ok() {
  local url="$1"
  local label="$2"
  local tries="${3:-90}"

  for i in $(seq 1 "$tries"); do
    if curl -fsSI "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "[ERROR] ${label} not ready: $url"
  return 1
}

show_status() {
  echo "[INFO] docker containers"
  docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  echo
  echo "[INFO] env health summary"

  if curl -fsS "$DEV_BACKEND_HEALTH" >/dev/null 2>&1; then
    echo "dev backend   : UP    ($DEV_BACKEND_HEALTH)"
  else
    echo "dev backend   : DOWN  ($DEV_BACKEND_HEALTH)"
  fi

  if curl -fsSI "$DEV_FRONTEND_URL" >/dev/null 2>&1; then
    echo "dev frontend  : UP    ($DEV_FRONTEND_URL)"
  else
    echo "dev frontend  : DOWN  ($DEV_FRONTEND_URL)"
  fi

  if curl -fsS "$PROD_BACKEND_HEALTH" >/dev/null 2>&1; then
    echo "prod backend  : UP    ($PROD_BACKEND_HEALTH)"
  else
    echo "prod backend  : DOWN  ($PROD_BACKEND_HEALTH)"
  fi

  if curl -fsSI "$PROD_FRONTEND_URL" >/dev/null 2>&1; then
    echo "prod frontend : UP    ($PROD_FRONTEND_URL)"
  else
    echo "prod frontend : DOWN  ($PROD_FRONTEND_URL)"
  fi

  echo
  echo "[INFO] active nginx config link target"
  if [ -f "$ACTIVE_NGINX_CONF" ]; then
    ls -l "$ACTIVE_NGINX_CONF" || true
  else
    echo "[WARN] $ACTIVE_NGINX_CONF not found"
  fi
}

ensure_nginx_container() {
  if ! container_running "$NGINX_CONTAINER"; then
    echo "[ERROR] nginx container not running: $NGINX_CONTAINER"
    exit 1
  fi
}

switch_nginx_conf() {
  local conf_src="$1"
  local env_name="$2"

  require_file "$conf_src"
  ensure_nginx_container

  echo "[INFO] switch nginx to $env_name"
  cp "$conf_src" "$ACTIVE_NGINX_CONF"

  echo "[INFO] test nginx config"
  docker exec "$NGINX_CONTAINER" nginx -t

  echo "[INFO] reload nginx"
  docker exec "$NGINX_CONTAINER" nginx -s reload
}

stop_env() {
  local env_name="$1"

  if [ "$env_name" = "dev" ]; then
    if [ -f "$DEV_ENV" ] && [ -f "$DEV_COMPOSE" ]; then
      echo "[INFO] stop dev environment"
      docker compose --env-file "$DEV_ENV" -f "$DEV_COMPOSE" down || true
    fi
  elif [ "$env_name" = "prod" ]; then
    if [ -f "$PROD_ENV" ] && [ -f "$PROD_COMPOSE" ]; then
      echo "[INFO] stop prod environment"
      docker compose --env-file "$PROD_ENV" -f "$PROD_COMPOSE" down || true
    fi
  fi
}

start_dev() {
  require_file "$DEV_ENV"
  require_file "$DEV_COMPOSE"
  require_file "$DEV_NGINX_CONF"

  echo "[INFO] stop prod first"
  stop_env "prod"

  echo "[INFO] start dev environment"
  docker compose --env-file "$DEV_ENV" -f "$DEV_COMPOSE" up -d --build

  echo "[INFO] wait for dev backend ready"
  wait_http_ok "$DEV_BACKEND_HEALTH" "dev backend"

  echo "[INFO] wait for dev frontend ready"
  wait_http_head_ok "$DEV_FRONTEND_URL" "dev frontend"

  switch_nginx_conf "$DEV_NGINX_CONF" "dev"

  echo "[INFO] verify target services"
  curl -fsS "$DEV_BACKEND_HEALTH" >/dev/null
  curl -fsSI "$DEV_FRONTEND_URL" >/dev/null

  echo "[INFO] nginx switched to dev"
  echo "[INFO] backend: $DEV_BACKEND_HEALTH"
  echo "[INFO] frontend: $DEV_FRONTEND_URL"
}

start_prod() {
  require_file "$PROD_ENV"
  require_file "$PROD_COMPOSE"
  require_file "$PROD_NGINX_CONF"

  echo "[INFO] stop dev first"
  stop_env "dev"

  echo "[INFO] ensure target services running"
  docker compose --env-file "$PROD_ENV" -f "$PROD_COMPOSE" up -d

  echo "[INFO] wait for backend ready"
  wait_http_ok "$PROD_BACKEND_HEALTH" "prod backend"

  echo "[INFO] verify frontend"
  wait_http_head_ok "$PROD_FRONTEND_URL" "prod frontend"

  switch_nginx_conf "$PROD_NGINX_CONF" "prod"

  echo "[INFO] nginx switched to prod"
  echo "[INFO] backend: $PROD_BACKEND_HEALTH"
  echo "[INFO] frontend: $PROD_FRONTEND_URL"
}

case "$TARGET" in
  dev)
    start_dev
    ;;
  prod)
    start_prod
    ;;
  status)
    show_status
    ;;
  *)
    usage
    ;;
esac
