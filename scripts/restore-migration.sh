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
TMP_PROJECT_RESTORE="/tmp/blog-system-project-restore"

mkdir -p "$BACKUP_ROOT"
mkdir -p "$(dirname "$PROJECT_DIR")"
mkdir -p "$UPLOADS_DIR"
mkdir -p "$TMP_PROJECT_RESTORE"

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

echo "[INFO] restore project files except current restore script"
cp -a "$EXTRACT_DIR/project/." "$TMP_PROJECT_RESTORE/" 2>/dev/null || true

# 不覆盖当前正在执行的 restore 脚本
rm -f "$TMP_PROJECT_RESTORE/scripts/restore-migration.sh" 2>/dev/null || true

cp -a "$TMP_PROJECT_RESTORE/." "$PROJECT_DIR/" 2>/dev/null || true

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
BACKEND_CONTAINER=""
FRONTEND_CONTAINER=""
BACKEND_HEALTH_URL=""
FRONTEND_URL=""
SQL_DUMP=""

if [ "$ENV_CHOICE" = "1" ]; then
  TARGET_ENV="dev"
  COMPOSE_FILE="$PROJECT_DIR/deploy/compose.dev.yml"
  ENV_FILE="$PROJECT_DIR/deploy/.env.dev"
  MYSQL_CONTAINER="blog-mysql-dev"
  BACKEND_CONTAINER="blog-backend-dev"
  FRONTEND_CONTAINER="blog-frontend-dev"
  BACKEND_HEALTH_URL="http://127.0.0.1:8081/actuator/health"
  FRONTEND_URL="http://127.0.0.1:3001"
  SQL_DUMP="$EXTRACT_DIR/data/blogdb-dev.sql.gz"
  echo "[INFO] restore dev environment"
elif [ "$ENV_CHOICE" = "2" ]; then
  TARGET_ENV="prod"
  COMPOSE_FILE="$PROJECT_DIR/deploy/compose.prod.yml"
  ENV_FILE="$PROJECT_DIR/deploy/.env.prod"
  MYSQL_CONTAINER="blog-mysql-prod"
  BACKEND_CONTAINER="blog-backend-prod"
  FRONTEND_CONTAINER="blog-frontend-prod"
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

MYSQL_ROOT_PASSWORD="$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" | cut -d= -f2- || true)"
MYSQL_DATABASE="$(grep '^MYSQL_DATABASE=' "$ENV_FILE" | cut -d= -f2- || true)"
MYSQL_USER="$(grep '^MYSQL_USER=' "$ENV_FILE" | cut -d= -f2- || true)"
MYSQL_PASSWORD="$(grep '^MYSQL_PASSWORD=' "$ENV_FILE" | cut -d= -f2- || true)"

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
  echo "[ERROR] MYSQL_ROOT_PASSWORD not found in $ENV_FILE"
  exit 1
fi

if [ -z "${MYSQL_DATABASE:-}" ]; then
  echo "[ERROR] MYSQL_DATABASE not found in $ENV_FILE"
  exit 1
fi

if [ "$TARGET_ENV" = "prod" ]; then
  echo "[INFO] ensure external mysql volume exists"
  if ! docker volume inspect backend_blog_mysql_data_prod >/dev/null 2>&1; then
    docker volume create backend_blog_mysql_data_prod >/dev/null
    echo "[INFO] created volume: backend_blog_mysql_data_prod"
  else
    echo "[INFO] volume already exists: backend_blog_mysql_data_prod"
  fi
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
  if docker exec "$MYSQL_CONTAINER" mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --silent >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker exec "$MYSQL_CONTAINER" mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --silent >/dev/null 2>&1; then
  echo "[ERROR] mysql is not ready"
  docker logs --tail 200 "$MYSQL_CONTAINER" || true
  exit 1
fi

echo "[INFO] import sql dump if exists"
if [ -f "$SQL_DUMP" ]; then
  gzip -cd "$SQL_DUMP" | docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD"
  echo "[INFO] sql import done"
else
  echo "[WARN] sql dump not found: $SQL_DUMP"
fi

if [ -n "${MYSQL_USER:-}" ] && [ -n "${MYSQL_PASSWORD:-}" ]; then
  echo "[INFO] ensure app mysql user exists and has privileges"
  docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
  echo "[INFO] mysql user/grants ensured"
fi

echo "[INFO] start full application stack"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build

echo "[INFO] wait for backend health"
for i in {1..90}; do
  if curl -fsS "$BACKEND_HEALTH_URL" >/dev/null; then
    break
  fi
  sleep 2
done

if ! curl -fsS "$BACKEND_HEALTH_URL" >/dev/null; then
  echo "[ERROR] backend health check failed"
  docker logs --tail 200 "$BACKEND_CONTAINER" || true
  docker logs --tail 100 "$MYSQL_CONTAINER" || true
  exit 1
fi

echo "[INFO] wait for frontend"
for i in {1..90}; do
  if curl -fsSI "$FRONTEND_URL" >/dev/null; then
    break
  fi
  sleep 2
done

if ! curl -fsSI "$FRONTEND_URL" >/dev/null; then
  echo "[WARN] frontend http check failed"
  docker logs --tail 200 "$FRONTEND_CONTAINER" || true
fi

echo "[INFO] backend final check"
curl -fsS "$BACKEND_HEALTH_URL" || true

echo "[INFO] frontend final check"
curl -fsSI "$FRONTEND_URL" || true

echo "[INFO] running containers"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "[INFO] restore finished"
echo "[WARN] nginx config, ssl certs, domain dns, github secrets and deploy keys still need manual verification if needed"
