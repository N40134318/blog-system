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

````

---

# 第四步：保存后提交

在 monorepo 根目录执行：

```bash
cd /config/workspace/blog-system
git status
git add docs/deploy-runbook.md docs/ops-troubleshooting.md
git commit -m "docs: add deploy runbook and troubleshooting notes"
git push
````
