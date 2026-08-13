# 观察清单（Watchlist）

> 已知问题、技术债、悬而未决事项。digest 会把 commit 中出现
> TODO/FIXME/workaround 且讨论未闭环的项建议加入这里。

## 架构待确认（来源：ADR-001 §待确认）

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 1 | 护栏检测服务实现（云原生 vs 自建） | PoC | ADR-001, spec 006 | open |
| 2 | BFF 层三选一 | 架构决策 | ADR-001 | open |
| 3 | 会话数据持久化归属 | 数据边界 | ADR-001, spec 001 | open |
| 4 | Health Check 探测归属 | P0 范围 | ADR-001, spec 002/009 | open |
| 5 | mgmt-service 拆分时机 | 性能验证 | ADR-001 | open |
| 6 | 模型凭据解析路径（agent→Nexus） | 架构决策 | ADR-001, spec 007 AC-21 | open |
| 7 | Gateway 运行时状态投影机制 | 架构决策 | ADR-001, spec 004/006/008 | open |
| 8 | Knowledge→MCP 导入凭据注入方 | 依赖+凭据 | ADR-001, spec 005 AC-11 | open |
| 9 | Knowledge→mgmt 隐藏依赖是否正式声明 | manifest 对齐 | ADR-001 D11, spec 008 | open |
| 10 | 会话级知识库快照跨服务语义 | API 设计 | ADR-001, spec 001 AC-10 | open |
| 11 | Agent-service 事件消费方式 | manifest 对齐 | ADR-001 D7 | open |
| 12 | Eval→mgmt REST 消费声明 | manifest 对齐 | ADR-001 D8 | open |

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
