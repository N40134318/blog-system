# 📦 Blog System Architecture Overview (v2)

## 1. 项目定位

Blog System 已从：

👉 单机开发项目

演进为：

👉 **具备工程化能力的可部署、可迁移系统**

------------------------------------------------------------------------

## 2. 核心能力

当前系统具备：

-   ✅ Dev / Prod 双环境隔离
-   ✅ Dev 自动部署 + Prod 手动发布
-   ✅ Docker Compose 标准化运行
-   ✅ MySQL + Uploads 持久化
-   ✅ 一键迁移（package + restore）
-   ✅ 环境切换（switch-env）
-   ✅ 健康检查（health-check）
-   ✅ 部署冲突保护（Prod 优先）

------------------------------------------------------------------------

## 3. 总体架构

``` mermaid
flowchart TD
  A["GitHub Repository"] --> B["GitHub Actions"]

  B --> C["Deploy Dev"]
  B --> D["Deploy Prod"]

  C --> E["dev.rainstorm.space"]
  D --> F["preview.rainstorm.space"]

  E --> G["Nginx (Dev)"]
  F --> H["Nginx (Prod)"]

  G --> I["Frontend Dev :3001"]
  G --> J["Backend Dev :8081"]

  H --> K["Frontend Prod :3000"]
  H --> L["Backend Prod :8080"]

  J --> M["MySQL Dev :3307"]
  J --> N["Redis Dev :6380"]

  L --> O["MySQL Prod :3306"]
  L --> P["Redis Prod :6379"]

  Q["/opt/devplatform/uploads"]

  J --> Q
  L --> Q
```

------------------------------------------------------------------------

## 4. 环境划分

### Dev

  组件       端口
  ---------- ------
  Frontend   3001
  Backend    8081
  MySQL      3307
  Redis      6380

### Prod

  组件       端口
  ---------- ------
  Frontend   3000
  Backend    8080
  MySQL      3306
  Redis      6379

------------------------------------------------------------------------

## 5. 部署与切换逻辑

``` mermaid
flowchart LR
A[Push main] --> B[Deploy Dev]
B --> C{Prod running?}
C -- Yes --> D[Skip Dev]
C -- No --> E[Deploy Dev]

F[Manual Deploy Prod] --> G[Stop Dev]
G --> H[Deploy Prod]
```

------------------------------------------------------------------------

## 6. 数据与存储

``` mermaid
flowchart TD
  A["Backend"] --> B["/opt/devplatform/uploads"]

  C["MySQL Dev"] --> D["blog_mysql_data_dev"]
  E["MySQL Prod"] --> F["backend_blog_mysql_data_prod"]

  G["Redis"] --> H["Memory Only"]
```

------------------------------------------------------------------------

## 7. 迁移系统（核心能力）

### 📦 打包

``` bash
bash scripts/package-migration.sh
```

包含：

-   project（deploy / scripts / docs）
-   nginx 配置
-   docker 状态
-   MySQL dump
-   uploads

------------------------------------------------------------------------

### ♻️ 恢复

``` bash
bash scripts/restore-migration.sh <archive>
```

流程：

``` mermaid
flowchart TD
A[解压] --> B[恢复项目]
B --> C[恢复 uploads]
C --> D[启动 mysql]
D --> E[导入 SQL]
E --> F[启动服务]
F --> G[健康检查]
```

------------------------------------------------------------------------

### 🔁 环境切换

``` bash
bash scripts/switch-env.sh dev
bash scripts/switch-env.sh prod
```

------------------------------------------------------------------------

### ❤️ 健康检查

``` bash
bash scripts/health-check.sh dev
bash scripts/health-check.sh prod
```

------------------------------------------------------------------------

## 8. CI/CD 架构

``` mermaid
flowchart TD
A[GitHub main] --> B[deploy-dev.yml]
A --> C[deploy-prod.yml]

B --> D[自动]
C --> E[手动]

D --> F{Prod running?}
F -- Yes --> G[跳过]
F -- No --> H[部署 dev]

E --> I[停止 dev]
E --> J[部署 prod]
```

------------------------------------------------------------------------

## 9. 回滚策略

### 代码回滚

``` bash
git reset --hard <tag>
```

### 服务回滚

``` bash
docker compose up -d --build
```

⚠️ 数据需手动恢复 dump

------------------------------------------------------------------------

## 10. 当前系统阶段

``` mermaid
flowchart LR
A[能跑] --> B[双环境]
B --> C[CI/CD]
C --> D[迁移能力]
D --> E[环境切换]
E --> F[稳定部署体系]
```

------------------------------------------------------------------------

## 11. 后续方向

-   Redis 持久化（AOF）
-   数据库权限隔离
-   自动迁移（scp + restore）
-   灰度 / 蓝绿部署
-   监控系统（Prometheus）

------------------------------------------------------------------------

# 📌 总结

Blog System 已具备：

👉 **部署能力 + 迁移能力 + 环境控制能力**

正在从：

👉 工具集合

进化为：

👉 **标准化工程系统**
