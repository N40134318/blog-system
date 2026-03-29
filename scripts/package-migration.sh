#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/opt/devplatform/projects/blog-system"
BACKUP_ROOT="/opt/devplatform/backups/migration"
TS="$(date +%F_%H-%M-%S)"
PKG_DIR="$BACKUP_ROOT/blog-system-migration-$TS"
ARCHIVE="$BACKUP_ROOT/blog-system-migration-$TS.tar.gz"

MYSQL_CONTAINER_DEV="blog-mysql-dev"
MYSQL_CONTAINER_PROD="blog-mysql-prod"

DEV_ENV_FILE="$PROJECT_DIR/deploy/.env.dev"
PROD_ENV_FILE="$PROJECT_DIR/deploy/.env.prod"

UPLOADS_DIR="/opt/devplatform/uploads"
NGINX_DIR="/etc/nginx/conf.d"

mkdir -p "$PKG_DIR/project"
mkdir -p "$PKG_DIR/nginx"
mkdir -p "$PKG_DIR/state"
mkdir -p "$PKG_DIR/data"
mkdir -p "$PKG_DIR/uploads"

echo "[INFO] package dir: $PKG_DIR"

echo "[INFO] copy project files"
cp -a "$PROJECT_DIR/deploy" "$PKG_DIR/project/" 2>/dev/null || true
cp -a "$PROJECT_DIR/docs" "$PKG_DIR/project/" 2>/dev/null || true
cp -a "$PROJECT_DIR/scripts" "$PKG_DIR/project/" 2>/dev/null || true
cp -a "$PROJECT_DIR/.github" "$PKG_DIR/project/" 2>/dev/null || true
cp -a "$PROJECT_DIR/README.md" "$PKG_DIR/project/" 2>/dev/null || true
cp -a "$PROJECT_DIR/.gitignore" "$PKG_DIR/project/" 2>/dev/null || true

echo "[INFO] export nginx conf"
sudo cp -a "$NGINX_DIR/dev.rainstorm.space.conf" "$PKG_DIR/nginx/" 2>/dev/null || true
sudo cp -a "$NGINX_DIR/preview.rainstorm.space.conf" "$PKG_DIR/nginx/" 2>/dev/null || true

echo "[INFO] collect docker state"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$PKG_DIR/state/docker-ps.txt" || true
docker volume ls > "$PKG_DIR/state/docker-volume-ls.txt" || true
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}" > "$PKG_DIR/state/docker-images.txt" || true

docker inspect blog-mysql-dev > "$PKG_DIR/state/blog-mysql-dev.inspect.json" 2>/dev/null || true
docker inspect blog-mysql-prod > "$PKG_DIR/state/blog-mysql-prod.inspect.json" 2>/dev/null || true
docker inspect blog-frontend-dev > "$PKG_DIR/state/blog-frontend-dev.inspect.json" 2>/dev/null || true
docker inspect blog-frontend-prod > "$PKG_DIR/state/blog-frontend-prod.inspect.json" 2>/dev/null || true

echo "[INFO] export mysql dumps if container exists"

if docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER_DEV}$"; then
  if [ -f "$DEV_ENV_FILE" ]; then
    set -o allexport
    source "$DEV_ENV_FILE"
    set +o allexport
    DEV_MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"
    if [ -n "${DEV_MYSQL_ROOT_PASSWORD:-}" ]; then
      docker exec "$MYSQL_CONTAINER_DEV" sh -c "exec mysqldump -uroot -p${DEV_MYSQL_ROOT_PASSWORD} --databases blogdb" \
        | gzip > "$PKG_DIR/data/blogdb-dev.sql.gz"
    fi
  fi
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER_PROD}$"; then
  if [ -f "$PROD_ENV_FILE" ]; then
    set -o allexport
    source "$PROD_ENV_FILE"
    set +o allexport
    PROD_MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"
    if [ -n "${PROD_MYSQL_ROOT_PASSWORD:-}" ]; then
      docker exec "$MYSQL_CONTAINER_PROD" sh -c "exec mysqldump -uroot -p${PROD_MYSQL_ROOT_PASSWORD} --databases blogdb" \
        | gzip > "$PKG_DIR/data/blogdb-prod.sql.gz"
    fi
  fi
fi

echo "[INFO] copy uploads"
if [ -d "$UPLOADS_DIR" ]; then
  cp -a "$UPLOADS_DIR/." "$PKG_DIR/uploads/" || true
fi

echo "[INFO] write migration notes"
cat > "$PKG_DIR/MIGRATION_README.md" <<'EOF'
# Blog System Migration Package

## Included
- project/deploy
- project/docs
- project/scripts
- project/.github
- nginx configs
- docker runtime state
- mysql dumps
- uploads

## Restore outline
1. Prepare Docker / Docker Compose on target machine
2. Clone repository or copy project files
3. Restore deploy configs and env files
4. Restore nginx configs and certificates manually
5. Restore uploads to target path
6. Start mysql container first
7. Import sql dump
8. Start app containers
9. Verify nginx reverse proxy and domain resolution

## Security notes
- This package may contain sensitive env files
- Store it only in trusted locations
- Do not commit this package or extracted files into git
- Do not share it through public channels

## Notes
- This package does not include SSL cert private deployment automation
- This package does not directly copy docker volumes
- MySQL is migrated by dump/import, which is safer across machines
EOF

echo "[INFO] create archive"
tar -czf "$ARCHIVE" -C "$BACKUP_ROOT" "blog-system-migration-$TS"

echo "[INFO] done"
echo "[INFO] archive: $ARCHIVE"
