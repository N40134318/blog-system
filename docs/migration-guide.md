# 📦 Blog System Migration & Env Tools 使用说明

> 更新时间：2026-03-31 02:40

---

# 🧭 一、整体目标

本工具体系用于实现：

- ✅ 环境迁移（dev / prod）
- ✅ 数据库迁移（MySQL dump）
- ✅ 上传文件迁移（uploads）
- ✅ 项目配置迁移（deploy / scripts / docs）
- ✅ 一键恢复运行环境
- ✅ 一键切换运行环境（dev / prod）

---

# 🏗️ 二、整体流程

源机器
  ↓ package-migration.sh
迁移包 (.tar.gz)
  ↓ 传输
目标机器
  ↓ restore-migration.sh
恢复环境
  ↓ switch-env.sh
切换运行环境

---

# 📦 三、打包脚本：package-migration.sh

## 📍 作用

在源机器执行，生成迁移包：

```bash
./package-migration.sh
```

---

## 📁 输出结构

```
blog-system-migration-xxxx/
├── data/
│   ├── blogdb-dev.sql.gz
│   └── blogdb-prod.sql.gz
├── uploads/
├── project/
│   ├── deploy/
│   ├── scripts/
│   ├── docs/
│   └── .github/
├── nginx/
├── state/
└── MIGRATION_README.md
```

---

## ⚙️ 内容说明

| 项目 | 内容 |
|------|------|
| MySQL | mysqldump 导出 |
| uploads | 文件复制 |
| project | 配置 + 脚本 |
| nginx | 反代配置 |
| state | docker 状态 |

---

## ⚠️ 注意

- 包含 `.env`（敏感信息）
- 禁止提交 git
- 仅用于可信环境

---

# 🚀 四、恢复脚本：restore-migration.sh

## 📍 用法

```bash
./restore-migration.sh /path/to/migration.tar.gz
```

---

## 🧩 恢复流程

1. 解压迁移包
2. 恢复项目
3. 恢复 uploads
4. 启动 MySQL / Redis
5. 重建数据库
6. 导入 SQL
7. 启动全部服务
8. 健康检查

---

## 🎯 成功标准

- DB 有数据
- backend health = UP
- frontend 可访问
- 图片加载正常

---

# 🔁 五、环境切换脚本：switch-env.sh

## 📍 用法

```bash
bash scripts/switch-env.sh dev
bash scripts/switch-env.sh prod
bash scripts/switch-env.sh status
```

---

## 🧠 功能说明

| 命令 | 作用 |
|------|------|
| dev | 启动 dev + 切 nginx |
| prod | 启动 prod + 切 nginx |
| status | 查看状态 |

---

## 🔄 执行逻辑

### dev

1. 停 prod
2. 启动 dev
3. 等 backend ready
4. 等 frontend ready
5. 切 nginx
6. reload nginx

---

### prod

1. 停 dev
2. 启动 prod
3. 等 backend ready
4. 切 nginx
5. reload nginx

---

# 🌐 六、nginx 配置说明

目录：

```
/opt/devplatform/nginx/
```

文件：

- blog.dev.conf
- blog.prod.conf
- blog.conf（当前生效）

---

## 🔁 切换方式

```bash
cp blog.dev.conf blog.conf
docker exec blog-nginx nginx -s reload
```

---

# ⚠️ 七、常见问题

## ❌ Docker 拉镜像失败

原因：网络问题

解决：

```bash
docker pull maven:3.9.9-eclipse-temurin-21
docker pull node:22-bookworm
```

---

## ❌ 502 Bad Gateway

```bash
docker logs blog-nginx
docker logs blog-backend-dev
```

---

## ❌ 数据为空

```sql
SELECT COUNT(*) FROM post;
```

---

## ❌ 图片不显示

```bash
chown -R 1000:1000 /opt/devplatform/uploads
```

---

# 🔐 八、安全

- 包含数据库
- 包含 env
- 禁止公网传播

---

# 🧠 九、设计原则

1. 数据与容器解耦
2. 可重复恢复
3. 环境隔离
4. 可观测性

---

# 🚀 十、总结

👉 当前系统已实现：

- 可迁移
- 可恢复
- 可切换
- 可验证

---

> 这标志着系统已进入工程化阶段（DevOps 基础能力）
