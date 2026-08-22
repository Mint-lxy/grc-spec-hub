<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-agent-service 状态卡（更新于 2026-W34）

## 职责与边界
无状态推理执行引擎：接收已组装好的会话上下文 → 知识库检索 → MCP 工具调用 → LLM 推理 → 流式输出。
不持有会话/知识库挂载/消息历史的权威数据（归 grc-mgmt-service）；不做知识构建（→ grc-knowledge-engine）；
不做资产管理（→ grc-mgmt-service）。

## 当前状态
- 里程碑 M1 进行中
- spec 001 任务完成度：T101~T114、T116 已完成，T115（护栏钩子）占位实现
- 27 个测试全过，ruff 干净
- 提供契约：`contracts/openapi/grc-agent-service.yaml`（3 个执行端点）
- 消费契约：`contracts/openapi/grc-knowledge-engine.yaml`、`contracts/openapi/grc-mgmt-service.yaml`

## 近期重要变化（最近 4 周）
- W34: Nexus 网关适配完成——Chat 适配器加 `query_params` 支持 Azure OpenAI 风格 URL；
  新增 `VertexStyleEmbeddingAdapter` 对接 gemini-embedding-001
- W34: userId 凭据解析链路打通——`SessionContext` 加 `user_id` 字段，`llm_client.py`
  支持双模式（有 userId 走 `build_chat_adapter_for_user`，无 userId 降级为静态凭据）
- W34: `llm_client.py` 委托给 `grc-python-sdk` 的 `ChatPort`（commit `1ace60d`）
- W34: 路径前缀统一为 `/mgmt/`（从 `/mgt/` 修正，对齐已合并契约）
- W33: 服务孵化，初始化仓库脚手架；三端点首版实现 + 本地 mock 端到端联调通过

## 已知问题
- T115 护栏钩子仍是占位实现（等 plan.md 待评审确认项定论：由 agent-service 还是网关负责）
- ADR-007（A2A 协议统一，状态 Proposed）若 Accept，现有 3 个自定义端点将替换为 A2A handler
- 多实例部署下 cancel 路由方案待架构确认（一致性哈希 vs Redis 广播）
- grc-mgmt-service 内部接口（T203）尚未真实落地，agent-service 靠 mock 联调
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python 3.11+ / FastAPI / httpx / sse-starlette / structlog
- AI API 调用统一经 grc-python-sdk（ADR-003），不直接调用 provider API
- LLM 网关：Nexus（`genai-nexus.int.api.corpinter.net`），Bearer token 认证，
  Chat 用 Azure OpenAI 部署风格 URL（需 `query_params={"api-version": "2024-10-21"}`）
- 路径前缀：mgmt-service 统一用 `/mgmt/`（不是 `/mgt/`）
- grc-python-sdk 已发布到私有 Nexus PyPI（`http://<nexus>:8081/repository/pypi-hosted/`），
  版本 0.1.0
<!-- /人工区块 -->
