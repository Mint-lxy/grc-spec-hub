# ADR-007: grc-agent-service 统一采用 A2A 协议，mgmt-service 为前端提供自定义接口

> 状态：Proposed
> 日期：2026-08-21 · 决策者：@nzhang · 关联 spec：`specs/001-conversation`

## 背景

grc-agent-service 当前 api-landscape 设计中直接对前端暴露自定义 REST+SSE 端点（`POST /chat/sessions/{id}/messages`），
同时 PRD 已将 A2A 列为平台协议。agent-service 作为无状态推理引擎（ADR-001），不持有会话/消息等业务表，
会话持久化与上下文管理已归 mgmt-service chat-agent domain（ADR-001 D3）。
若 agent-service 同时维护自定义端点与 A2A 端点，会出现两套协议并存的维护负担，
且前端直连 agent-service 导致会话上下文的获取和消息持久化需要 agent-service 反向调用 mgmt-service。

## 决策

- **grc-agent-service 只暴露 A2A 协议端点**（`/.well-known/agent.json` + `POST /a2a`），不再提供自定义 REST 路由。支持流式（`tasks/sendSubscribe`，SSE）和非流式（`tasks/send`，同步 JSON）两种模式。
- **grc-mgmt-service（chat-agent domain）为前端提供自定义接口**（`POST /mgmt/chat/sessions/{id}/messages` 等），内部通过 A2A 协议调用 agent-service，负责会话上下文组装、消息持久化、知识库挂载快照管理。
- 外部系统与 Agent 间集成同样通过 A2A 端点，由 gateway 路由。

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| agent-service 同时维护自定义端点 + A2A 端点 | 前端直连 agent-service 省一跳 | 两套协议维护成本；agent-service 无状态却需反调 mgmt 获取上下文与持久化消息，职责倒挂 | 违反 ADR-001 的无状态定位，增加耦合 |
| 不采用 A2A、仅保留自定义 REST+SSE | 无协议学习成本 | 外部系统需逐一适配私有接口；与 PRD A2A 承诺不符；无标准 Agent Card 发现机制 | 不满足平台开放定位 |
| 前端直连 A2A 端点（不经 mgmt-service） | 减少中间层 | 前端需实现 A2A 客户端；会话管理/持久化/上下文组装无处安放 | A2A 面向 Agent 间调用设计，非面向 UI |

## 影响

- 受影响服务：grc-agent-service（移除自定义 `/chat/` 端点、仅实现 A2A handler）、grc-mgmt-service（chat-agent domain 新增前端对话接口、内部 A2A 客户端）、grc-api-gateway（调整路由：前端对话走 mgmt，A2A 发现与直调走 agent-service）
- 契约影响：`contracts/openapi/grc-agent-service.yaml` 替换为 A2A 协议定义；mgmt-service 契约新增 `/mgmt/chat/` 前端对话端点
- api-landscape.md 需同步更新：agent-service 段改为 A2A 端点、mgmt-service 段新增 chat 端点
- 迁移/回滚：当前均为 Draft 阶段，无存量端点需迁移

## 后果

### 正面
- agent-service 职责纯粹化：只做推理，不关心会话管理与持久化
- mgmt-service 统一掌控会话全生命周期，上下文组装与消息持久化在同一服务完成，无跨服务反调
- 外部系统与内部前端走不同入口但共享同一推理引擎

### 负面
- 前端对话请求多经一跳 mgmt → agent-service（增加约 5–10ms 延迟）
- mgmt-service 需实现 A2A 客户端（含 SSE 转发逻辑）

### 风险
- A2A 规范仍在演进 → 锁定基线版本，Agent Card 中声明协议版本，后续升级走 ADR
