<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-knowledge-engine 状态卡（更新于 2026-W35）

## 职责与边界
知识引擎：目录树管理、知识库 CRUD 与状态机、四通道文档导入、四阶段构建管线（解析/切片/增强/向量化）、向量检索、开放接口（PAT 认证）。不做文档解析（→ grc-parser-engine）、不做认证（→ grc-auth-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-knowledge-engine.yaml, contracts/events/knowledge-build.asyncapi.yaml
- 消费契约：contracts/openapi/grc-parser-engine.yaml

## 近期重要变化（最近 4 周）
- W35: 解析链路支持文档上传（`08a25b2`）；接口参数调整与 api 修复（`a6df779`/`b30a2de`/`2a846a2`）；puml/svg 成对修复（`68c76ff`）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 与 spec 005 的契约对齐差距 7 项未消化（watchlist #71：三档 visibility、切片策略参数、DeepDoc 枚举残留、删除语义冲突等），需走 contract-change 流程
- #51：实现侧 deepdoc 参数移除与 FR-038 参数矩阵审阅待跟进（责任人 Li Zhonghao）
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI
- AI API 调用统一经 grc-ai-sdk（grc-python-sdk），不直接调用 provider API（ADR-003）
- 向量数据库：Milvus
<!-- /人工区块 -->
