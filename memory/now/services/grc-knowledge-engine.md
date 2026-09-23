<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-knowledge-engine 状态卡（更新于 2026-W37）

## 职责与边界
知识引擎：目录树管理、知识库 CRUD 与状态机、四通道文档导入、四阶段构建管线（解析/切片/增强/向量化）、向量检索、开放接口（PAT 认证）。不做文档解析（→ grc-parser-engine）、不做认证（→ grc-auth-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-knowledge-engine.yaml, contracts/events/knowledge-build.asyncapi.yaml
- 消费契约：contracts/openapi/grc-parser-engine.yaml

## 近期重要变化（最近 4 周）
- W37: spec 015 集成 release `843ee71` 并保留 AKS 认证/non-root/8080 修复；新增幂等
  migration 007，将 1903 行 chunk 的 `update_time` 转为 `timestamptz`。发布 digest
  `afe7e918...`；固定 DOCX 产出 104 chunks/104 vectors，任务 SUCCEEDED、检索 5 条。
- W37: spec 014 AKS 真实文档链路完成：补 deployed Service Bus queue 生命周期、运行时
  fail-fast、`LOCAL_UPLOAD`、HTTPS SAS source 下载和 Parser bearer token；开发演示使用
  `local + real DB` worker。固定 DOCX 产出 21 chunks/21 vectors，文档 ACTIVE，检索返回
  5 条。实现 `f3f2405`/`88c503d`/`165a6b3`/`2197d65`/`794ad7f`。
- W35: 解析链路支持文档上传（`08a25b2`）；接口参数调整与 api 修复（`a6df779`/`b30a2de`/`2a846a2`）；puml/svg 成对修复（`68c76ff`）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 与 spec 005 的契约对齐差距 7 项未消化（watchlist #71：三档 visibility、切片策略参数、DeepDoc 枚举残留、删除语义冲突等），需走 contract-change 流程
- #51：实现侧 deepdoc 参数移除与 FR-038 参数矩阵审阅待跟进（责任人 Li Zhonghao）
- Service Bus topic/subscription 已创建，但当前账号无 `listKeys` 权限；切回 deployed worker
  前需取得连接串并验证 Pod 重启后的任务恢复。
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI
- AI API 调用统一经 grc-ai-sdk（grc-python-sdk），不直接调用 provider API（ADR-003）
- 向量数据库：Milvus
- 开发 AKS 已部署 Milvus 2.5.12 Standalone + Rocksmq、单副本 etcd、单副本 MinIO；
  三个 64 GiB Premium PVC，均运行于带 `sku=milvus:NoSchedule` 的 `milvuspool`。
- 集群内地址为 `http://milvus.milvus.svc.cluster.local:19530`；认证已开启，
  `MILVUS_TOKEN` 必须通过 Secret 注入，禁止写入 Git。
- 部署工件见 `grc-knowledge-engine/deploy/aks/milvus/`（spec 011，
  commit `8593554`）；生产不得直接复用单节点拓扑。
<!-- /人工区块 -->
