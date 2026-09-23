# Implementation Plan: grc-ai-sdk（credentialId 解析、统一调用与 Chat 图像输入承载）

**Branch**: `007-credential` | **Date**: 2026-08-18（初版） / 2026-09-15（按已批准的 credentialId + multimodal 决策修订） | **Spec**: [spec.md](./spec.md)

**Input**: `specs/007-credential/spec.md`（模型类调用的 SDK 边界）、`specs/001-conversation/spec.md`（Chat 图像输入当前交付范围）、
[ADR-003](../../architecture/adr/003-ai-sdk.md)（AI SDK 分层设计）、
[ADR-005](../../architecture/adr/005-credential-resolution.md)（凭据解析归属与边界）

## Summary

本 plan 只覆盖 spec 007 里**模型类调用的 SDK 范围**，并吸收 spec 001 已升级为当前交付的
Chat 图像输入需求：

- SDK **不再按 userId / modelId 自动选凭据**，而是由调用方显式传入 `credentialId`；
- SDK 复用既有 `GET /mgmt/vault/outbound/credentials/{id}/resolve`，只精确解析该 ID；
  对 grc-ai-sdk 路径，调用时 **MUST 同时传 `userId`** 供 mgmt-service 校验凭据归属，
  但 `userId` 不参与 SDK 内部选凭据；
- Vault resolve 响应按最新团队接口解释：`credentialId` / `userId` 都按 int64 处理；成功响应
  `data.credentialId` 为 numeric、`targetType = NEXUS`、`targetId` 为 string、`authType =
  NEXUS_PERSONAL_TOKEN`、`endpoint` / `protocol` 可为 `null`；
- SDK 仅把返回的 `authType` / `resolvedFields` 用于模型鉴权；`endpoint` / `protocol`
  只是返回元数据，不决定 SDK 的模型调用 URL / provider；`model_gateway_base_url`、
  provider 与 query params 来自调用方或模型配置；`NEXUS_PERSONAL_TOKEN` 使用
  `resolvedFields.nexus_token`；
- 调用方负责凭据选择、用户/业务授权、credential 使用策略、fallback / retry 决策；
- 宿主工作负载通过 Azure Workload Identity 获取访问令牌访问 mgmt-service；
- SDK 不自动上报凭据失败、不自动改写可用性快照、不自动回落平台凭据，provider 错误直接返回调用方；
- 当前多模态交付范围是 **ChatPort 支持图像输入、文本输出**：图片仅接受 Base64，
  SDK 内部序列化为 OpenAI-compatible content parts 与 data URI；纯文本调用继续兼容；
- `DOCUMENT_PARSE` 与 Chat vision 能力分离：历史 `MULTIMODAL -> parser` 映射保留一版
  deprecated 兼容，再于 1.0 移除，避免静默破坏既有 parser 调用方。

密钥库/PAT/资产调用凭据等 spec 007 其余部分（PAT、资产调用、导入通道）不在本 plan 范围内。

## Technical Context

**Language/Version**: Python 3.11+

**Primary Dependencies**: httpx（Provider 调用 + mgmt-service 调用）；访问令牌由宿主服务的
Azure Workload Identity 提供，具体取 token 的库遵循消费方仓库现有实现，本 plan 不在 hub 内定死。

**Storage**: 无业务存储。SDK 仅保留**进程内短期缓存**：按 **(`userId`, `credentialId`)**
缓存解析结果，默认 TTL 60 秒，仅用于降低 mgmt-service 抖动对可用性的影响；MUST NOT 仅按
`credentialId` 缓存，以免绕过所有权校验；resolved secret 不落盘、不写日志、不跨进程共享。

**Testing**: pytest + pytest-asyncio，`httpx.MockTransport` 隔离 mgmt-service 与上游 Provider；
多模态覆盖纯文本回归、图像输入、流式、tool calling、deprecation 兼容，以及
`ApiResponse.code` string/int 容忍、numeric `credentialId` / string `targetId`、`targetType = NEXUS`、
`endpoint` / `protocol` nullable、`NEXUS_PERSONAL_TOKEN` → `resolvedFields.nexus_token`
映射测试。

**Target Platform**: 作为 pip 依赖被其他 Python 服务引用，不独立部署

**Project Type**: library

**Performance Goals**:

- 解析缓存 TTL 默认 60 秒，可配置并支持显式失效；
- Chat 多模态请求默认超时 120 秒，可由调用方配置覆盖；
- 图片限制：JPEG/PNG/WebP，单次最多 4 张，单张解码后 ≤ 10 MiB，总计 ≤ 20 MiB。

**Constraints**:

- SDK 不能引入业务逻辑：不做凭据选择策略、不做用户授权判定、不做模型 capability 决策；
- SDK 不负责文件存储/下载/压缩/格式转换，不抓取外部 URL；
- provider 4xx/5xx/网络错误直接返回调用方，不自动切到另一条凭据；
- vision-capable chat model 走 ChatPort；Document Parse 是独立概念，不得继续把 Chat 图像理解偷偷映射到 parser。

