<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-knowledge-engine 状态卡（更新于 2026-W33）

## 职责与边界
知识引擎：目录树管理、知识库 CRUD 与状态机、四通道文档导入、四阶段构建管线（解析/切片/增强/向量化）、向量检索、开放接口（PAT 认证）。不做文档解析（→ grc-parser-engine）、不做认证（→ grc-auth-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-knowledge-engine.yaml, contracts/events/knowledge-build.asyncapi.yaml
- 消费契约：contracts/openapi/grc-parser-engine.yaml

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI
- AI API 调用统一经 grc-ai-sdk（grc-python-sdk），不直接调用 provider API（ADR-003）
- 向量数据库：Milvus
<!-- /人工区块 -->
