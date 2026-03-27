# Blog System Deploy Runbook

## 1. 项目结构

- `frontend/`：Nuxt 前端
- `backend/`：Spring Boot 后端
- `deploy/compose.dev.yml`：preview 环境 compose
- `.github/workflows/deploy-preview.yml`：preview 自动部署 workflow

---

## 2. Preview 环境

- 域名：`https://preview.rainstorm.space`
- 用途：预览环境 / 自动部署测试环境
- 部署目录：`/opt/devplatform/projects/blog-system`
- 反代目标：`127.0.0.1:8081`

---

## 3. Prod 环境

- 域名：`https://dev.rainstorm.space`
- 用途：当前正式对外环境
- 前端端口：`3000`
- 后端端口：`8080`

---

## 4. Preview 自动部署流程

GitHub Actions workflow：

- 文件：`.github/workflows/deploy-preview.yml`
- 触发方式：
  - `workflow_dispatch`
  - `push` 到 `main`

流程：

1. GitHub Actions SSH 登录服务器
2. 进入 `/opt/devplatform/projects/blog-system`
3. `git pull origin main`
4. `docker compose -f deploy/compose.dev.yml up -d --build`

---

## 5. 常用命令

### 查看 preview 容器

```bash
cd /opt/devplatform/projects/blog-system
docker compose -f deploy/compose.dev.yml ps
````

### 查看 preview 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f
```

### 只看 backend 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f backend
```

### 只看 frontend 日志

```bash
docker compose -f deploy/compose.dev.yml logs -f frontend
```

---

## 6. 健康检查

### 后端健康检查

```bash
curl http://127.0.0.1:8080/actuator/health
```

### 前端本地检查

```bash
curl -I http://127.0.0.1:3000
```

---

## 7. Nginx

### Preview

- 域名：`preview.rainstorm.space`
- 反代到：`127.0.0.1:8081`

### Prod

- 域名：`dev.rainstorm.space`
- 前端反代到：`127.0.0.1:3000`
- 后端 API 反代到：`127.0.0.1:8080`

---

## 8. GitHub Secrets

preview workflow 需要：

- `SERVER_HOST`
- `SERVER_PORT`
- `SERVER_USER`
- `SERVER_SSH_KEY`

---

## 9. SSH 相关

### GitHub Actions -> 服务器

使用单独 SSH 私钥登录服务器用户 `character`

### 服务器 -> GitHub 仓库

服务器本机通过 deploy key 拉取 `blog-system` 仓库代码

---

## 10. 权限要求

项目目录需要保证部署用户可写：

```bash
chown -R 1000:1000 /opt/devplatform/projects/blog-system
```

如果 code-server 容器内用户 UID/GID 为 `1000:1000`，这样能保证 IDE 与服务器部署一致。
