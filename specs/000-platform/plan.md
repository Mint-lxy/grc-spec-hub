# Plan 000 — 平台总体技术选型

> 对应 spec：`specs/000-platform/spec.md`
> 这是各 feature `plan.md` 的上位技术约束。

## 1. 方案概述

采用微服务架构，以平台网关为统一入口（护栏检测、凭据解析、审计、流式输出缓冲）。后端服务按业务能力拆分，各服务间通过 REST API 同步通信、事件总线异步通信。认证依托企业 Alice（SSO）体系，密钥托管依托企业 Key Vault，模型调用经由企业 Nexus 网关。前端为单页应用。

## 2. 涉及服务

平台级 plan 覆盖全部服务，清单见 `architecture/service-map.md`。

## 3. 契约影响

定义**契约技术栈**（feature 契约必须遵循）：
- REST：OpenAPI 3.1（`contracts/openapi/`）
- 事件：AsyncAPI 2.x（`contracts/events/`）
- 共享模型：JSON Schema（`contracts/shared/`）
- 兼容性政策：见 `contracts/POLICY.md`

## 4. 平台级技术决策

| 主题 | 选型 | 说明/ADR |
|------|------|----------|
| 运行时/语言 | [待确认] | 建议后端 Java/Python；前端 React/TypeScript |
| 服务间通信 | REST + 事件 | 同步调用 REST、异步通知经事件总线 |
| 消息中间件 | Azure Service Bus | Azure Service Bus |
| 认证 | Alice（SSO）+ PAT（入站） | cross-cutting/auth.md |
| 模型网关 | Nexus | 企业统一模型调用入口 |
| 密钥托管 | 企业 Key Vault | 密钥库以 Key Vault 为底层存储 |
| 向量数据库 | Milvus / PGVector（P0）/ Azure AI Search（P1） | ADR-0013 |
| 向量化模型 | [待确认]  | 知识库级锁定 |
| 文档解析器 | Docling / MinerU / Azure Document Intelligence（P1） | 知识管线 |
| 护栏执行 | [待确认]  | ADR-0008；命中即拦截 |
| 可观测性 | langfuse | cross-cutting/observability.md |
| CI/CD | [待确认]（门禁默认本地脚本，见 gates/） | gates/GATES.md |

## 5. 测试策略（平台基线）

- 契约一致性是跨服务的强制门禁：hub 侧 `gates/scripts/check-contracts.{ps1,sh}`，
  服务侧 provider/consumer 契约测试（见 `gates/GATES.md`）。
- 其余分层策略见 `standards/testing.md`。
- 质量门控按资产类型参数化（Agent 七项 / MCP 六项），为硬阻断。

## 6. 风险与回滚

| 风险 | 缓解 |
|------|------|
| 服务边界划错导致频繁跨服务改动 | 第 3–4 周用真实跨服务 spec 验证边界 |
| 记忆腐化 | memory-digest 管线 + 门禁提醒 |
| Key Vault 集成可行性不确定 | 开工前需与 Key Vault 服务方确认集成方式|
| 带资进组的资源组角色控制层面不确定性 | 开工前需逐类验证鉴权要求 |
| 外部依赖（Alice/Nexus/Key Vault）不可达 | 开工前定义各外部依赖的契约假设与降级策略|
| 护栏全文缓冲增加首段延迟 | 网关缓冲→检测→按段回放；延迟含全文生成与检测时长，需性能测试确认可接受范围 |
