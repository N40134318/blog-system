# 🚀 Blog System

> 工程化个人博客系统（持续迭代中）

一个基于 **Nuxt3 + Spring Boot + MySQL + Redis + Docker**
的全栈博客系统，支持 Dev / Prod
环境隔离、自动部署、数据迁移与基础运维能力。

------------------------------------------------------------------------

## ✨ 当前能力

-   ✅ 前后端分离（Nuxt3 + Spring Boot）
-   ✅ Docker Compose 一键运行
-   ✅ Dev / Prod 双环境隔离
-   ✅ GitHub Actions 自动部署（Dev）
-   ✅ 手动发布（Prod）
-   ✅ MySQL 数据持久化
-   ✅ 文件上传（uploads 持久化）
-   ✅ 一键迁移（打包 / 恢复）
-   ✅ 部署冲突保护（Prod 运行时阻止 Dev 覆盖）

------------------------------------------------------------------------

## 🏗️ 技术栈

  层         技术
  ---------- -------------------------
  Frontend   Nuxt3 + Vue3 + PNPM
  Backend    Spring Boot
  Database   MySQL 8
  Cache      Redis
  Deploy     Docker + Docker Compose
  CI/CD      GitHub Actions
  Proxy      Nginx

------------------------------------------------------------------------

## 🧭 架构说明

👉 详细架构文档：

-   [📦 Architecture Overview](docs/architecture-overview.md)

------------------------------------------------------------------------

## ⚙️ 本地开发

### 1️⃣ 启动 Backend

``` bash
cd backend
./mvnw spring-boot:run
```

### 2️⃣ 启动 Frontend

``` bash
cd frontend
pnpm install
pnpm dev
```

### 3️⃣ 访问

-   Frontend: http://localhost:3000
-   Backend: http://localhost:8080

------------------------------------------------------------------------

## 🐳 Docker 运行

### Dev 环境

``` bash
docker compose -f deploy/compose.dev.yml up -d --build
```

-   Frontend: http://127.0.0.1:3001
-   Backend: http://127.0.0.1:8081

### Prod 环境

``` bash
docker compose --env-file deploy/.env.prod -f deploy/compose.prod.yml up -d --build
```

-   Frontend: http://127.0.0.1:3000
-   Backend: http://127.0.0.1:8080

------------------------------------------------------------------------

## 🚀 部署（CI/CD）

### Dev（自动）

-   push 到 `main`
-   自动触发 `deploy-dev.yml`
-   若 Prod 正在运行 → 自动跳过

### Prod（手动）

GitHub Actions 手动执行：

    Deploy Prod

行为：

-   停止 Dev
-   启动 Prod
-   健康检查

------------------------------------------------------------------------

## 🔄 环境切换策略

  场景               行为
  ------------------ --------------
  push main          自动部署 Dev
  Prod 正在运行      Dev 自动跳过
  手动 Deploy Prod   自动停止 Dev

------------------------------------------------------------------------

## 📦 数据与存储

-   MySQL：Docker Volume 持久化
-   Uploads：`/opt/devplatform/uploads`
-   Redis：当前仅缓存（无持久化）

------------------------------------------------------------------------

## 🔁 数据迁移

### 打包

``` bash
scripts/package-migration.sh
```

### 恢复

``` bash
scripts/restore-migration.sh <archive>
```

------------------------------------------------------------------------

## 🛠️ 运维工具

-   `scripts/check-environment.sh` → 环境检查
-   `scripts/cleanup-safe.sh` → 安全清理
-   `scripts/package-migration.sh` → 打包
-   `scripts/restore-migration.sh` → 恢复
-   `scripts/switch-env.sh` → 环境切换
-   `scripts/health-check.sh` → 健康检查

------------------------------------------------------------------------

## 🔙 回滚

### 回滚代码

``` bash
git fetch --tags
git reset --hard <tag>
```

### 回滚容器

``` bash
# dev
docker compose -f deploy/compose.dev.yml up -d --build

# prod
docker compose --env-file deploy/.env.prod -f deploy/compose.prod.yml up -d --build
```

⚠️ 数据库需手动恢复

------------------------------------------------------------------------

## 🏷️ 版本策略

-   `v1.0.0` → 初始可运行版本
-   `v1.1.0` → 部署体系稳定
-   `v1.x.x` → 持续演进

------------------------------------------------------------------------

## 📌 当前阶段

👉 已进入：

**工程化部署阶段（CI/CD + 环境隔离 + 迁移能力）**

------------------------------------------------------------------------

## 🔮 后续规划

-   Redis 持久化（AOF）
-   数据库权限拆分（不再使用 root）
-   零停机部署（blue/green）
-   监控与告警（Prometheus / Grafana）
-   多环境（staging / preview）
-   自动备份与恢复策略

------------------------------------------------------------------------

## 📚 Documentation

-   [📦 Architecture Overview](docs/architecture-overview.md)
-   [🔁 Migration Guide](docs/migration-guide.md)
-   [🛠️ Runbook](docs/runbook.md)
-   [📘 Stage Summary](docs/stage-summary.md)

------------------------------------------------------------------------

## 👤 Author

个人项目 / 持续演进中 🚀

------------------------------------------------------------------------

## ⭐ 备注

这是一个以"工程能力提升"为核心目标的项目，
不仅关注功能实现，也持续完善：

-   部署体系
-   运维能力
-   架构设计