**Scale/Scope**: 当前真实消费方仍以 grc-agent-service 为主；本次新增的是 Chat 图像输入承载与
credentialId 解析边界，Embedding/Rerank/Document Parse 保持接口兼容并按各自 feature 落地。

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-python-sdk | 新增实现 / 边界修订 | `CredentialResolver` 改为按 `credentialId` 调 `GET /mgmt/vault/outbound/credentials/{id}/resolve?userId=...` 做所有权校验；解析缓存若保留则按 (`userId`, `credentialId`) 键控；模型鉴权只消费 vault 响应的 `authType` / `resolvedFields`，`model_gateway_base_url` / provider / query params 取自调用方或模型配置，不取自 vault `endpoint` / `protocol`；ChatPort 支持图像输入；保留纯文本、流式与 tool calling；旧 `api_key` / `callback` / `*_for_user` 公共 API 进入一版 deprecated 兼容 |
| grc-mgmt-service | 既有契约澄清 | 不新增 `resolve-model` 端点；继续提供既有 `GET /mgmt/vault/outbound/credentials/{id}/resolve`，并明确 grc-ai-sdk 调用时必须传 int64 `userId` 做凭据归属校验，服务鉴权依赖 Azure Workload Identity 访问令牌；成功响应对齐最新团队接口：numeric `credentialId`、`targetType = NEXUS`、string `targetId`、`authType = NEXUS_PERSONAL_TOKEN`、`endpoint` / `protocol` nullable |
| grc-agent-service | 消费方接入调整 | Chat 业务层负责在进入 SDK 前完成 `credentialId` 选择、用户/业务授权，并向 SDK 提供用户上下文、模型网关 base URL / provider / query params，再将 Base64 图片请求传给 ChatPort；Provider 4xx 直接向上返回，不再依赖 SDK 自动回落 |
| grc-parser-engine | 兼容迁移 | Document Parse 继续走独立 `DOCUMENT_PARSE` 概念；历史 `MULTIMODAL` 映射仅保留为一版 deprecated alias，避免影响既有 parser 流程 |

> `grc-python-sdk` 是共享库，不改变 `architecture/service-map.md` 的服务拓扑；跨服务网络依赖仍是
> 消费方服务 → `grc-mgmt-service`（via SDK）。

## 契约影响（Contract Impact · 必填）

| 契约 | 类型 | 新增/变更/废弃 | 是否破坏性 | 消费方 |
|------|------|----------------|-----------|--------|
| `contracts/openapi/grc-mgmt-service.yaml` | openapi | **澄清现有路径** `GET /mgmt/vault/outbound/credentials/{id}/resolve` 的 SDK 内部语义与服务身份鉴权；保留控制器层 `userId` 可选，但明确 grc-ai-sdk 调用时必须传 int64 `userId` 做归属校验；对齐 `ResolvedCredentialResponse` 的 numeric `credentialId` / string `targetId` / `targetType = NEXUS` / `authType = NEXUS_PERSONAL_TOKEN` / nullable `endpoint` / `protocol` / `nexus_token` 运行时语义 | 否（描述性澄清 + 运行时语义对齐） | grc-agent-service / grc-python-sdk / 其他经 SDK 使用该内部接口的服务 |

grc-python-sdk 本身**不产出 OpenAPI 契约**（内部共享库，不对外暴露 API）。

## Constitution Check

| 原则 | 自查结果 |
|------|---------|
| 一、Spec 先行 | ✅ 追溯到 spec 007（SDK 凭据边界）+ spec 001（Chat 图像输入）+ ADR-003/005 |
| 二、契约先行 | ✅ 不发明新 `resolve-model` 端点；代码只消费已存在并在本次澄清后的 `grc-mgmt-service.yaml` |
| 三、测试先行 | ✅ resolver / multimodal / deprecation / streaming / tool calling 均要求先补失败测试 |
| 四、服务边界 | ✅ mgmt-service 只做 credentialId 精确解析；SDK 不下沉业务授权与凭据选择策略 |
| 五、记忆义务 | ⏳ 本 spec 完成时补 `retro.md` 与 memory/now 更新建议；本次仅改 spec/plan/tasks/ADR/contract |
| 六、人类守门点 | ⏳ plan 与 contract 仍需人审合并 |

## Project Structure

```text
grc-python-sdk/
├── grc_python_sdk/
│   ├── __init__.py
│   ├── errors.py
│   ├── model_config.py
│   ├── factory.py
│   ├── registry.py
│   ├── credential_resolver.py    # 调 GET /mgmt/vault/outbound/credentials/{id}/resolve
│   ├── ports/                    # ChatPort / EmbeddingPort / RerankPort / DocumentParsePort
│   ├── domain/                   # Chat 内容 parts、图片 detail、规范响应类型
│   └── adapters/                 # OpenAI-compatible Chat Adapter 等 Provider 实现
└── tests/
```

**Structure Decision**:

- `factory.py` 的生产默认路径收敛为 **credentialId 驱动**；
- 旧 `*_for_user` / raw `api_key` / `callback` 入口仅作为一版 deprecated compatibility shim，
  由 shim 在边界层转发到新的 `credentialId` 路径或显式提示迁移；
- `ChatPort` 承载文本与图像输入；`DocumentParsePort` 保持独立；
- `MULTIMODAL` 历史枚举在过渡期内标 deprecated，并明确别名到 `DOCUMENT_PARSE`，
  同时文档要求 vision-capable chat model 改走 `ChatPort`。

## 待评审确认项

- [x] Nexus Base64 图片真实联调 PoC：2026-09-16 使用 GPT-5.5 端点完成标准 Base64 PNG
      输入，模型正确识别图片主色并正常返回文本；同时确认 GPT-5.5 使用
      `max_completion_tokens`，不接受旧 `max_tokens`
- [ ] 宿主服务获取 Azure Workload Identity 访问令牌的具体实现库与封装位置
      （遵循各服务现有依赖，不在 hub 里预设统一 Python 包）
- [ ] `MULTIMODAL` deprecated 兼容窗口结束的确切版本号
      （当前原则：保留一版，1.0 移除；若 semver 节奏调整需在服务仓库 release note 再确认）
