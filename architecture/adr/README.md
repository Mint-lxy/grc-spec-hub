# architecture/adr — 平台级架构决策记录

只记录**跨服务**的决策。服务内部决策放各服务仓库的 `docs/adr/`。

- 新决策：复制 `template.md` 为 `NNN-<slug>.md`，编号自增。
- 被替代：把旧 ADR 状态改为 `Superseded by ADR-XXX`，并在
  `memory/archive/decisions-superseded.md` 记一条（含替代原因），
  同时更新 `memory/now/decisions.md` 的摘要行。

| 编号 | 标题 | 状态 | 日期 |
|------|------|------|------|
| [001](001-service-split.md) | 服务拆分——以 C4 容器为基线的八服务架构 | Accepted | 2026-08-13 |
| [002](002-error-codes.md) | 统一错误码与错误响应规范 | Proposed | 2026-08-13 |
| [003](003-ai-sdk.md) | AI SDK——凭据解析与模型调用统一抽象 | Proposed | 2026-08-14 |
| [004](004-api-design-top-down.md) | API 设计采用自顶向下流程——先全局概览再逐服务契约化 | Accepted | 2026-08-17 |
| [005](005-credential-resolution.md) | 凭据解析归属 mgmt-service，双接口分离资产与模型两条路径 | Accepted | 2026-08-17 |
| [006](006-api-response-envelope.md) | 统一成功响应包络（ApiResponse）规范 | Accepted | 2026-08-21 |
| [007](007-a2a-protocol.md) | grc-agent-service 统一采用 A2A 协议，mgmt-service 为前端提供自定义接口 | Proposed | 2026-08-21 |
