# ADR-003: AI SDK——凭据解析与模型调用统一抽象

> 状态：Proposed
> 日期：2026-08-14 · 决策者：@todo-owner · 关联 spec：`specs/007-credential`、`specs/001-conversation`、`specs/005-knowledge`

## 背景

平台多个 Python 功能服务（agent-service、knowledge-engine、evaluation-service、parser-engine）运行时需调用外部 AI API（Nexus LLM/Rerank、Azure AI Search、Doc Intelligence 等）。每次调用涉及两个不可分割的关注点：

1. **凭据解析**——密钥选择取决于调用者身份与角色（"带资进组"场景下更复杂）
2. **模型调用**——不同 provider 的请求/响应格式各异（OpenAI Chat、Gemini、Responses API 等）

ADR-001 D4 只覆盖 gateway 侧出站凭据解析，内部服务直连场景不经 gateway。若将凭据解析与模型调用拆为两个独立 SDK，每个调用方仍需自行组装"拿到 credential → 构造请求 → 解析响应"的完整链路，格式转换与错误处理逻辑分散在各服务中。

凭据解析和模型调用是**同一个操作的两面**——没有功能服务会"只拿 credential 不调模型"，也没有"不需要 credential 的模型调用"。这个 seam 不对应独立变化的边界，拆开是人为的。

## 决策

实现 **Python AI SDK**（`grc-ai-sdk`），将凭据解析与模型调用合并为一个 SDK，功能服务通过 typed methods 完成调用，不感知凭据来源与 provider 差异。

### 核心设计原则

1. **调用方只关心三件事**：调用类型（LLM/Embedding/Rerank）、模型标识、业务参数。SDK 内部完成凭据解析→provider 路由→格式转换→调用→响应归一化。
2. **SDK 定义自己的规范类型**（Canonical Types），所有 provider 的响应归一化为同一结构，调用方永远只看到一种类型。
3. **Provider 是多层概念**：Nexus 本身是模型网关，但同一模型（如 DeepSeek V3）可能有多条上游路径（DeepSeek 直连、方舟等）。SDK 的 provider 路由模型需覆盖"网关 → 上游 provider → 模型"的层级关系，具体 API 设计在实现阶段定义。

### SDK 内部分层

```
┌─────────────────────────────────────────────────┐
│  Public API: llm / embedding / rerank           │  ← 调用方唯一接触面
├─────────────────────────────────────────────────┤
│  Canonical Types                                │  ← SDK 自定义规范响应类型
├─────────────────────────────────────────────────┤
│  Provider Adapters: Nexus / AzureOpenAI / ...   │  ← 请求构造 + 响应归一化
├─────────────────────────────────────────────────┤
│  Credential Resolver: → auth-service            │  ← 角色→密钥映射
├─────────────────────────────────────────────────┤
│  Infra: 缓存 / 重试 / 流式 / 降级              │  ← 横切关注点
└─────────────────────────────────────────────────┘
```

> 具体 API 签名、规范类型字段定义、provider 路由模型在实现阶段确定，本 ADR 只锁定分层结构与职责边界。

### Provider Adapter 策略

| 策略 | 适用场景 | 推荐度 |
|------|---------|--------|
| **先只写 Nexus adapter** | 当前所有模型调用均经 Nexus | ★★★ 当前推荐 |
| 内部 wrap litellm | 需支持多 provider 且不想自建 adapter | ★★ 多 provider 时评估 |
| 自建全部 adapter | 对外部依赖有严格管控 | ★ 仅在必要时 |

当前阶段：**先只实现 Nexus adapter**，预留 adapter 接口，后续按需扩展。

### 覆盖范围

| 类别 | 目标 API | 调用方 | 阶段 |
|------|----------|--------|------|
| LLM 推理 | Nexus LLM | agent-service, eval-service | 当前 |
| Embedding | Nexus Embedding | knowledge-engine, agent-service | 当前 |
| Rerank | Nexus Rerank | knowledge-engine | 当前 |
| AI 搜索 | Azure AI Search | knowledge-engine | 规划（带资进组） |
| 文档智能 | Azure Doc Intelligence | parser-engine / knowledge-engine | 规划（带资进组） |

