# Retro: 当前环境端到端演示

## 结果

已在 Azure 中国云开发 AKS `XAGPMCNINFAKS001` 打通真实演示链路：

`Portal → Gateway → Auth/Mgmt → Knowledge → Parser/Milvus`

Portal 通过 Internal LoadBalancer `172.27.104.8` 暴露。固定 DOCX 经 Portal 同域 API、
Azure Blob、Parser、Knowledge 和 Milvus 完成构建，最终文档状态为 `ACTIVE`，生成 21 个
chunks 和 21 条向量；预定义检索返回 5 条结果。

## 做得好的地方

- 优先复用 EC2 已跑通镜像，再按源码 commit 与 ACR digest 固定，缩短了部署路径。
- 每个运行时清单先写静态校验，避免 latest、公网服务、localhost 和错误探针进入集群。
- 以真实业务 E2E 而不是 Pod Ready 作为完成标准，连续暴露并修复了多个运行时缺口。
- EC2 `grc_db` 以无 owner/权限的 dump 迁移到 Azure，恢复 68 张 public 表和演示数据。
- Portal 重新按 AKS Gateway/Blob origin 构建，明确关闭 Mock。

## 主要问题与修复

1. Java 镜像未声明 OCI User，`runAsNonRoot: true` 会在启动前被拒绝；当前保留 seccomp、
   drop capabilities 和禁提权，后续重建非 root 镜像。
2. Mgmt production profile 需要标准 `SPRING_DATASOURCE_*`，不能只依赖 `DB_*`。
3. Gateway production profile硬编码 localhost，需用 `GATEWAY_*_BASE_URL` 完整属性覆盖。
4. Portal rewrite 在 build 时固化，必须针对 AKS origin 重建镜像。
5. Azure Blob container 需先创建，且中国云工具必须使用正确 endpoint suffix。
6. Knowledge 旧镜像没有 deployed worker；新镜像先以 `local + real DB` 完成开发演示。
7. Knowledge 缺少 `LOCAL_UPLOAD` SourceType、把 HTTPS SAS 当本地文件读取、Parser token
   硬编码，均通过红绿测试修复。
8. PostgreSQL 迁移不会迁移 Milvus；旧知识库的 generation 引用不可直接在新 Milvus 复用，
   演示改用空知识库创建全新 generation。

## 验证证据

- Auth 登录：HTTP 200，成功签发 token。
- Gateway：无 token 返回 401；携带 token 的知识库列表 HTTP 200，返回 9 条。
- Portal：主页、bootstrap、Curate 页面和同域 API 均成功。
- 上传：Blob PUT 201，完成会话与创建文档均 HTTP 200。
- Parser：1 页、9614 字符解析完成。
- Knowledge：21 chunks，pipeline live switch 完成，文档 `ACTIVE`。
- Milvus：目标 collection `count(*) = 21`。
- Retrieval：HTTP 200，返回 5 条结果。
- Gateway rollout undo 后恢复当前 manifest，Deployment 保持 Ready。

## 尚未完成

- 当前账号无 Service Bus `listKeys`，Knowledge 暂用进程内 worker；Pod 重启会中断在途任务。
- 需要从实际 VPN 客户端验证 `http://172.27.104.8/` 私网路由。
- PostgreSQL 当前仍使用过渡管理员凭据，需改为最小权限服务账号并轮换。
- Java 镜像需重建为非 root，并为 Mgmt 增加正式应用 readiness。
- 全仓历史测试仍有 11 个既有失败，主要是 provider contract 漂移和空查询参数兼容。
