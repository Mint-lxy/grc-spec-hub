# 观察清单（Watchlist）

> 已知问题、技术债、悬而未决事项。digest 会把 commit 中出现
> TODO/FIXME/workaround 且讨论未闭环的项建议加入这里。

## 架构待确认（来源：ADR-001 §待确认）

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 1 | 护栏检测服务实现（云原生 vs 自建） | PoC | ADR-001, spec 006 | open |
| 2 | BFF 层三选一——结论：保持 mgmt-service 同时承担 BFF 功能（用户确认 2026-08-14） | 架构决策 | ADR-001 | closed |
| 3 | 会话数据持久化归属——结论：mgmt-service 新增 chat-agent domain 直接存储会话数据（用户确认 2026-08-14） | 数据边界 | ADR-001, spec 001 | closed |
| 4 | Health Check 探测归属——结论：P0 不做周期探测，各服务自带 K8s liveness/readiness 探针即可（用户确认 2026-08-14） | P0 范围 | ADR-001, spec 002/009 | closed |
| 5 | mgmt-service 拆分时机——结论：当前不拆分，按 domain 内部隔离，domain 间不共享表、通过 service 方法调用（用户确认 2026-08-14） | 性能验证 | ADR-001 | closed |
| 6 | 模型凭据解析路径（agent→Nexus）——结论：通过 Python SDK 内部转换调用，转换依赖 auth-service 密钥转换接口（用户确认 2026-08-14） | 架构决策 | ADR-001, spec 007 AC-21 | closed |
| 7 | Gateway 运行时状态投影机制——结论：拉取 mgmt 资产清单 API，Redis + 本地双层缓存，~30s TTL（用户确认 2026-08-14） | 架构决策 | ADR-001, spec 004/006/008 | closed |
| 8 | Knowledge→MCP 导入凭据注入方——结论：mcp-server 自行经 grc-ai-sdk 解析凭据，knowledge 只传 user context（用户确认 2026-08-14） | 依赖+凭据 | ADR-001, spec 005 AC-11 | closed |
| 9 | Knowledge→mgmt 隐藏依赖是否正式声明——结论：正式声明，Knowledge 需通过 mgmt-service 文件接口获取/下载文件（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D11, spec 008 | closed |
| 10 | 会话级知识库快照跨服务语义——结论：agent 会话创建时缓存 KB ID 列表，检索时传列表（用户确认 2026-08-14） | API 设计 | ADR-001, spec 001 AC-10 | closed |
| 11 | Agent-service 事件消费方式——结论：不主动感知，下游调用失败时按统一错误码（ADR-002）降级提示（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D7 | closed |
| 12 | Eval→mgmt REST 消费声明——结论：改为事件驱动，eval 发 eval-completed 事件，mgmt 消费（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D8 | closed |

## 环境与账号前置依赖

| # | 项目 | 类型 | 关联 | 责任方 | 状态 |
|---|------|------|------|--------|------|
| 24 | 开发人员 GitHub 账号开通——已完成（用户确认 2026-08-17） | 账号 | 全服务 | `[待确认]` | closed |
| 25 | Alice 应用 admin 账号申请（阻塞 SSO 集成调研验证）——最晚下周二 (2026-08-19) | 账号+集成 | spec 000/007, auth-service | `[待确认]` | open |
| 26 | Azure 账号→SharePoint 方案落地（进行中） | 基础设施 | spec 005 AC-10, mcp-m365-server | `[待确认]` | in-progress |
| 27 | Nexus Teams 创建 + 模型订阅 + 支持模型列表对齐 | 外部依赖 | spec 001/004, agent-service, eval-service | `[待确认]` | closed |
| 28 | Nexus 缺少多模态/OCR 模型，需自行部署（用户指令 2026-08-14） | 外部依赖 | parser-engine, knowledge-engine | `[待确认]` | open |

## Spec 高优未决（来源：各 spec §4）

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 13 | M1/M2/M3 里程碑日期 | 计划 | spec 000 | open |
| 14 | Key Vault 集成方式与可行性 | 外部依赖 | spec 000/007 | open |
| 15 | 资产级服务凭据可行性（委派授权） | 外部依赖 | spec 003/007 | open |
| 16 | 外部依赖契约与降级策略（Alice/Nexus/KV/A2A/MCP） | 外部依赖 | spec 000 | open |
| 17 | 容量与默认参数基线 26 项审定 | 基线 | spec 000 | open |
| 18 | 分层留存与对话原文隐私合规 | 合规 | spec 000 | open |
| 19 | 会话级快照止损时效合规 | 合规 | spec 001 | open |
| 20 | 在途申请条款版本合规 | 合规 | spec 002 | open |
| 21 | 内容源权限放大合规 | 合规 | spec 005 | open |
| 22 | 测评模板初始阈值审定 | 基线 | spec 004 | open |
| 23 | Alice 同步周期与失败回滚 | 外部依赖 | spec 008 | open |
| 29 | UI/UX 方案未定，阻塞前端工作——现只有 PRD §13.11 视觉与品牌基础规范（深色风格/主色/胶囊按钮/字体）与一份已过期的旧原型（`docs/prd/GRC_AI_Agent_Prototype_v1.html`），无信息架构/交互稿/组件规范；`grc-ai-portal` 的 `docs/design/` 为空 | 前端/设计 | grc-ai-portal, PRD §13.11 | open |

## 文档缺口

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 30 | API 成功响应包络（`ApiResponse`）未正式规范——`error-codes.md` 已定义错误响应格式（RFC 9457），但成功响应只在 `api-landscape.md` 提了一句"服务统一返回 `ApiResponse` 包络"，无 schema/字段定义/ADR，示例响应（如 `/auth/logout`）字段与错误格式不一致 | 文档缺口 | architecture/cross-cutting/error-codes.md, specs/000-platform/api-landscape.md | open |
