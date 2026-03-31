# 📦 Blog System 标准迁移流程

## 一、源机器（打包）

执行：

bash scripts/package-migration.sh

输出：

/opt/devplatform/backups/migration/blog-system-migration-xxxx.tar.gz

---

## 二、传输迁移包

scp / rsync / 手动复制

---

## 三、目标机器（恢复）

执行：

bash scripts/restore-migration.sh /path/to/package.tar.gz

选择：

1) dev
2) prod

---

## 四、切换环境（如果需要）

bash scripts/switch-env.sh dev
bash scripts/switch-env.sh prod

---

## 五、验证

Backend:
curl http://127.0.0.1:8080/actuator/health

Frontend:
curl -I http://127.0.0.1:3000

---

## 六、成功标准

- Backend = UP
- Frontend 可访问
- 图片正常加载
- 数据存在

---

## 七、常见错误

### 1. 数据为空
→ SQL 没导入

### 2. 502
→ nginx 指向错误

### 3. 图片不显示
→ uploads 权限问题
