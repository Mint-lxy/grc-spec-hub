# Plan 000 — 平台总体技术选型

> 对应 spec：`specs/000-platform/spec.md`
> 这是各 feature `plan.md` 的上位技术约束。

<!--
第 0 周与总体 spec 一同产出。这里定"平台级"选型，feature plan 不得与之冲突。
-->

## 1. 方案概述

<平台整体技术路线一段话。> `[待确认]`

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
| 运行时/语言 | `[待确认]` | |
| 服务间通信 | REST + 事件 | ADR-000x |
| 消息中间件 | `[待确认]` | |
| 认证 | `[待确认]` | cross-cutting/auth.md |
| 可观测性 | `[待确认]` | cross-cutting/observability.md |
| CI/CD | `[待确认]`（可选；门禁默认本地脚本，见 gates/） | gates/GATES.md |

## 5. 测试策略（平台基线）

- 契约一致性是跨服务的强制门禁：hub 侧 `gates/scripts/check-contracts.{ps1,sh}`，
  服务侧 provider/consumer 契约测试（见 `gates/GATES.md`）。
- 其余分层策略见 `standards/testing.md`。

## 6. 风险与回滚

| 风险 | 缓解 |
|------|------|
| 服务边界划错导致频繁跨服务改动 | 第 3–4 周用真实跨服务 spec 验证边界 |
| 记忆腐化 | memory-digest 管线 + 门禁提醒 |
