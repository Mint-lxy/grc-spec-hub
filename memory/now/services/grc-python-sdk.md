<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-python-sdk 状态卡（更新于 2026-W33）

## 职责与边界
Python AI SDK（grc-ai-sdk）：凭据解析、Provider 适配器、规范类型定义，供全部 Python 服务统一调用 LLM/Embedding/Rerank 等 AI API（ADR-003）。不含业务逻辑。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：无（内部共享 SDK，不对外暴露 API）
- 消费契约：无

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / uv
- 被 grc-agent-service / grc-evaluation-service / grc-knowledge-engine / grc-parser-engine 以 pip 依赖方式引用
<!-- /人工区块 -->
