# Implementation Plan: grc-ai-sdk（模型类调用的凭据解析与统一调用）

**Branch**: `007-credential` | **Date**: 2026-08-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/007-credential/spec.md`（AC-10~13、AC-21：模型类调用
按触发人解析，个人优先、平台默认兜底）+ [ADR-003](../../architecture/adr/003-ai-sdk.md)
（AI SDK 分层设计）+ [ADR-005](../../architecture/adr/005-credential-resolution.md)（凭据解析归属）

## Summary

本 plan 只覆盖 spec 007 里"模型类调用"这部分（AC-10~13、AC-21），落地 ADR-003 定义的
`grc-ai-sdk`（仓库名 `grc-python-sdk`，两者是同一个东西——见
`memory/now/services/grc-python-sdk.md`）：凭据解析 + Provider Adapter + 规范类型，
供 grc-agent-service / grc-evaluation-service / grc-knowledge-engine / grc-parser-engine
四个 Python 服务统一调用 LLM/Embedding/Rerank。P0 范围只做 LLM（grc-agent-service 已有
消费需求，见 `specs/001-conversation/plan.md` 的待评审确认项 T111），Embedding/Rerank
的 Provider Adapter 先搭好接口骨架，具体 Provider 接入留给对应 feature（005-knowledge）。

密钥库/PAT/资产级凭据等 spec 007 的其余部分（AC-1~9、AC-14~25）不在本 plan 范围内。

## Technical Context

**Language/Version**: Python 3.11+

**Primary Dependencies**: httpx（Provider 调用 + mgt-service 调用），无其他重依赖

**Storage**: 无。SDK 内置一个进程内 TTL 缓存存解析出的凭据（ADR-003 风险缓解项：
"mgt-service 不可用时所有 AI API 调用失败——缓解：SDK 本地缓存凭据"），不是业务数据存储。

**Testing**: pytest + pytest-asyncio，`httpx.MockTransport` 隔离外部调用

**Target Platform**: 作为 pip 依赖被其他 Python 服务引用，不独立部署

**Project Type**: library

**Performance Goals**: `[待确认]`（凭据缓存 TTL 具体取值待与 grc-mgt-service 团队对齐，
ADR-005 提到该服务侧缓存 TTL 5min，SDK 侧缓存可以对齐或更短）

**Constraints**: SDK 不能引入业务逻辑（ADR-003"边界红线"：不做 prompt 管理、不做对话历史管理、
不做模型选择策略）

**Scale/Scope**: 当前只有 grc-agent-service 一个真实消费方（本次同步接入）；
grc-evaluation-service / grc-knowledge-engine / grc-parser-engine 待各自 feature 落地时接入

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-python-sdk | 新增实现（首个版本） | Chat/Embedding/Rerank/Parser 四个 Port + OpenAI 兼容 Adapter + 凭据解析层（调用 grc-mgt-service）+ 规范类型 |
| grc-mgt-service | 新增端点 | `POST /mgt/vault/inbound/resolve-model`（ADR-003/ADR-005 已定义响应形状，本次落地为正式契约） |
| grc-agent-service | 消费方接入 | `app/services/llm_client.py` 从自包含实现改为依赖 `grc-python-sdk` 的 `ChatPort`；对应 `specs/001-conversation/plan.md` 的 T111 待评审确认项 |

> service-map.md 中 grc-agent-service 已声明 `depends-on: grc-mgt-service`，本次新增依赖
> grc-python-sdk 是 pip 包依赖（非服务间网络调用），不改变服务拓扑，不需要更新 service-map。

## 契约影响（Contract Impact · 必填）

| 契约 | 类型 | 新增/变更/废弃 | 是否破坏性 | 消费方 |
|------|------|----------------|-----------|--------|
| `contracts/openapi/grc-mgmt-service.yaml` | openapi | 新增路径 `POST /mgt/vault/inbound/resolve-model`（追加到已有文件的 vault 子域，见文件内新增的 "3.5 凭据库与 PAT（内部）" 小节） | 否（新增路径，不改动已有的 chat 会话子域） | grc-python-sdk（通过消费本服务契约的方式对齐，非直接消费方声明——SDK 不在 service-map 登记为独立服务） |

grc-python-sdk 本身**不产出 OpenAPI 契约**（内部共享库，不对外暴露 API，
见 `memory/now/services/grc-python-sdk.md`"提供契约：无"）。

## Constitution Check

| 原则 | 自查结果 |
|------|---------|
| 一、Spec 先行 | ✅ 追溯到 spec 007 AC-10~13/AC-21 + ADR-003/005 |
| 二、契约先行 | ✅ `resolve-model` 端点先在本 plan 同批产出契约草案，代码只引用合并后的版本 |
| 三、测试先行 | ✅ 新增代码将先写测试（Provider Adapter 用 `httpx.MockTransport`，Credential Resolver 用 fake mgt-service），先红后绿 |
| 四、服务边界 | ✅ SDK 经 HTTP 契约调用 grc-mgt-service，不直连其数据库 |
| 五、记忆义务 | ⏳ 待本 spec 完成时更新 memory/now（grc-python-sdk 服务卡"当前状态"从"里程碑 M1 进行中"更新） |
| 六、人类守门点 | ⏳ 本 plan.md 与契约变更均待人审合并 |

## Project Structure

```text
grc-python-sdk/
├── grc_python_sdk/
│   ├── __init__.py
│   ├── errors.py
│   ├── model_config.py          # ModelConfig/ModelCategory
│   ├── factory.py                # 按 ModelConfig.category 分发到具体 Adapter
│   ├── registry.py               # ProviderRegistry
│   ├── credential_resolver.py    # 新增：真正调用 grc-mgt-service resolve-model
│   ├── ports/                    # ChatPort/EmbeddingPort/RerankerPort/DocumentParsePort
│   ├── domain/                   # 各 Port 的请求/响应领域模型（规范类型）
│   └── adapters/                 # OpenAICompatibleChatAdapter 等具体 Provider 实现
└── tests/
```

**Structure Decision**: 沿用本地骨架验证阶段已验证过的六边形架构（ports/adapters/domain），
新增 `credential_resolver.py` 补上 ADR-003 要求但骨架阶段缺失的一层——骨架阶段是"凭据解析是
调用方的责任"（`factory.py` 用回调注入），ADR-003 的决策是"SDK 内部完成凭据解析"，本次按
ADR-003 改造：`factory.py` 默认使用 `credential_resolver.py`，调用方仍可通过回调覆盖（保留
单测所需的可替换性），但生产默认路径不再要求调用方自己写解析逻辑。

## 待评审确认项

- [ ] SDK 侧凭据缓存 TTL 具体取值（对齐 ADR-005 的 mgt-service 侧 5min，还是更短）
- [ ] Provider 路由的"网关 → 上游 provider → 模型"层级关系（ADR-003："具体 API 设计在实现
      阶段定义"）：本次 P0 先只支持单层（`ModelConfig.provider` 直接对应一个 Adapter 类），
      多层路由留给后续
- [ ] `resolve-model` 返回的 `availableModels[]` 具体怎么影响 SDK 的 Provider 选择（当前
      `ModelConfig` 是调用方显式传入，还是应该由 SDK 根据 `availableModels[]` 自动选第一个可用的）
