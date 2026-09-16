# ADR-003: AI SDK——凭据解析与模型调用统一抽象

> 状态：Proposed
> 日期：2026-08-14 · 决策者：@todo-owner · 关联 spec：`specs/007-credential`、`specs/001-conversation`、`specs/005-knowledge`
> 2026-09-15 修订：撤回「SDK 按 userId 自动选凭据 / 自动回落平台默认」的旧口径，改为**调用方显式传 `credentialId`，SDK 仅精确解析并调用**；同时把 Chat 图像输入纳入当前交付范围，并明确 `ChatPort` 与 `DOCUMENT_PARSE` 分离。

## 背景

平台多个 Python 功能服务（agent-service、knowledge-engine、evaluation-service、parser-engine）运行时需调用外部 AI API（Nexus LLM/Rerank、Azure AI Search、Doc Intelligence 等）。每次调用仍然有两个关注点，但 2026-09-15 后边界被重新切开：

1. **业务侧决策**——谁可以调用、选哪条 `credentialId`、是否允许 fallback / retry、模型是否支持 vision
2. **SDK 运行时职责**——拿着一个明确的 `credentialId`，解析 secret，组装 provider 请求，归一化响应

此前提案把「按触发人自动选个人凭据并必要时回落平台默认」压进 SDK，导致 SDK 混入业务授权、凭据策略和可用性治理。用户已明确批准改为：**调用方负责策略，SDK 只负责执行。**

## 决策

实现 **Python AI SDK**（`grc-ai-sdk`），但把职责严格收窄为：**按调用方传入的 `credentialId` 精确解析凭据，并以统一 typed API 调用 AI Provider**。

### 核心设计原则

1. **调用方必须显式给出 `credentialId`**。对 grc-ai-sdk 路径，SDK 调 resolve 时还必须同时传 `userId` 供 mgmt-service 做凭据归属校验；但 SDK 仍不据此选凭据。
2. **SDK 复用既有契约**：调用 `GET /mgmt/vault/outbound/credentials/{id}/resolve`；对当前 Nexus 模型调用，对齐最新团队接口的成功响应语义为 numeric `credentialId`、`targetType = NEXUS`、string `targetId`、`authType = NEXUS_PERSONAL_TOKEN`、nullable `endpoint` / `protocol` 与 `resolvedFields`。SDK 仅把 `authType` / `resolvedFields` 用于模型鉴权，`endpoint` / `protocol` 不决定模型调用 URL / provider，`model_gateway_base_url`、provider 与 query params 由调用方或模型配置提供。
3. **策略不进 SDK**：具体选哪条 `credentialId`、fallback / retry、失败上报、模型 capability 判定都留在业务层或配置层。
4. **Chat vision 仍属 Chat**：图像识别输入走 `ChatPort`，Document Parse 继续是独立 `DOCUMENT_PARSE` 概念。
5. **兼容迁移而非静默破坏**：历史 `MULTIMODAL -> parser` 映射保留一版 deprecated alias，再于 1.0 移除；旧 raw `api_key` / `callback` / `*_for_user` 公共 API 同样保留一版 deprecated 兼容。

### SDK 内部分层

```
┌────────────────────────────────────────────────────────┐
│  Public API: chat / embedding / rerank / doc-parse    │  ← 调用方唯一接触面
├────────────────────────────────────────────────────────┤
│  Canonical Types                                       │  ← SDK 自定义规范类型
├────────────────────────────────────────────────────────┤
│  Provider Adapters: Nexus / AzureOpenAI / ...          │  ← 请求构造 + 响应归一化
├────────────────────────────────────────────────────────┤
│  Credential Resolver: → mgmt-service                   │  ← GET /mgmt/vault/outbound/credentials/{id}/resolve
├────────────────────────────────────────────────────────┤
│  Infra: cache / streaming / timeout / retry hooks      │  ← 仅技术机制，不含业务 fallback
└────────────────────────────────────────────────────────┘
```

> 本 ADR 只锁定分层与职责边界；具体 API 签名在实现阶段落到服务仓库。

### Provider Adapter 策略

| 策略 | 适用场景 | 推荐度 |
|------|---------|--------|
| **先只写 Nexus adapter** | 当前模型调用主路径均经 Nexus | ★★★ 当前推荐 |
| 内部 wrap litellm | 未来需快速扩多 provider | ★★ 后续评估 |
| 自建全部 adapter | 对外部依赖管控极严 | ★ 仅必要时 |

当前阶段：**先只实现 Nexus adapter**，并把 Chat 图像输入按 OpenAI-compatible content parts / data URI 序列化。

### Resolve 响应约定

- `credentialId` / `userId` 以 int64 处理。
- 成功响应 `data.credentialId` 为 numeric、`targetType = NEXUS`、`targetId` 为 string。
- `authType = NEXUS_PERSONAL_TOKEN` 时，SDK 读取 `resolvedFields.nexus_token` 作为 Nexus Authorization token。
- 平台成功响应的 `ApiResponse.code` 运行时可能返回字符串 `"0"` 或数值 `0`，SDK 解析需同时容忍两者。

### 覆盖范围

| 类别 | 目标 API | 调用方 | 阶段 |
|------|----------|--------|------|
| Chat（文本） | Nexus Chat | agent-service, eval-service | 当前 |
| Chat（图像输入、文本输出） | Nexus Chat Vision-compatible endpoint | agent-service | 当前 |
| Embedding | Nexus Embedding | knowledge-engine, agent-service | 当前 |
| Rerank | Nexus Rerank | knowledge-engine | 当前 |
| Document Parse | Azure Doc Intelligence / Parser stack | parser-engine / knowledge-engine | 规划（独立于 Chat vision） |