### 与 ADR-001 D4 的关系

| 场景 | 解析点 | 机制 |
|------|--------|------|
| 用户出站调用资产 API | gateway（D4） | gateway 从 Key Vault 取凭据注入出站请求 |
| 内部服务调用平台托管 AI API | grc-ai-sdk（本 ADR） | SDK 经 auth-service 解析凭据后直调目标 API |

### SDK 的边界红线

以下内容**不进入 SDK**：

| 不进 SDK | 原因 | 归属 |
|----------|------|------|
| Prompt engineering / 模板管理 | 业务逻辑，变化频率远高于 SDK | 各服务自行维护 |
| 对话历史管理 | agent-service 领域逻辑 | agent-service |
| 测评评分逻辑 | eval-service 领域逻辑 | eval-service |
| 模型选择策略（fallback/A-B test） | 可能频繁变化 | 配置层或各服务 |

SDK 只负责：**用正确的凭据、以正确的格式、调用正确的端点、返回规范化的结果**。

### 职责分工

| 组件 | 职责 |
|------|------|
| grc-ai-sdk | 凭据解析 + provider adapter + 规范类型 + 缓存/重试/流式 |
| auth-service | 维护角色→密钥映射表；执行凭据转换业务逻辑；密钥值从 Key Vault 获取 |
| 功能服务 | 只调 SDK typed methods，不感知凭据来源、provider 差异与响应格式 |

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 凭据 SDK + 各服务自行调模型 | SDK 范围小 | 格式转换/重试/流式逻辑在每个服务中重复；凭据与调用的 seam 不对应独立变化边界 | 人为拆分不可分割的操作 |
| 各服务自行查 mgmt-service 获取凭据 + 自行调用 | 无新组件 | 权限逻辑与调用逻辑双重分散 | 违反关注点分离 |
| 所有调用经 gateway 复用 D4 | 统一解析点 | agent→Nexus 多一跳延迟；gateway 成为所有 AI 调用瓶颈 | 延迟与扩展性不可接受 |
| 凭据解析 sidecar + 各服务自行调用 | 无凭据网络调用 | K8s 资源翻倍；调用逻辑仍分散 | 运维复杂度过高 |
| 全平台引入 litellm 作为标准调用层 | 多 provider 开箱即用 | 不含凭据解析；外部依赖管控风险；仍需各服务自行集成 | 缺平台凭据集成 |

## 影响

- **受影响服务**：auth-service（新增凭据转换接口）、agent-service / evaluation-service / knowledge-engine / parser-engine（接入 SDK）
- **auth-service 职责扩展**：ADR-001 D1 表需新增"凭据转换"职责
- **新增跨服务依赖**：agent-service / evaluation-service / knowledge-engine / parser-engine → auth-service（均 via SDK）
- **契约影响**：auth-service 需新增 `/internal/credential/resolve` OpenAPI 接口定义
- **service-map / manifest 更新**：待本 ADR 状态确认后统一对齐

## 后果

### 正面
- 功能服务专注业务逻辑，不感知权限模型与 provider 差异
- 新增 provider / 资源类型只改 SDK adapter 或 auth-service 映射，各服务无需改动
- "带资进组"场景下凭据管理与模型调用有统一收口
- 流式、重试、错误处理等横切逻辑只实现一次

### 负面
- auth-service 成为凭据解析的关键路径，需保证高可用
- SDK 版本升级需协调所有 Python 服务（建议 semver + 兼容性保证）
- SDK 需处理流式（SSE）解析，增加实现复杂度

### 风险
- auth-service 不可用时所有 AI API 调用失败——缓解：SDK 本地缓存凭据（TTL 内可用）
- SDK 滑向 "隐藏的 monolith"——缓解：严守边界红线，不引入业务逻辑
