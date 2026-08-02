# Blog System Ops Troubleshooting

## 1. Flyway 启动失败

### 现象
应用启动时卡在 Flyway，或迁移报错。

### 原因
项目最初不是完整 Flyway 管理，后续才补迁移脚本，导致历史表结构与迁移版本不完全一致。

### 处理
- 新建 `V1__init.sql`，按当前数据库真实结构初始化
- 历史补丁脚本重命名为 `DISABLED_V2...` 等，避免重复执行
- 保证数据库表结构与 `V1__init.sql` 一致

---

## 2. `/actuator/health` 连接被重置

### 现象
```bash
curl http://127.0.0.1:8080/actuator/health
````

返回 connection reset。

### 原因

后端容器还没真正启动完成，或启动过程中异常退出。

### 排查

```bash
docker compose -f compose.prod.yml ps
docker compose -f compose.prod.yml logs --tail=200 backend
```

---

## 3. Git safe.directory 提示

### 现象

VS Code / code-server 提示：

- repository is potentially unsafe
- folder is owned by someone other than the current user

### 原因

IDE 在容器里运行，Git 检查的是容器内路径，不是宿主机路径。

### 处理

在 IDE 容器终端执行：

```bash
git config --global --add safe.directory /config/workspace
git config --global --add safe.directory /config/workspace/blog-system
git config --global --add safe.directory /config/workspace/blog-system/frontend
git config --global --add safe.directory /config/workspace/blog-system/backend
```

---

## 4. code-server 无法新建文件夹

### 现象

报错：

```bash
EACCES: permission denied, mkdir ...
```

### 原因

挂载目录宿主机权限与容器内 UID/GID 不一致。

### 处理

宿主机执行：

```bash
chown -R 1000:1000 /opt/devplatform/projects/blog-system
find /opt/devplatform/projects/blog-system -type d -exec chmod 755 {} \;
find /opt/devplatform/projects/blog-system -type f -exec chmod 644 {} \;
find /opt/devplatform/projects/blog-system -name "mvnw" -exec chmod 755 {} \;
```

---

## 5. GitHub Actions SSH 登录服务器失败

### 现象

workflow 报错：

```bash
ssh: handshake failed
unable to authenticate
```

### 原因

- GitHub Secrets 私钥错误
- 服务器 `authorized_keys` 未正确写入
- 用户名、端口错误

### 处理

确认：

- `SERVER_HOST`
- `SERVER_PORT`
- `SERVER_USER`
- `SERVER_SSH_KEY`

并在服务器手动验证：

```bash
ssh -i ~/.ssh/github_actions_to_server -p <port> character@127.0.0.1 'echo ok'
```

---

## 6. 服务器无法 `git pull`

### 现象

报错：

```bash
Permission denied (publickey)
```

### 原因

服务器到 GitHub 的 deploy key 未配置成功。

### 处理

- 为仓库添加 deploy key
- 开启 write access（如果需要 push）
- 在服务器 `~/.ssh/config` 指定仓库 key

---

## 7. `.git/FETCH_HEAD Permission denied`

### 原因

仓库目录属主不一致，当前部署用户无写权限。

### 处理

```bash
chown -R character:character /opt/devplatform/projects/blog-system
```

或统一到容器/部署用户的 UID/GID。

---

## 8. root 无法 SSH

### 原因

sshd 配置禁止 root 登录：

```bash
PermitRootLogin no
```

### 处理

使用普通用户 `character` 登录。

---

## 9. 前端 `Failed to fetch` 后端 API

### 现象

浏览器页面提示类似：

```text
[GET] "http://<vm-ip>:8081/api/posts?...": <no response> Failed to fetch
```

### 原因

前端和后端运行在不同端口，例如：

- Frontend: `http://<vm-ip>:3001`
- Backend: `http://<vm-ip>:8081`

浏览器会按跨源请求处理，需要后端返回 CORS 响应头。

### 处理

在 `deploy/.env.dev` 中配置：

```env
NUXT_PUBLIC_API_BASE=http://<vm-ip>:8081
APP_CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000,http://127.0.0.1:3001,http://<vm-ip>:3001
```

然后重启后端：

```bash
docker compose -f deploy/compose.dev.yml restart backend
```

验证：

```bash
curl -I -H 'Origin: http://<vm-ip>:3001' 'http://<vm-ip>:8081/api/posts?page=0&size=6&keyword=&sort=latest'
```

响应头中应包含 `Access-Control-Allow-Origin`。

---

## 10. PNPM 11 拦截依赖构建脚本

### 现象

前端 Docker 构建时报错：

```text
[ERR_PNPM_IGNORED_BUILDS] Ignored build scripts: @parcel/watcher, esbuild
```

### 原因

新版本 pnpm 默认会限制依赖安装脚本。Nuxt/Vite 相关依赖可能需要运行
`esbuild`、`@parcel/watcher` 的安装脚本。

### 处理

仓库中提供 `frontend/pnpm-workspace.yaml`，并让 Dockerfile 在安装前复制它：

```dockerfile
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* ./
```

当前 dev 迁移实验为了先跑通本地 VM，使用：

```yaml
dangerouslyAllowAllBuilds: true
```

生产化前建议锁定 pnpm 版本，并改回更精确的允许列表。

---

## 11. Docker Compose v1 `ContainerConfig` 报错

### 现象

使用 Ubuntu 源中的 `docker-compose` v1，并搭配较新的 Docker Engine 时，
重建容器可能报错：

```text
KeyError: 'ContainerConfig'
```

### 原因

`docker-compose` v1 已停止演进，和新 Docker 镜像/Engine 元数据存在兼容问题。

### 处理

优先安装并使用 Docker Compose v2：

```bash
docker compose version
docker compose -f deploy/compose.dev.yml up -d --build
```

如果短期只能使用 Compose v1，可先移除需要重建的旧容器再启动：

```bash
docker rm -f blog-backend-dev blog-frontend-dev
docker-compose -f deploy/compose.dev.yml up -d --build
```

注意：不要删除 MySQL volume，避免丢失数据。

