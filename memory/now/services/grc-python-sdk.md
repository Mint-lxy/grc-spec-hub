<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-python-sdk 状态卡（更新于 2026-W35）

## 职责与边界
Python AI SDK（grc-ai-sdk，ADR-003）：凭据解析（对接 grc-mgmt-service resolve-model）、
Provider 适配器（Chat/Embedding/Rerank/Parser）、重试基础设施、AC-13 降级机制、规范类型定义。
供全部 Python 服务统一调用 LLM/Embedding/Rerank 等 AI API。不含业务逻辑（不做 prompt 管理、
不做对话历史管理、不做模型选择策略——ADR-003 边界红线）。

## 当前状态
- 里程碑 M1 进行中
- 版本：0.1.0，已发布到私有 Nexus PyPI（`pypi-hosted`）
- 提供契约：无（内部共享 SDK，不对外暴露 API）
- 消费契约：`contracts/openapi/grc-mgmt-service.yaml`（vault 子域：resolve-model / report-credential-failure）
- 测试：76 个通过

## 近期重要变化（最近 4 周）
- W34: Nexus 网关适配——Chat 适配器加 `query_params` 支持 Azure OpenAI 风格 URL；
  新增 `VertexStyleEmbeddingAdapter` 对接 gemini-embedding-001；注册为 `vertex_ai` provider
- W34: 凭据解析设计决策定稿——TTL 60s、模型选择取 availableModels[0]（管理员优先级排序）、
  Nexus 多上游路由由网关处理（SDK 不需要实现，风险项关闭）
- W34: userId 凭据解析链路打通（`build_chat_adapter_for_user`），已被 grc-agent-service 集成
- W34: 路径前缀统一为 `/mgmt/`（从 `/mgt/` 修正，对齐已合并契约）
- W34: AC-13 降级完整实现（`complete_chat_for_user`：个人凭据 401/403 → 上报 → 平台默认重试）
- W33: 服务孵化，初始化仓库脚手架；六边形架构（ports/adapters/domain）+ ProviderRegistry

## 已知问题
- **【高】契约断裂**：hub main 契约 `7c62373`（2026-08-27）将 vault 内部接口替换为 `tokens/verify` + `credentials/{id}/resolve`，SDK `credential_resolver.py` 仍调旧端点 `resolve-model`/`report-credential-failure`（源码与测试），凭据解析链路联调必断，需立即适配 [待确认 @Zhang Hao]（digest 2026-W35）
- Embedding/Rerank/Parser 有代码有单测，从未对接过真实服务（下游都还是空脚手架），等真实消费方接入时联调
- `complete_chat_for_user` 的 AC-13 降级模式仅实现了 Chat，Embedding/Rerank 等有真实消费方时再复制
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
