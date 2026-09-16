<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-python-sdk 状态卡（更新于 2026-W38）

## 职责与边界
Python AI SDK（grc-ai-sdk，ADR-003）：按 `userId + credentialId` 对接 grc-mgmt-service
解析 Vault 凭据、Provider 适配器（Chat/Embedding/Rerank/Document Parse）、重试基础设施与规范类型定义。
供全部 Python 服务统一调用 LLM/Embedding/Rerank 等 AI API。不含业务逻辑（不做 prompt 管理、
不做对话历史管理、不做模型选择策略——ADR-003 边界红线）。

## 当前状态
- 里程碑 M1 进行中
- 版本：0.2.0（实现提交 `grc-python-sdk@bd27788`，待发布到私有 Nexus PyPI）
- 提供契约：无（内部共享 SDK，不对外暴露 API）
- 消费契约：`contracts/openapi/grc-mgmt-service.yaml`
  （`GET /mgmt/vault/outbound/credentials/{id}/resolve?userId=...`）
- 测试：119 个通过；grc-agent-service 兼容测试 27 个通过

## 近期重要变化（最近 4 周）
- W38: SDK 0.2.0 实现 `userId + credentialId` 精确解析；调用方负责凭据选择、授权、
  fallback/retry，SDK 只通过 Workload Identity 取密钥并调用 Provider；缓存按
  `(userId, credentialId)` 隔离。旧 raw Key / callback / `*_for_user` 保留一版 deprecated
- W38: ChatPort 支持 Base64 JPEG/PNG/WebP 图片输入（4 张、10 MiB/张、20 MiB 总量），
  保持流式与 tool calling；GPT-5.5 真实 PNG 联调成功，并确认使用
  `max_completion_tokens`
- W34: Nexus 网关适配——Chat 适配器加 `query_params` 支持 Azure OpenAI 风格 URL；
  新增 `VertexStyleEmbeddingAdapter` 对接 gemini-embedding-001；注册为 `vertex_ai` provider
- W34: 凭据解析设计决策定稿——TTL 60s、模型选择取 availableModels[0]（管理员优先级排序）、
  Nexus 多上游路由由网关处理（SDK 不需要实现，风险项关闭）
- W34: userId 凭据解析链路打通（`build_chat_adapter_for_user`），已被 grc-agent-service 集成
- W34: 路径前缀统一为 `/mgmt/`（从 `/mgt/` 修正，对齐已合并契约）
- W34: AC-13 降级完整实现（`complete_chat_for_user`：个人凭据 401/403 → 上报 → 平台默认重试）
- W33: 服务孵化，初始化仓库脚手架；六边形架构（ports/adapters/domain）+ ProviderRegistry

## 已知问题
- grc-agent-service 当前仍使用 deprecated `*_for_user`/静态 Key 兼容路径，需在业务层提供
  credentialId 后迁移
- mgmt-service 的 Workload Identity 服务授权仍需落地
- Embedding/Rerank/Parser 有代码有单测，从未对接过真实服务（下游都还是空脚手架），等真实消费方接入时联调
- 旧 `complete_chat_for_user` 自动降级仅作兼容，1.0 移除；新路径不自动 fallback
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python 3.10+ / httpx（唯一运行时依赖）
- 被 grc-agent-service / grc-evaluation-service / grc-knowledge-engine / grc-parser-engine 以 pip 依赖方式引用
- 本地安装：`pip install -e ../grc-python-sdk`（路径依赖，尚未发布到公共 PyPI）
- Nexus 网关：`genai-nexus.int.api.corpinter.net`，Bearer token 认证
  - Chat 用 Azure OpenAI 部署风格 URL（需 `query_params={"api-version": "2024-10-21"}`）
  - Embedding（gemini-embedding-001）用 Vertex AI `:predict` 协议
- 已注册 Provider：`openai_compatible`（Chat/Embedding）、`vertex_ai`（Embedding）、
  `cohere_style`（Rerank）、`parser_engine`（Parser）
- 自定义 Provider 注册：`CHAT_PROVIDERS.register("my_provider", MyAdapterClass)` 即可，不改 SDK 源码
<!-- /人工区块 -->
