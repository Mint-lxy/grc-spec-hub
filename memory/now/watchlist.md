# 观察清单（Watchlist）

> 已知问题、技术债、悬而未决事项。digest 会把 commit 中出现
> TODO/FIXME/workaround 且讨论未闭环的项建议加入这里。

## 架构待确认（来源：ADR-001 §待确认）

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 1 | 【责任人：Zhang Hao】护栏检测服务实现（云原生 vs 自建） | PoC | ADR-001, spec 006 | open |
| 2 | BFF 层三选一——结论：保持 mgmt-service 同时承担 BFF 功能（用户确认 2026-08-14） | 架构决策 | ADR-001 | closed |
| 3 | 会话数据持久化归属——结论：mgmt-service 新增 chat-agent domain 直接存储会话数据（用户确认 2026-08-14） | 数据边界 | ADR-001, spec 001 | closed |
| 4 | Health Check 探测归属——结论：P0 不做周期探测，各服务自带 K8s liveness/readiness 探针即可（用户确认 2026-08-14） | P0 范围 | ADR-001, spec 002/009 | closed |
| 5 | mgmt-service 拆分时机——结论：当前不拆分，按 domain 内部隔离，domain 间不共享表、通过 service 方法调用（用户确认 2026-08-14） | 性能验证 | ADR-001 | closed |
| 6 | 模型凭据解析路径（agent→Nexus）——结论：通过 Python SDK 内部转换调用，转换依赖 auth-service 密钥转换接口（用户确认 2026-08-14） | 架构决策 | ADR-001, spec 007 AC-21 | closed |
| 7 | Gateway 运行时状态投影机制——结论：拉取 mgmt 资产清单 API，Redis + 本地双层缓存，~30s TTL（用户确认 2026-08-14） | 架构决策 | ADR-001, spec 004/006/008 | closed |
| 8 | Knowledge→MCP 导入凭据注入方——结论：mcp-server 自行经 grc-ai-sdk 解析凭据，knowledge 只传 user context（用户确认 2026-08-14） | 依赖+凭据 | ADR-001, spec 005 AC-11 | closed |
| 9 | Knowledge→mgmt 隐藏依赖是否正式声明——结论：正式声明，Knowledge 需通过 mgmt-service 文件接口获取/下载文件（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D11, spec 008 | closed |
| 10 | 会话级知识库快照跨服务语义——原 2026-08-14「会话创建时缓存 KB ID 列表」结论已被 2026-08-21 设计变更取代；现行口径见 #31：取消会话级快照，检索时即时校验状态与权限 | API 设计 | ADR-001, spec 001 AC-10 | closed |
| 11 | Agent-service 事件消费方式——结论：不主动感知，下游调用失败时按统一错误码（ADR-002）降级提示（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D7 | closed |
| 12 | Eval→mgmt REST 消费声明——结论：改为事件驱动，eval 发 eval-completed 事件，mgmt 消费（用户确认 2026-08-14） | manifest 对齐 | ADR-001 D8 | closed |
| 31 | 会话 KB 快照缓存机制复核——已按「取消会话级快照」结论收敛：检索基于检索时刻的知识库状态与权限，ADR-001/ADR-007 中旧的缓存/快照表述已清理 | 架构决策复核 | ADR-001, ADR-007, spec 001 AC-10, spec 005 FR-034 | closed |

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
| 14 | Key Vault 集成方式与可行性——已确认（用户确认 2026-08-21，PRD §13.10 #2） | 外部依赖 | spec 000/007 | closed |
| 15 | 资产级服务凭据可行性（委派授权）——已确认（用户确认 2026-08-21，PRD §13.10 #10，含身份上下文传递与防篡改、滥用归因限流） | 外部依赖 | spec 003/007 | closed |
| 16 | 外部依赖契约与降级策略（Alice/Nexus/KV/A2A/MCP）——已确认（用户确认 2026-08-21，PRD §13.10 #16；模型类资源全部经 Nexus 供给） | 外部依赖 | spec 000 | closed |
| 17 | §9.10 参数基线逐项审定——已完成（2026-08-21 interview，28 行全部确认为工单基线；6 处调整：HC 周期 10min、检索按切片去重、会话删除按钮、PAT 永不过期、审批 3 级、目录分公共 5 层/我的 3 层；4 个待审定值落实：分享 20 人、名称 1–100/禁控制字符、收藏 50 个、构建并发 5 条） | 基线 | spec 000, PRD §13.10 #11 | closed |
| 18 | 分层留存与对话原文隐私合规——已确认（2026-08-22 BA 裁定）：审计与调用日志 3 年、对话内容与命中原文经脱敏/敏感字段遮蔽后保留 90 天、业务记录永久 | 合规 | spec 000, PRD §9.8/§13.10 #1 | closed |
| 19 | 会话级快照止损时效合规——经设计变更关闭：取消会话级快照，收敛事件立即生效（用户裁定 2026-08-21，PRD §13.10 #13） | 合规 | spec 001 | closed |
| 20 | 在途申请条款版本合规——已确认（用户确认 2026-08-21，PRD §13.10 #12） | 合规 | spec 002 | closed |
| 21 | 内容源权限放大合规——已确认（2026-08-22 BA 裁定）：接受「内容准入责任归建库方」现口径，P0 不同步来源系统文档级权限 | 合规 | spec 005, PRD §9.7/§13.10 #8 | closed |
| 22 | 测评模板初始阈值审定 | 基线 | spec 004 | open |
| 23 | Alice 同步周期与失败回滚——随 PRD §13.10 #16 确认关闭（2026-08-21） | 外部依赖 | spec 008 | closed |
| 29 | UI/UX 方案未定，阻塞前端工作——现只有 PRD §13.11 视觉与品牌基础规范（深色风格/主色/胶囊按钮/字体）与一份已过期的旧原型（`docs/prd/GRC_AI_Agent_Prototype_v1.html`），无信息架构/交互稿/组件规范；`grc-ai-portal` 的 `docs/design/` 为空 | 前端/设计 | grc-ai-portal, PRD §13.11 | open |
| 32 | 005 FR-013 与 PRD §9.7 冲突——已解决（用户裁定 2026-08-21）：新建库角色模型——建库时指定知识库 Owner+Deputy、平台据此调 Alice 建角色并授予、后续授予由知识库 Owner/Deputy 单级审批；PRD/CONTEXT/旅程/ADR-0013/005 已全链路修订 | spec 冲突 | spec 005, PRD §7 M4-5/§9.7, ADR-0013 | closed |
| 33 | 管理后台「准入测评模板维护」页面（PRD §5.2）的 spec 归属：004-publish 或 008-admin——待与开发团队/架构师讨论后补入对应 spec | spec 归属 | spec 004/008, PRD §5.2 | open |
| 34 | 005 User Story 优先级标注（P1/P2/P3，spec-kit 约定）与 PRD 的 P0/P1 批次同名不同义——建议改写为「高/中/低」避免工单拆分时误读 | 格式 | spec 005 | open |
| 35 | PRD §13.10 #3：知识目录与知识库权限细化规则——已确认（2026-08-22 BA 裁定）：目录级角色以 Alice 流程为主，平台仅展示权限 ID、申请入口与同步状态；知识库级维护角色保留 Owner/Deputy 单级审批 | 权限模型 | spec 005, PRD §9.7, ADR-0006 | closed |
| 36 | PRD §13.10 #4：平台事件响应手段边界——已确认（2026-08-22 BA 裁定）：维持现边界，管理员可停用出站调用但不改变资产状态、不承诺阻断直连调用；孤儿资产补员恢复治理 | 合规 | spec 004/008, PRD §9.1, ADR-0009 | closed |
| 37 | PRD §13.10 #5：P1 自助测评需求范围——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不细化模板体系、数据集管理与对比报告范围 | P1 规划 | spec 004 | closed |
| 38 | PRD §13.10 #6：临时文件上传（P1）的护栏检测时机——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定解析与检测时机 | P1 规划 | spec 001, PRD §9.5 | closed |
| 39 | PRD §13.10 #7：库内重复文档识别（P1）相似度口径与处置形态——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定口径、阈值与处置形态 | P1 规划 | spec 005 | closed |
| 40 | PRD §13.10 #9：导入通道定时同步（P1）凭据主体与「配置人离职中断」风险处置——已确认（2026-08-22 BA 裁定）：使用配置人个人出站凭据；配置人账号停用/离职/凭据失效时同步暂停并通知知识库 Owner/Deputy | P1 规划 | spec 005 | closed |
| 41 | PRD §13.10 #14：申请人撤回订阅申请是否纳入——已确认（2026-08-22 BA 裁定）：P0 不纳入，待审批申请无申请人出边 | 产品决策 | spec 002, PRD §9.2 | closed |
| 42 | PRD §13.10 #15：审批停滞兜底——已确认（2026-08-22 BA 裁定）：P0 不补系统催办或超时回落；在职但长期不处理由人工沟通解决，死锁回落仅覆盖账号失效 | 产品决策 | spec 002, PRD §9.2 | closed |
| 43 | `spec-sync-prd-v1.2` 分支已并入 main：PRD v1.2 同步 + §13.10 五项澄清 + 002/005 grill 细化已成为主分支基线；合并等待项关闭 | 评审合并 | specs/001–009, docs/prd, memory/now | closed |
| 44 | 【BA 跟进】非 002/005 spec 未决项继续跟踪：001 模型兜底 UX/输出缓冲首段延迟；003 动态凭据校验深度/Agent Card 重试；004 裁判模型算力并发；006 护栏性能基准/违禁词上限；007 SDK 凭据缓存 TTL；008 平台资源监控告警；009 通知去重/抑制间隔 | BA 跟进 | specs/001/003/004/006/007/008/009 各「未决问题」或 plan 待确认节 | open |
| 45 | 【责任人：Zhang Hao】ADR-007（A2A 协议统一，状态 Proposed）需决策是否 Accept：若 Accept，grc-agent-service 自定义 REST+SSE 端点将替换为 A2A handler（`/.well-known/agent.json` + `POST /a2a`），mgmt-service chat-agent domain 需新增 A2A 客户端，gateway 路由与 `grc-agent-service.yaml` 契约需整体调整；当前不动代码，等 ADR Accept 后再改 | 架构决策 | ADR-007, spec 001, grc-agent-service, grc-mgmt-service, grc-api-gateway | open |
| 46 | 【责任人：Zhang Hao】服务 owner 仍为 `@todo-owner`，需填实 `architecture/services.manifest.yaml` 与 `architecture/service-map.md` 的 9 个服务负责人；否则工单认领、契约消费方确认与人审守门点缺少责任闭环 | 责任归属 | architecture/services.manifest.yaml, architecture/service-map.md | open |
| 47 | 【责任人：Zhang Hao】架构/API/横切规范未决项需统一收敛：api-landscape 待评审 11 项、认证授权横切规范、可观测性状态、000-platform plan 中护栏执行与 CI/CD、契约骨架填充优先级；需形成 plan 阶段输入或拆分工单 | 架构/API/横切 | specs/000-platform/api-landscape.md, architecture/cross-cutting/auth.md, architecture/cross-cutting/observability.md, specs/000-platform/plan.md, contracts/ | open |
| 48 | `check-contracts.sh` 未通过（2026-08-22）：`contracts/_example/openapi/example.yaml` security-defined；`contracts/openapi/grc-mcp-server.yaml` YAML 解析失败（313:64）；`contracts/openapi/grc-agent-service.yaml` security-defined；`contracts/openapi/grc-knowledge-engine.yaml` YAML 解析失败（109:32）；`contracts/openapi/grc-auth-service.yaml` struct/security-defined；`contracts/openapi/grc-mgmt-service.yaml` 语法通过但有 warnings。当前 PRD/spec 微调已避免破坏性契约字段删除或重命名；上述失败需另行修复或建立 lint baseline | 契约门禁 | contracts/, gates/scripts/check-contracts.sh, contracts/POLICY.md, architecture/service-map.md | open |

## 文档缺口

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 30 | API 成功响应包络（`ApiResponse`）已规范——ADR-006 定义统一包络（`code:0` 为成功），`error-codes.md` §1 补充成功响应格式与分页结构（2026-08-21） | 文档缺口 | architecture/adr/006-api-response-envelope.md, architecture/cross-cutting/error-codes.md | closed |