### 与 ADR-001 D4 的关系

| 场景 | 策略决策点 | 运行时执行点 |
|------|------------|--------------|
| 用户出站调用资产 API | gateway / mgmt-service 按资产语义决定凭据 | gateway 注入出站请求 |
| 内部服务调用平台托管 AI API | 业务层 / 配置层先选定 `credentialId` 并提供 int64 用户上下文 | grc-ai-sdk 通过 Azure Workload Identity 访问令牌调 `GET /mgmt/vault/outbound/credentials/{id}/resolve?userId=...` 做归属校验后，只使用响应中的 `authType` / `resolvedFields` 进行鉴权，再按调用方/模型配置给定的 `model_gateway_base_url`、provider 与 query params 直调目标 API |

### SDK 的边界红线

以下内容**不进入 SDK**：

| 不进 SDK | 原因 | 归属 |
|----------|------|------|
| 用户/业务授权判定 | 业务规则 | 各功能服务 / mgmt-service 业务层 |
| 具体选哪条 `credentialId` | 策略频繁变化 | 调用方或配置层 |
| 自动 fallback / 自动失败上报 / 自动快照改写 | 业务治理，不是纯调用抽象 | 调用方或凭据治理域 |
| 模型是否支持 vision 的判定 | 属模型配置 / 产品策略 | 调用方或模型配置 |
| 文件存储、下载、压缩、格式转换 | 非 SDK 职责 | 前端 / 文件服务 / 业务服务 |
| Prompt engineering / 模板管理 | 业务逻辑 | 各服务自行维护 |
| 对话历史管理 | 领域逻辑 | agent-service |

SDK 只负责：**用调用方指定且经归属校验的凭据、以正确格式、按调用方/模型配置提供的网关信息发起调用、返回规范化结果**。

### 职责分工

| 组件 | 职责 |
|------|------|
| grc-ai-sdk | `credentialId` 精确解析、携带 `userId` 做归属校验、按 (`userId`, `credentialId`) 的纯技术缓存、只消费 `authType` / `resolvedFields` 做鉴权、provider adapter、规范类型、流式处理、多模态内容序列化 |
| mgmt-service（credential 模块） | 按 credentialId 返回解析结果；对当前 Nexus 模型调用语义对齐为 numeric `credentialId`、`targetType = NEXUS`、string `targetId`、`authType = NEXUS_PERSONAL_TOKEN`、nullable `endpoint` / `protocol` 与 `resolvedFields`；对 grc-ai-sdk 路径以 `userId` 校验凭据归属；以服务身份鉴权保护内部 resolve 接口 |
| 功能服务 / 配置层 | 选择 `credentialId`、完成用户/业务授权、决定 credential 使用策略、决定 fallback / retry、决定 vision 模型是否可用 |

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| SDK 按 userId 自动选凭据 | 调用方参数少 | SDK 混入授权、策略、治理逻辑；与已存在 contract 不一致 | 已被 2026-09-15 用户裁定否决 |
| 凭据 SDK + 各服务自行调模型 | SDK 范围小 | 序列化/流式/错误处理在各服务重复 | 抽象价值不足 |
| 所有调用经 gateway 复用 D4 | 统一网络出口 | agent→Nexus 多一跳，gateway 成瓶颈 | 延迟与扩展性差 |
| Chat 图像输入继续复用 parser「MULTIMODAL」概念 | 不用改旧命名 | 混淆 Chat vision 与文档解析，边界错误 | 以 deprecated alias 过渡，但不作为目标模型 |

## 影响

- **受影响服务**：grc-python-sdk、grc-agent-service、grc-mgmt-service；parser-engine 仅受命名迁移影响
- **契约影响**：不新增 `resolve-model` 端点；只澄清 `GET /mgmt/vault/outbound/credentials/{id}/resolve` 的内部语义，并清理未引用的旧 `ResolveModelResponseEnvelope`
- **兼容影响**：`api_key` / `callback` / `*_for_user` 与 `MULTIMODAL` 旧路径进入一版 deprecated 兼容窗口，1.0 移除
- **验证影响**：现有 Postman 文件只证明 GPT-5.5 文本接口可通，不证明 Base64 图像 payload 兼容；需单独做 Nexus 图像 PoC

## 后果

### 正面

- SDK 与现有 contract 对齐，不再依赖已删除的旧端点
- 业务授权与凭据策略边界清晰，SDK 更容易复用与测试
- Chat 图像输入与 Document Parse 概念拆清，减少后续模型类别混乱
- 纯文本、流式、tool calling 能以同一 ChatPort 持续兼容

### 负面

- 调用方需要显式管理 `credentialId` 与策略，接入工作量上升
- 兼容窗口内需同时维护新旧 API/枚举的 deprecated shim
- Base64 图像 payload 会增加请求体体积，需要靠业务层限额控制

### 风险

- 宿主服务若未正确配置 Azure Workload Identity 访问令牌，则 resolve 调用整体失败
- 若调用方误把非 vision 模型用于图像输入，Provider 4xx 会直接暴露给上层；需由业务配置与测试兜底
- 若 1.0 前未完成 `MULTIMODAL` / `*_for_user` 调用方迁移，将在移除窗口触发兼容性风险
