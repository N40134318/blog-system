📦 Blog System Migration 工具使用说明

«本文档描述 "package-migration.sh" 与 "restore-migration.sh" 的使用方式，用于实现 Blog System 的跨环境迁移与恢复。»

---

🧭 一、整体目标

本工具用于实现：

- ✅ 环境迁移（dev / prod）
- ✅ 数据库迁移（MySQL dump）
- ✅ 上传文件迁移（uploads）
- ✅ 项目配置迁移（deploy / scripts / docs）
- ✅ 运行状态记录（docker state）

---

🏗️ 二、迁移流程总览

源机器
  ↓ package-migration.sh
迁移包 (.tar.gz)
  ↓ 传输
目标机器
  ↓ restore-migration.sh
完整恢复运行环境

---

📦 三、打包脚本：package-migration.sh

📍 作用

在源机器上执行，生成完整迁移包：

./package-migration.sh

---

📁 生成内容结构

blog-system-migration-xxxx/
├── data/            # MySQL dump
│   ├── blogdb-dev.sql.gz
│   └── blogdb-prod.sql.gz
├── uploads/         # 上传文件
├── project/         # 项目配置
│   ├── deploy/
│   ├── scripts/
│   ├── docs/
│   └── .github/
├── nginx/           # nginx 配置
├── state/           # docker 状态
└── MIGRATION_README.md

---

⚙️ 打包内容说明

项目| 内容
MySQL| 使用 "mysqldump" 导出
uploads| 直接复制
project| deploy + scripts + docs
nginx| 域名配置
state| docker 状态快照

---

⚠️ 注意事项

- ".env" 文件会被打包（包含敏感信息）
- 仅在可信环境使用
- 不要提交到 git

---

🚀 四、恢复脚本：restore-migration.sh

📍 作用

在目标机器上执行，从迁移包恢复完整环境：

./restore-migration.sh /path/to/blog-system-migration-xxxx.tar.gz

---

🧩 恢复流程

1️⃣ 解压迁移包

自动完成

---

2️⃣ 恢复项目文件

/opt/devplatform/projects/blog-system

---

3️⃣ 恢复 uploads

/opt/devplatform/uploads

---

4️⃣ 启动 MySQL & Redis

docker compose up -d mysql redis

---

5️⃣ 重建数据库

DROP DATABASE IF EXISTS blogdb;
CREATE DATABASE blogdb;

---

6️⃣ 导入 SQL

gzip -cd blogdb-*.sql.gz | mysql

---

7️⃣ 启动完整服务

docker compose up -d --build

---

8️⃣ 健康检查

/actuator/health

---

🎯 五、成功判定标准

必须同时满足：

项目| 标准
DB| 有数据
Backend| health=UP
Frontend| 可访问
Uploads| 图片正常加载

---

⚠️ 六、常见问题

---

❌ 1. 502 Bad Gateway

原因：

- nginx → upstream 不通

排查：

docker logs blog-nginx
docker logs blog-backend-dev

---

❌ 2. 数据为空

原因：

- SQL 未导入
- 导入失败

排查：

SELECT COUNT(*) FROM post;

---

❌ 3. 表已存在错误

解决：

DROP DATABASE blogdb;
CREATE DATABASE blogdb;

---

❌ 4. 图片不显示

原因：

- uploads 未恢复
- 权限问题

解决：

chown -R 1000:1000 /opt/devplatform/uploads

---

🔐 七、安全注意事项

- 包含数据库数据
- 包含 env 密钥
- 禁止上传公网
- 建议使用私有存储

---

🧠 八、设计原则（核心）

本迁移系统遵循：

1️⃣ 数据与容器解耦

→ 使用 SQL dump 而非 volume copy

2️⃣ 可重复恢复

→ 任意机器可还原

3️⃣ 环境隔离

→ dev / prod 独立

4️⃣ 可观测性

→ docker state + health check

---

🚀 九、后续演进方向

- [ ] 一键远程迁移（scp + restore）
- [ ] CI/CD 自动迁移
- [ ] 灰度环境复制
- [ ] 数据版本校验（checksum）

---

📌 十、总结

本工具实现了：

👉 从“能跑” → “可迁移” → “可复制”的工程升级

是系统从开发阶段走向工程化的重要一步。
