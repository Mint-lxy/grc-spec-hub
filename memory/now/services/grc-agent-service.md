<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-agent-service 状态卡（更新于 2026-W33）

## 职责与边界
Agent 服务：对话编排（Chat agent-runtime + 资产 Agent 透传）、MCP Tool 调用、LLM 推理调度、会话持久化、知识库挂载检索代理。不做知识构建（→ grc-knowledge-engine）、不做资产管理（→ grc-mgmt-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-agent-service.yaml
- 消费契约：contracts/openapi/grc-knowledge-engine.yaml, contracts/openapi/grc-mgmt-service.yaml

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI
- AI API 调用统一经 grc-ai-sdk（grc-python-sdk），不直接调用 provider API（ADR-003）
<!-- /人工区块 -->
