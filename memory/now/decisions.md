# 现行有效决策（摘要）

> 每条一行，指向权威 ADR。被替代的决策移入 `../archive/decisions-superseded.md`。
> 新 ADR 合并时在此增补一行（宪法第五条 / PIPELINE 写入入口 ③）。

| 决策 | 摘要 | ADR | 生效日期 |
|------|------|-----|----------|
| 服务拆分 | 8 服务 + 前端架构，mgmt-service 大后端内部模块化+BFF+chat-agent domain，模型凭据经 AI SDK+auth-service，gateway 拉取缓存 30s TTL，eval 事件驱动回写，agent 不订阅事件（12/12 待确认项已关闭 11 项） | [ADR-001](../../architecture/adr/001-service-split.md) | 2026-08-13 |
| 错误码统一规范 | RFC 9457 错误格式 + 按模块注册前缀 + 类别分级 + 幂等/超时约定 | [ADR-002](../../architecture/adr/002-error-codes.md) | 2026-08-13 |
| AI SDK | grc-ai-sdk 将凭据解析与模型调用合并，提供 llm/embedding/rerank typed methods，规范类型归一化，provider adapter 先只实现 Nexus | [ADR-003](../../architecture/adr/003-ai-sdk.md) | 2026-08-14 |
| API 设计自顶向下 | 三阶段流程：全局概览（api-landscape.md）→ 评审确认 → 逐 feature 契约化，先对齐服务边界再写 contract | [ADR-004](../../architecture/adr/004-api-design-top-down.md) | 2026-08-17 |
| 凭据解析归属 | 凭据解析归 mgmt-service，双接口分离（平台凭据解析 + 个人凭据解析） | [ADR-005](../../architecture/adr/005-credential-resolution.md) | 2026-08-17 |
| 统一成功响应包络 | ApiResponse 统一包络（code:0 成功、data 载荷、分页结构），SSE 流式端点豁免 | [ADR-006](../../architecture/adr/006-api-response-envelope.md) | 2026-08-21 |
| A2A 协议统一（**Proposed，待 Accept**——watchlist #45，spec 001 plan 前置） | agent-service 只暴露 A2A 端点（`/.well-known/agent.json` + `POST /a2a`），mgmt-service 为前端提供自定义对话接口 | [ADR-007](../../architecture/adr/007-a2a-protocol.md) | 2026-08-21 |
| 平台资源与模型凭据解析 | 平台资源不是资产；实例类资源进注册表并按资源逐人授权；模型类调用经 Nexus，按触发人解析个人模型凭据优先、平台默认兜底；2026-08-24 008 clarify 补充：P0 模型清单/启用态/默认模型部署内置只读，模型默认凭据仅引用注册表中的平台内部 Nexus 凭据对象 | [hub ADR-005](../../architecture/adr/005-credential-resolution.md) | 2026-08-21 / 2026-08-24 |
| 资产调用凭据模型反转 | 旧资产凭据模型取消；一切资产调用使用订阅者个人凭据；创建者只声明凭据元数据且全程不接触密钥值；静态凭据由订阅者填入绑定，动态凭据由订阅成功后平台代颁发入库；不回落任何共享身份 | [hub ADR-005](../../architecture/adr/005-credential-resolution.md) | 2026-08-24 |
