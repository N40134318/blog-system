# Blog System Deploy Runbook

## 1. 项目结构

- `frontend/`：Nuxt 前端
- `backend/`：Spring Boot 后端
- `deploy/compose.dev.yml`：Dev 环境（测试环境）
- `deploy/compose.prod.yml`：Prod 环境（正式环境）
- `.github/workflows/deploy-dev.yml`：Dev 自动部署 workflow

---

## 2. 环境说明（核心）

### 🌐 Prod（正式环境）

- 域名：`https://preview.rainstorm.space`
- 用途：对外访问
- 前端端口：`3000`
- 后端端口：`8080`
- compose：`compose.prod.yml`

---

### 🧪 Dev（测试环境）

- 域名：`https://dev.rainstorm.space`
- 用途：开发 / 测试 / 调试
- 前端端口：`3001`
- 后端端口：`8081`
- compose：`compose.dev.yml`

---

## 3. Dev 自动部署流程（CI/CD）

GitHub Actions workflow：

- 文件：`.github/workflows/deploy-dev.yml`
- 触发方式：
  - `workflow_dispatch`
  - `push` 到 `main`

流程：

1. GitHub Actions SSH 登录服务器
2. 进入 `/opt/devplatform/projects/blog-system`
3. 拉取最新代码：

```bash
   git fetch origin main
   git reset --hard origin/main
```

4. 启动 Dev 环境：

    ```bash
    docker compose -f deploy/compose.dev.yml up -d --build
    ```


---

## 4. 常用命令

### 查看 Dev 容器

```bash
cd /opt/devplatform/projects/blog-system
docker compose -f deploy/compose.dev.yml ps
```

### 查看 Dev 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f
```

### 查看 backend 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f backend
```

### 查看 frontend 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f frontend
```

### 本地 VM Dev 环境变量

如果 Dev 环境运行在本地 VM，并且需要从宿主机浏览器访问：

```bash
cat >> deploy/.env.dev <<'EOF'
BLOG_DEV_BIND_HOST=0.0.0.0
NUXT_PUBLIC_API_BASE=http://<vm-ip>:8081
APP_CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000,http://127.0.0.1:3001,http://<vm-ip>:3001
EOF
```

说明：

- `BLOG_DEV_BIND_HOST=0.0.0.0`：让前端 `3001` 和后端 `8081` 暴露给宿主机。
- `NUXT_PUBLIC_API_BASE`：让浏览器中的前端请求 VM 后端。
- `APP_CORS_ALLOWED_ORIGINS`：让 Spring Boot 放行前端来源。
- MySQL 和 Redis 仍默认只绑定 `127.0.0.1`，不对宿主机开放。

启动：

```bash
docker compose -f deploy/compose.dev.yml up -d --build
```

如果机器只有旧版 Compose v1，则命令是：

```bash
docker-compose -f deploy/compose.dev.yml up -d --build
```

但 Compose v1 与新 Docker 版本存在兼容风险，优先安装 Compose v2。

---

## 5. 健康检查

### Dev 后端

```bash
curl http://127.0.0.1:8081/actuator/health
```

### Dev 前端

```bash
curl -I http://127.0.0.1:3001
```

### VM 宿主机访问检查

```bash
curl -I http://<vm-ip>:3001
curl http://<vm-ip>:8081/actuator/health
curl 'http://<vm-ip>:8081/api/posts?page=0&size=6&keyword=&sort=latest'
```

---

## 6. Nginx

### 🌐 Prod（preview 域名）

- 域名：`preview.rainstorm.space`
- 前端 → `127.0.0.1:3000`
- API → `127.0.0.1:8080`

---

### 🧪 Dev（dev 域名）

- 域名：`dev.rainstorm.space`
- 前端 → `127.0.0.1:3001`
- API → `127.0.0.1:8081`

---

## 7. Prod 手动发布（当前策略）

```bash
cd /opt/devplatform/projects/blog-system
git pull origin main

docker compose \
  --env-file deploy/.env.prod \
  -f deploy/compose.prod.yml \
  up -d --build
```

---

## 8. GitHub Secrets

Dev workflow 需要：

- `SERVER_HOST`
- `SERVER_PORT`
- `SERVER_USER`
- `SERVER_SSH_KEY`

---

## 9. SSH 说明

### GitHub Actions → 服务器

- 使用独立 SSH 私钥
- 登录用户：`character`

### 服务器 → GitHub

- 使用 deploy key 拉取 `blog-system` 仓库

---

## 10. 权限要求

```bash
chown -R 1000:1000 /opt/devplatform/projects/blog-system
```

说明：

- 保证 code-server / Docker / 部署一致权限
- 避免 node_modules / target 权限问题

## 当前常驻开发环境

运行中的容器：
- blog-frontend-dev
- blog-backend-dev
- blog-redis-dev
- blog-mysql-dev

当前 Dev 关键卷：
- deploy_blog_mysql_data_dev
- deploy_blog_frontend_node_modules_dev
- deploy_blog_frontend_nuxt_dev

历史 MySQL 卷（暂保留，不删除）：
- backend_blog_mysql_data_prod
- blog-backend_blog_mysql_data
- blog-backend_blog_mysql_data_prod

## 环境迁移
见：migration-guide.md

## 数据恢复
见：migration-guide.md
