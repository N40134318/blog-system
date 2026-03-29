#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/blog-system-migration-xxxx.tar.gz"
  exit 1
fi

ARCHIVE_PATH="$1"

PROJECT_DIR="/opt/devplatform/projects/blog-system"
BACKUP_ROOT="/opt/devplatform/backups/migration/restore-tmp"
UPLOADS_DIR="/opt/devplatform/uploads"

mkdir -p "$BACKUP_ROOT"
mkdir -p "$(dirname "$PROJECT_DIR")"
mkdir -p "$UPLOADS_DIR"

echo "[INFO] archive: $ARCHIVE_PATH"

if [ ! -f "$ARCHIVE_PATH" ]; then
  echo "[ERROR] archive not found: $ARCHIVE_PATH"
  exit 1
fi

echo "[INFO] extract archive"
tar -xzf "$ARCHIVE_PATH" -C "$BACKUP_ROOT"

EXTRACT_DIR="$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name 'blog-system-migration-*' | sort | tail -n 1)"

if [ -z "${EXTRACT_DIR:-}" ] || [ ! -d "$EXTRACT_DIR" ]; then
  echo "[ERROR] extracted directory not found"
  exit 1
fi

echo "[INFO] extracted dir: $EXTRACT_DIR"

echo "[INFO] ensure project dir exists"
mkdir -p "$PROJECT_DIR"

echo "[INFO] restore project files"
cp -a "$EXTRACT_DIR/project/." "$PROJECT_DIR/" 2>/dev/null || true

echo "[INFO] restore uploads"
cp -a "$EXTRACT_DIR/uploads/." "$UPLOADS_DIR/" 2>/dev/null || true

echo "[INFO] check docker availability"
docker version >/dev/null
docker compose version >/dev/null

echo "[INFO] choose target environment"
echo "1) dev"
echo "2) prod"
read -r -p "Select environment [1/2]: " ENV_CHOICE

TARGET_ENV=""
COMPOSE_FILE=""
ENV_FILE=""
MYSQL_CONTAINER=""
MYSQL_PASSWORD=""
BACKEND_HEALTH_URL=""
FRONTEND_URL=""
SQL_DUMP=""

if [ "$ENV_CHOICE" = "1" ]; then
  TARGET_ENV="dev"
  COMPOSE_FILE="$PROJECT_DIR/deploy/compose.dev.yml"
  ENV_FILE="$PROJECT_DIR/deploy/.env.dev"
  MYSQL_CONTAINER="blog-mysql-dev"
  BACKEND_HEALTH_URL="http://127.0.0.1:8081/actuator/health"
  FRONTEND_URL="http://127.0.0.1:3001"
  SQL_DUMP="$EXTRACT_DIR/data/blogdb-dev.sql.gz"
  echo "[INFO] restore dev environment"
elif [ "$ENV_CHOICE" = "2" ]; then
  TARGET_ENV="prod"
  COMPOSE_FILE="$PROJECT_DIR/deploy/compose.prod.yml"
  ENV_FILE="$PROJECT_DIR/deploy/.env.prod"
  MYSQL_CONTAINER="blog-mysql-prod"
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health"
  FRONTEND_URL="http://127.0.0.1:3000"
  SQL_DUMP="$EXTRACT_DIR/data/blogdb-prod.sql.gz"
  echo "[INFO] restore prod environment"
else
  echo "[ERROR] invalid choice"
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "[ERROR] compose file not found: $COMPOSE_FILE"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] env file not found: $ENV_FILE"
  exit 1
fi

set -o allexport
source "$ENV_FILE"
set +o allexport

MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

if [ -z "${MYSQL_PASSWORD:-}" ]; then
  echo "[ERROR] MYSQL_ROOT_PASSWORD not found in $ENV_FILE"
  exit 1
fi

echo "[INFO] start mysql and redis first"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d mysql redis

echo "[INFO] wait for mysql container"
for i in {1..60}; do
  if docker ps --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}$"; then
    break
  fi
  sleep 2
done

if ! docker ps --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}$"; then
  echo "[ERROR] mysql container not running: $MYSQL_CONTAINER"
  exit 1
fi

echo "[INFO] wait for mysql ready"
for i in {1..60}; do
  if docker exec "$MYSQL_CONTAINER" mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker exec "$MYSQL_CONTAINER" mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; then
  echo "[ERROR] mysql is not ready"
  exit 1
fi

echo "[INFO] import sql dump if exists"
if [ -f "$SQL_DUMP" ]; then
  gzip -cd "$SQL_DUMP" | docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_PASSWORD"
  echo "[INFO] sql import done"
else
  echo "[WARN] sql dump not found: $SQL_DUMP"
fi

echo "[INFO] start full application stack"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build

echo "[INFO] wait for backend health"
for i in {1..60}; do
  if curl -fsS "$BACKEND_HEALTH_URL" >/dev/null; then
    break
  fi
  sleep 2
done

echo "[INFO] wait for frontend"
for i in {1..60}; do
  if curl -fsSI "$FRONTEND_URL" >/dev/null; then
    break
  fi
  sleep 2
done

echo "[INFO] backend final check"
curl -fsS "$BACKEND_HEALTH_URL" || true

echo "[INFO] frontend final check"
curl -fsSI "$FRONTEND_URL" || true

echo "[INFO] running containers"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "[INFO] restore finished"
echo "[WARN] nginx config, ssl certs, domain dns, github secrets and deploy keys still need manual verification"
