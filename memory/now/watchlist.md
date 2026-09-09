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
| 63 | 【责任人：架构/开发】统一数据清理任务机制细化——2026-08-25 会议裁定+用户 grill-me 裁定：平台数据（知识库/对话记录/审计日志）到期或删除后的物理清理由平台统一定时清理任务执行、禁止人工直接操作数据库、需状态监控+失败告警+执行结果记录（spec 000 AC-G8）；任务调度方式、执行频率、告警通道与失败重试策略待 plan 阶段确认 | 架构决策 | spec 000 AC-G8, spec 005 FR-042, spec 001 FR-031 | open |
| 68 | 【责任人：架构/开发】默认构建配置性能与并发适用性评估——2026-08-25 会议：大量文档统一用语义切分对 embedding 模型与构建 pipeline 的压力、平台并发构建能力有限；一期采用静态平台默认配置（spec 005 FR-010），按文档类型动态推荐/算子路由为 P1 扩展点；需评估一套通用、经济、高效的默认配置并压测验证 | 性能评估 | spec 005 FR-010/FR-038 | open |
| 72 | 【责任人：BA+架构】完善子级目录创建与编辑规则——创建时分别配置「目录控制权限」与「知识库创建权限」两个角色，每个角色设置 2–3 名审批人；创建后仅允许修改目录名称，`Location` 与权限配置不可编辑；字段、角色及不可编辑约束需确认并同步相应 spec/契约（来源：2026-08-28 用户提供的会议待办）。**已关闭（2026-09-01 用户指令）** | 权限模型 | spec 005, spec 008, contracts/ | closed |
| 74 | 【责任人：架构/开发+运维】梳理目录层级调整的运维 SOP——明确标准流程、风险、审批与影响范围；会议提出后台数据库操作，但不得覆盖 spec 000 AC-G8/watchlist #63「禁止人工直接操作数据库」的既有基线，需优先确认是否应通过受控管理接口、迁移任务或自动化作业实施（来源：2026-08-28 用户提供的会议待办） | 运维治理 | spec 000 AC-G8, spec 005, watchlist #63, sop/ | open |
| 81 | 【责任人：架构/开发】Alice 知识库角色有效权限的落地机制——业务语义已由 2026-09-01 用户裁定为 `Owner ⊇ Contributor ⊇ Consumer`，Owner 无需单独申请 Contributor（spec 005 FR-009c）；待架构/开发确认 Alice 侧采用角色继承、权限并集或自动附加角色的实现方式，并走相应契约变更流程 | 架构决策 | spec 005 FR-009c, Alice, watchlist #73 | open |
| 84 | 【责任人：架构/开发】Alice 公共知识库角色申请与同步的落地机制——2026-09-04 用户裁定：平台仅展示权限 ID 与 Alice 申请入口，角色申请、审批、授予与回收均在 Alice；仅 Alice 批准并同步有效后可用。待确认权限 ID 与角色的映射、跳转形态、申请/同步状态获取、延迟与失败提示以及跨服务契约，须走 contract-change 流程 | 架构决策 | spec 005 FR-008/FR-009/FR-059/FR-060, Alice, contracts/ | open |

## 环境与账号前置依赖

| # | 项目 | 类型 | 关联 | 责任方 | 状态 |
|---|------|------|------|--------|------|
| 24 | 开发人员 GitHub 账号开通——已完成（用户确认 2026-08-17） | 账号 | 全服务 | `[待确认]` | closed |
| 25 | Alice 应用 admin 账号申请（阻塞 SSO 集成调研验证）——原目标最晚 2026-08-19，2026-08-24 watchlist 质量复核未见最新状态；下一步需补申请状态、新目标日期与责任人 | 账号+集成 | spec 000/007, auth-service | `[待确认]` | open |
| 26 | Azure 账号→SharePoint 方案落地（进行中）——2026-08-24 watchlist 质量复核未见最新检查点；下一步需补落地负责人、当前阶段与下一检查点 | 基础设施 | spec 005 AC-10, mcp-m365-server | `[待确认]` | open |
| 27 | Nexus Teams 创建 + 模型订阅 + 支持模型列表对齐 | 外部依赖 | spec 001/004, agent-service, eval-service | `[待确认]` | closed |
| 28 | Nexus 缺少多模态/OCR 模型，需自行部署（用户指令 2026-08-14）——下一步需确认自部署模型方案、责任人、目标日期与是否影响 P0 交付 | 外部依赖 | parser-engine, knowledge-engine | `[待确认]` | open |
| 73 | 确认 Alice 集成方案——**已关闭（2026-09-01 用户裁定）**：知识库有效权限采用 `Owner ⊇ Contributor ⊇ Consumer`；Owner 无需向 Alice 单独申请 Contributor；公共目录建库的创建角色持有人未被指定为 Owner/Deputy 时仅保留读取、检索与详情只读权限；所有已登录用户默认获得 Viewer 最小视图，完全隐藏知识库不因该默认角色可发现；组织用户账号仍由 Alice 同步为只读视图；Add Documents 的定时同步仅保留 `Schedule`，移除重复的 `Refresh Frequency`。已回写 spec 005。Alice 侧具体采用角色继承、权限并集或自动附加角色的技术实现转 #81 跟踪 | 外部集成/权限模型 | spec 005 FR-009c/FR-013c/FR-019/FR-037c~FR-037f, spec 008 FR-050, Alice, watchlist #81 | BA+架构/开发 | closed |
| 85 | 【责任人：parser-engine+运维】开发 AKS 已通过 spec 010 启用自管 NVIDIA Device Plugin；生产部署前需完成 NVIDIA Device Plugin/CUDA 镜像许可证审查，并决定是否另立 GPU 指标/DCGM 监控 spec | 基础设施/许可证/可观测性 | spec 010, grc-parser-engine | parser-engine+运维 | open |
| 86 | 【责任人：knowledge-engine+运维】开发 Milvus 已通过 spec 011 以 Standalone 单节点拓扑部署；生产前需独立设计 Milvus Cluster 高可用、备份恢复、RPO/RTO、多可用区、PVC 80% 告警和正式镜像许可证/漏洞审查 | 基础设施/容灾/可观测性 | spec 011, grc-knowledge-engine | knowledge-engine+运维 | open |

## Spec 高优未决（来源：各 spec §4）

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 13 | 【责任人待确认】M1/M2/M3 里程碑日期——下一步由项目计划负责人补齐目标日期、起算点与评审节奏 | 计划 | spec 000 | open |
| 14 | Key Vault 集成方式与可行性——已确认（用户确认 2026-08-21，PRD §13.10 #2） | 外部依赖 | spec 000/007 | closed |
| 15 | 旧资产凭据模型可行性（委派授权）——已确认（用户确认 2026-08-21，PRD §13.10 #10）；**2026-08-24 被凭据模型修订取代**（项目组对齐：旧资产凭据模型整体取消，一切资产调用使用订阅者个人凭据；替代口径由 `architecture/adr/005-credential-resolution.md` 承载，不新增单独 ADR） | 外部依赖 | spec 003/007, PRD §9.3, ADR-005 | closed |
| 16 | 外部依赖契约与降级策略（Alice/Nexus/KV/A2A/MCP）——已确认（用户确认 2026-08-21，PRD §13.10 #16；模型类资源全部经 Nexus 供给） | 外部依赖 | spec 000 | closed |
| 17 | §9.10 参数基线逐项审定——已完成（2026-08-21 interview，28 行全部确认为工单基线；6 处调整：HC 周期 10min、检索按切片去重、会话删除按钮、PAT 永不过期、审批 3 级、目录分公共 5 层/我的 3 层；4 个待审定值落实：分享 20 人、名称 1–100/禁控制字符、收藏 50 个、构建并发 5 条） | 基线 | spec 000, PRD §13.10 #11 | closed |
| 18 | 分层留存与对话原文隐私合规——已确认（2026-08-22 BA 裁定）：审计与调用日志 3 年、对话内容与命中原文经脱敏/敏感字段遮蔽后保留 90 天、业务记录永久 | 合规 | spec 000, PRD §9.8/§13.10 #1 | closed |
| 19 | 会话级快照止损时效合规——经设计变更关闭：取消会话级快照，收敛事件立即生效（用户裁定 2026-08-21，PRD §13.10 #13） | 合规 | spec 001 | closed |
| 20 | 在途申请条款版本合规——已确认（用户确认 2026-08-21，PRD §13.10 #12） | 合规 | spec 002 | closed |
| 21 | 内容源权限放大合规——已确认（2026-08-22 BA 裁定）：接受「内容准入责任归建库方」现口径，P0 不同步来源系统文档级权限 | 合规 | spec 005, PRD §9.7/§13.10 #8 | closed |
| 22 | 测评模板初始阈值审定——注意：Zhang Hao 在 main 登记的口径（「安全合规 ≥90% 硬门控；功能质量与性能基线 P0 仅展示不阻断」）与 PRD §9.4 三类模型（提示词注入/意图偏离/内容安全各自独立阈值、三类均达标才算通过）对不上，**待其说明来源后再定**（2026-08-24 用户对账决定）。2026-09-04 用户提供截图更新：9.11 上线版本不涉及，保留本项 | 基线 | spec 004, PRD §9.4 | open |
| 23 | Alice 同步周期与失败回滚——随 PRD §13.10 #16 确认关闭（2026-08-21） | 外部依赖 | spec 008 | closed |
| 29 | UI/UX 方案未定，阻塞前端工作——**已关闭（2026-08-31 用户指令）**：9/7 按照新版 UI/UX 上 Knowledge 部分 | 前端/设计 | grc-ai-portal, PRD §13.11 | closed |
| 32 | 005 FR-013 与 PRD §9.7 冲突——已解决（用户裁定 2026-08-21）：新建库角色模型——建库时指定知识库 Owner+Deputy、平台据此调 Alice 建角色并授予、后续授予由知识库 Owner/Deputy 单级审批；PRD/CONTEXT/旅程/ADR-0013/005 已全链路修订 | spec 冲突 | spec 005, PRD §7 M4-5/§9.7, ADR-0013 | closed |
| 33 | 管理后台「准入测评模板维护」页面归 008-admin；004 仅承载发布链路中的模板消费语义（2026-08-23 Zhang Hao 登记，2026-08-24 用户对账确认）；004 的对应 Open Question 已关闭 | spec 归属 | spec 004/008, PRD §5.2 | closed |
| 34 | 005 User Story 优先级标注（P1/P2/P3，spec-kit 约定）与 PRD 的 P0/P1 批次同名不同义——**已关闭（2026-09-01 用户裁定）**：约定沿用 2026-08-25 终审裁定「Delivery: <PRD 批次> + Story Order: S<n>」；剩余动作「005 按同约定改写」已完成——005 的 14 个 US 全部改写为 Delivery: P0, Story Order: S1–S14（依据 PRD v1.2 §8.4/M4：本 spec US 全部对应 P0，P1 项仅 Non-Goals 中的重复文档识别与检索测试）；008 此前已回写 | 格式 | spec 005/006/008 | closed |
| 35 | PRD §13.10 #3：知识目录与知识库权限细化规则——已确认（2026-08-22 BA 裁定）：目录级角色以 Alice 流程为主，平台仅展示权限 ID、申请入口与同步状态；知识库级维护角色保留 Owner/Deputy 单级审批。**其中知识库级维护角色审批结论已被 2026-09-04 用户裁定取代：申请、审批、授予与回收均在 Alice 流程完成，平台不实现站内审批或角色写入；后续技术落地见 #84。** | 权限模型 | spec 005 FR-009/FR-059/FR-060, PRD §9.7, ADR-0006, watchlist #84 | closed |
| 36 | PRD §13.10 #4：平台事件响应手段边界——已确认（2026-08-22 BA 裁定）：维持现边界，管理员可停用出站调用但不改变资产状态、不承诺阻断直连调用；孤儿资产补员恢复治理 | 合规 | spec 004/008, PRD §9.1, ADR-0009 | closed |
| 37 | PRD §13.10 #5：P1 自助测评需求范围——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不细化模板体系、数据集管理与对比报告范围 | P1 规划 | spec 004 | closed |
| 38 | PRD §13.10 #6：临时文件上传（P1）的护栏检测时机——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定解析与检测时机 | P1 规划 | spec 001, PRD §9.5 | closed |
| 39 | PRD §13.10 #7：库内重复文档识别（P1）相似度口径与处置形态——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定口径、阈值与处置形态 | P1 规划 | spec 005 | closed |
| 82 | 【责任人：BA】PRD/用户旅程与 Spec 005 的构建参数重建口径漂移——PRD v1.2 §6 J4/§7 M4 与用户旅程 v1.2 仍表述「库级参数保存后触发全库重建」；2026-09-01 用户裁定已将 spec 005 FR-039 收敛为仅构建类参数变更触发重建、全库重建须确认、检索类参数即时生效。基础文档不得反写，待 BA 按 PRD 升版流程裁定并正向同步 | 基线漂移 | docs/prd/GRC-AI-Foundation-Platform-PRD-v1.2.md §6 J4/§7 M4, docs/user_journey/AI_Foundation_Platform_User_Journey_v1.2.md, spec 005 FR-039, watchlist #70 | open |
| 83 | 【责任人：BA】PRD/用户旅程与 Spec 005 的知识库分享与角色申请口径漂移——2026-09-04 用户裁定：全知识库取消平台内分享；公共目录仅展示 Alice 权限 ID 与申请入口，申请须获 Alice 批准且平台同步有效后方可使用；我的目录仅创建者本人可用。基础文档不得反写，待 BA 按 PRD 升版流程裁定并正向同步 | 基线漂移 | docs/prd/GRC-AI-Foundation-Platform-PRD-v1.2.md §6 J4/§7 M4/§9.7, docs/user_journey/AI_Foundation_Platform_User_Journey_v1.2.md, spec 005 FR-008/FR-009/FR-011/FR-014/FR-058~FR-061 | open |
| 40 | PRD §13.10 #9：导入通道定时同步（P1）凭据主体与「配置人离职中断」风险处置——已确认（2026-08-22 BA 裁定）：使用配置人个人出站凭据；配置人账号停用/离职/凭据失效时同步暂停并通知知识库 Owner/Deputy | P1 规划 | spec 005 | closed |
| 41 | PRD §13.10 #14：申请人撤回订阅申请是否纳入——已确认（2026-08-22 BA 裁定）：P0 不纳入，待审批申请无申请人出边 | 产品决策 | spec 002, PRD §9.2 | closed |
| 42 | PRD §13.10 #15：审批停滞兜底——已确认（2026-08-22 BA 裁定）：P0 不补系统催办或超时回落；在职但长期不处理由人工沟通解决，死锁回落仅覆盖账号失效 | 产品决策 | spec 002, PRD §9.2 | closed |
| 43 | `spec-sync-prd-v1.2` 分支已并入 main：PRD v1.2 同步 + §13.10 五项澄清 + 002/005 grill 细化已成为主分支基线；合并等待项关闭 | 评审合并 | specs/001–009, docs/prd, memory/now | closed |
| 44 | 【BA 跟进】spec plan 参数子项跟踪（2026-08-24 watchlist 质量复核拆分）：① 004 裁判模型算力与并发配置（plan 阶段）；② 006 护栏性能基准（全文缓冲延迟、窗口检测延迟）；③ 006 违禁词表单表条目上限与单文件大小上限（审定后补 PRD §9.10）；④ 007 SDK 凭据解析缓存 TTL——**已裁定（2026-08-31 用户裁定）：phase1 暂定 60 秒**，已回写 spec 007，剩余动作仅剩补入 PRD §9.10 参数基线审定。已核销项不再跟踪：003 动态凭据校验深度、003 Agent Card/工具清单拉取失败自动重试（不自动重试）、009 通知去重/抑制；001 滑动窗口/首段延迟参数统一由 #50 跟踪 | BA 跟进 | specs/004/006/007；watchlist #50 | open |
| 45 | ADR-007（A2A 协议统一）——**已关闭（2026-08-31 用户指令）**：ADR-007 维持 Proposed 状态不升 Accepted，spec 001 按现有 Proposed 口径进 plan；契约影响（agent-service A2A handler、mgmt A2A 客户端、gateway 路由）在 plan 阶段落地，不再作为 spec 001 进 plan 的阻塞前置 | 架构决策 | ADR-007, spec 001 FR-021, grc-agent-service, grc-mgmt-service, grc-api-gateway | closed |
| 46 | 【责任人：Zhang Hao】服务 owner 仍为 `@todo-owner`，需填实 `architecture/services.manifest.yaml` 与 `architecture/service-map.md` 的 9 个服务负责人；否则工单认领、契约消费方确认与人审守门点缺少责任闭环 | 责任归属 | architecture/services.manifest.yaml, architecture/service-map.md | open |
| 47 | 【责任人：Zhang Hao】架构/API/横切规范未决项需统一收敛：api-landscape 待评审 11 项、认证授权横切规范、可观测性状态、000-platform plan 中护栏执行与 CI/CD、契约骨架填充优先级；需形成 plan 阶段输入或拆分工单 | 架构/API/横切 | specs/000-platform/api-landscape.md, architecture/cross-cutting/auth.md, architecture/cross-cutting/observability.md, specs/000-platform/plan.md, contracts/ | open |
| 48 | `check-contracts.sh` 未通过——已修复（2026-08-22，合入 main @ cb1c992）：mcp-server/knowledge-engine YAML 引号 ×3、auth-service 7 处 nullable 迁移 3.1 union type、8 处 security 声明补齐（内部服务根级 bearerAuth 对齐 mgmt，healthz/login/verify/refresh/oauth 显式 `security: []`）、saveDocumentChunk 补 chunkId 路径参数、npx 缓存清理、门禁脚本 oasdiff 误报修复（仅 error/warning 级判失败，.sh/.ps1 同步）。人工豁免：chunkId 补齐声明的 `new-request-path-parameter` flag 属无效契约修复，理由记录于合并提交 cb1c992 | 契约门禁 | contracts/, gates/scripts/check-contracts.sh, contracts/POLICY.md | closed |
| 49 | 远端 main 删除 `DELETE /mgmt/knowledge/knowledge-bases/{kbId}` 端点——**已确认（2026-08-31 用户确认）**：删除有意、消费方已知情 | 契约治理 | contracts/openapi/grc-mgmt-service.yaml, contracts/POLICY.md, architecture/service-map.md | closed |
| 50 | 【责任人：Zhang Hao】【plan 阶段输入/待确认】输出侧护栏机制基线已采纳（2026-08-24 用户裁定）：流式响应＝重叠滑动窗口检测、非流式＝全文缓冲；**命中坚持全文零字留存**——命中时终止上游并瞬时撤回全部已下发内容（含已通过窗口的前缀）、展示安全护栏命中提醒。命中提醒形态已裁定为占位替换＋护栏类型，不再由本项跟踪；待 plan/压测确认窗口大小、重叠长度、检测位置、检测超时、首段延迟、长响应上限与实现可行性；引擎 SaaS/自建见 #1；main 上 Zhang 版含前缀保留口径已被本裁定取代 | 架构/性能 | spec 001 FR-022/FR-023, spec 006 FR-042/FR-043, watchlist #1 | open |
| 51 | 【责任人：Li Zhonghao】spec 005 构建管线改动需开发侧跟进（2026-08-23 BA Lead 复核裁定）：① 解析器收敛为 Docling/MinerU，不使用 DeepDoc——实现快照 `Implementation-Snapshot/KB-coding/knowledge-engine` 的 `pipeline_config_validator.py` 合法解析器集合与两份 Api 清单中的 deepdoc 参数需移除；② 切片/增强/解析器/向量化/重排序参数矩阵（FR-038）请审阅可行性；③ 语言提示为中文/英文/德语/自动检测 | 开发跟进 | spec 005 FR-038, Implementation-Snapshot/KB-coding | open |
| 52 | 【架构/开发待确认】准入测评任务整体超时上限——2026-08-23 spec 004 澄清建议值 30 分钟（超时视同执行失败、可重测）；需架构/开发确认可行性后补入 PRD §9.10 参数基线审定，审定前不作为工单基线 | 基线 | spec 004 FR-010, PRD §9.4/§9.10 | open |
| 53 | MCP 协议枚举 P0 单值「Streamable HTTP」——已确认（Zhang Hao 2026-08-23 审核通过：不兼容旧版 SSE，字段保留枚举结构供未来扩展）；003 对应 Open Question 随之关闭（2026-08-24 对账） | 技术审核 | spec 003 FR-013 | closed |
| 54 | 通知事件归类一揽子裁定——**已关闭**：P0 十三类设计全集确认；新增/补齐类为「资产治理通知」，载荷为中止发布与发布失败；受众按阶段分层（首发前：创建者 + 草稿协作者；首发后：Owner/Deputy）；旧资产凭据更新载荷已随凭据模型修订取消；资产删除不通知。已回写 PRD M9-1、spec 009 FR-033/FR-034 与 spec 004 发布失败/中止发布触发语义 | spec 对齐 | spec 009 FR-033, spec 004 FR-018/FR-042, PRD M9-1 | closed |
| 55 | spec 002/003/004 peer review 与终审——**已关闭（2026-08-23）**：Zeng Ziyang grill 复核 003/004（提交 4b1c90f/57f3008，补入 FR-041~045 等）；用户终审 13 项逐项裁定——采纳 FR-041/042/043/044/045 与版本号/说明口径转正，确认两项自我推翻项（中止不留痕、重测不收紧），驳回 HC 暂缓（#56 关闭），002 增补由用户终审追认；002 维持 Reviewed，003/004 升 Reviewed | 评审 | specs/002/003/004 | closed |
| 56 | Health Check 开关存废分歧——**已关闭（2026-08-23 用户终审）**：维持「HC 强制必选、消除开关」，驳回 peer review 暂缓；补充理由：HC 可关闭则资产失效无法触达时订阅者与平台无从知晓实际服务健康状态；spec 003 FR-007/FR-013 与 PRD 强制表述维持，无回滚 | spec 分歧 | spec 003 FR-007/FR-013, PRD v1.2 版本说明 2026-08-23 补遗 | closed |
| 57 | 原催办已拆分（2026-08-23/24）：#50 的护栏处理机制已裁定（流式滑动窗口/非流式全文；命中零字留存+撤回前缀为用户终审口径），剩余参数转为 plan 阶段输入；spec 001 进 plan 的架构前置仅剩 #45（ADR-007 是否 Accept） | 催办 | watchlist #45/#50, spec 001, ADR-007 | closed |
| 58 | 个人出站凭据一键探测的真实认证调用设计——**已关闭（2026-08-31 用户指令）**：phase1 功能点不含此部分，后续有需求再单开任务；原待确认项：三类目标（平台外资产/平台原生工具/Nexus）的认证调用形态与副作用约束 | 架构决策 | spec 007 FR-015, spec 003 FR-008 | closed |
| 59 | 个人模型凭据调用失败的「失效 vs 抖动」判定基线——**已裁定（2026-08-31 用户裁定）**：失效类 ＝ 全部 HTTP 4xx 除 429（含 400/401/403/404/408 等）；瞬时类 ＝ 429 + 全部 5xx + 网络错误 + 连接超时；仅看外层 HTTP 状态码、不解析 Nexus 响应体；P0 不引入连续瞬时故障升级/熔断机制。FR-021 与 SC-003 现为可测基线 | 架构决策 | spec 007 FR-021/SC-003, contracts/openapi/grc-mgmt-service.yaml（vault 子域 report-credential-failure） | closed |
| 60 | 新凭据模型与编辑范围矩阵复核——**已关闭（2026-08-31 用户终裁）**：① 所有凭据均不支持修改（PAT/资产调用静态与动态/导入通道/Nexus 模型凭据创建或颁发后一律锁定，含凭据值；变更＝新建+换绑+删旧，动态＝手动重新颁发）；② 保存不触发重新检测（探测仅显式一键触发）；③ 平台资源凭据由管理后台独立管理运维页单独维护，与用户密钥库分离。已回写 spec 007（总览表/FR-012/FR-013/FR-017/Clarifications）。**遗留契约影响**：`grc-mgmt-service.yaml` 的 `updateOutboundCredential`（PUT /mgmt/vault/outbound/credentials/{id}）与本裁定冲突，需走 contract-change 收敛（建议并入 #71 批次） | 架构复核 | ADR-005, spec 007, PRD §9.3, contracts/openapi/grc-mgmt-service.yaml, grc-python-sdk, grc-mgmt-service | closed |
| 61 | 【待客户确认】P0 护栏类型枚举暂定为四类（提示词注入/有害内容/意图偏离/违禁词），**不含个人身份信息（PII）检测**——2026-08-24 用户暂定，需客户确认是否接受 P0 不覆盖 PII（PRD §1.1 PII 词条与 CONTEXT.md「护栏」词条已同步标注；spec 006 FR-002） | 客户确认 | spec 006 FR-002, PRD §1.1, CONTEXT.md | open |
| 62 | 【责任人：合规+架构/开发】知识库软删除后 PG 原始 chunk/metadata 保留周期默认值——机制已入 spec（可配置保留周期+统一定时清理，spec 005 FR-042、spec 000 AC-G7，2026-08-25 用户裁定）；具体默认值 [待确认：Security/Compliance/Data Governance 裁定，2026-08-25 会议倾向 60 天，后续可调为一年等] | 合规/基线 | spec 005 FR-042, spec 000 AC-G7 | open |
| 64 | 【责任人：BA+UX】三档可见性的业务化命名——spec 005 FR-011 已用描述性术语「公开可用/公开需申请/完全隐藏」（2026-08-25 用户裁定）；面向业务用户的 UI 展示文案需避免技术术语，名称待定。**已关闭（2026-09-01 用户指令）** | 文案 | spec 005 FR-011 | closed |
| 65 | 【责任人：BA+架构】管理员/运维前台可见范围——**已关闭（2026-09-04 用户裁定）**：Phase 1 平台管理员拥有所有知识库及其文档的全量查看与维护权限，可代执行配置、导入、构建、停用和删除等操作，用于运维排障、避免只能查询后台数据库；操作留痕，不改变 Owner/Deputy 日常责任归属。已回写 spec 005/008 FR-054b | 权限模型 | spec 005 FR-054b, spec 008 FR-054b | closed |
| 66 | 【责任人：BA】知识库联系人展示范围与字段——**已关闭（2026-09-04 用户裁定）**：知识库 Owner/Deputy 仅在创建时输入，后续从 Alice 同步；无有效权限用户对可发现知识库的 Information 页展示 Owner 姓名和邮箱，完全隐藏知识库不展示。已回写 spec 005 FR-037f | 产品决策 | spec 005 FR-037f, Alice | closed |
| 67 | 【责任人：BA】文档上传预检 + 未解析状态推荐配置展示交互——**已关闭（2026-09-04 用户裁定）**：上传后、构建前执行基础预检并展示推荐构建配置；用户可修改，但修改仅作用于当前上传批次，不改变知识库默认配置，也不形成单文档长期覆盖配置。已回写 spec 005 FR-018b 与 US-2 | 产品决策 | spec 005 FR-018b, US-2 | closed |
| 69 | 【责任人：合规+BA】敏感信息局部打码 vs 护栏整段拦截的机制冲突——2026-08-25 上午会议：客户明文信息（电话/密码）严禁显示，员工姓名等内部信息是否脱敏无标准；现行护栏为整条拦截/全文零字留存（spec 006 FR-041/FR-042），与局部 PII 遮蔽需求存在逻辑冲突；会议暂缓决策，待咨询合规/董事后再定；参考 ChatGPT 实践：允许记住用户主动提供的个人信息。2026-09-04 用户裁定：9.11 上线版本不涉及，由 BA 维护，保留本项 | 合规 | spec 006 FR-041/FR-042, watchlist #61 | open |
| 70 | 【责任人：BA+开发】重建机制细则待续谈终态后回写 spec 005——2026-08-25 上午会议方向：向量模型与向量库绑定不可改；仅构建类参数（parser/chunk/增强）变更激活重建，检索类参数（top_k 等）即时生效不重建；支持单/多文档粒度重建；全库重建需二次确认（输入 confirm 文字），未确认则新配置仅用于后续上传文档；防止全库重建覆盖已调优文档配置。下午续谈后由用户裁定回写 FR-039（现行「保存即触发全库重建」口径待改）。**已关闭（2026-09-01 用户指令）** | spec 冲突 | spec 005 FR-039/US-8 | closed |
| 71 | 【责任人：架构/开发】knowledge/parser/mgmt 契约与 spec 005 对齐差距一揽子（走 contract-change 流程；2026-09-04 用户裁定：Alice 角色申请与同步的契约范围单独由 #84 跟踪）：①切片四策略专属参数全缺（仅通用 chunkSize/chunkOverlap）；②向量库缺索引类型/距离算法/用量展示；③重排序缺模型选择、topN 下限 1 与 spec 10–50 不符；④语言枚举缺德语、解析器枚举含已裁定不用的 DeepDoc（2026-08-23 裁定）；⑤visibility 仍为两档 [PRIVATE, PUBLIC]，未同步三档（spec 005 FR-011，2026-08-25 用户裁定）；⑥知识库删除契约为「立即不可恢复清理」与 spec 软删除+保留期语义相反；⑦两份契约 ParserConfig 互不一致；⑧`Description` 已裁定为建库必填（spec 005 FR-010，2026-08-30），但 knowledge/mgmt 的 CreateKnowledgeBaseRequest 均未列入 required，且契约现存 maxLength 512、更新接口 maxLength 4000 两套值，须统一对齐已裁定的 100 至 500 字业务基线；⑨Overview KPI 统计须收敛为知识库总数、可用知识库数、文档总数、构建失败文档数与就绪度（spec 005 FR-056c，2026-09-04 用户裁定） | 契约治理 | contracts/openapi/grc-knowledge-engine.yaml, contracts/openapi/grc-parser-engine.yaml, contracts/openapi/grc-mgmt-service.yaml, spec 005 FR-010/FR-011/FR-038/FR-042 | open |

| 75 | 权限展示与申请入口已裁定并回写（2026-08-28 用户裁定）：Viewer 仅见 Name/Update 且不可进详情；Consumer 可见完整列表与详情但不可操作；Contributor/Owner 可见全部状态并可维护、默认 Documents Tab；完全隐藏知识库仍不可发现。**2026-09-01 用户裁定补充（#73 关闭）**：所有已登录用户对「公开可用」与「公开需申请」知识库默认具有 Viewer 最小视图，并在显著位置获得 Alice 申请入口；Viewer 的 Alice 技术映射转 #81 跟踪，Owner 具体展示字段另由 #66 跟踪 | 权限交互 | spec 005 FR-037c~FR-037f, watchlist #66/#81 | closed |
| 76 | 【责任人：BA+UX】优化知识库创建与配置表单——**已关闭（2026-09-04 用户裁定）**：`Description` 必填，长度为 100 至 500 字；默认 Retrieval 策略为知识库级生命周期配置，仅作用于当前知识库，P0 仅提供现有重排序开关、模型与 top-k。已回写 spec 005 FR-010/FR-039 | 表单/检索配置 | spec 005 FR-010/FR-039 | closed |
| 77 | 【责任人：BA+UX+开发】调整知识库构建信息展示——移除 `Build Stage Status` 模块，改在 Information 页面静态说明 Chunk、Enhancer、Embedding 等构建流程；Pipeline 增加 Enhancer 阶段；失败时展示具体出错步骤并支持跳转至手动修复页面。Viewer 隐藏 Pipeline、Consumer 只读、Contributor/Owner 可查看全部状态的权限边界已于 2026-08-28 用户裁定并回写 spec 005 FR-037c~FR-037f；剩余待确认项为手动修复页面及入口细节。**已关闭（2026-09-01 用户指令）** | 构建交互 | spec 005 FR-025/FR-026/FR-037c~FR-037f/FR-038, grc-ai-portal | closed |
| 78 | 【责任人：BA+UX】优化 Overview 页面 KPI——**已关闭（2026-09-04 用户裁定）**：展示知识库总数、可用知识库数、文档总数、构建失败文档数与知识库就绪度；就绪度遵循 spec 005 FR-056 的定义。已回写 spec 005 FR-056c 与 US-14 | KPI/交互 | spec 005 FR-056/FR-056c, US-14 | closed |
| 79 | 一级导航信息架构冲突——**已关闭（2026-09-01 用户裁定）**：按 2026-08-26 会议决议采用新一级导航 Chat / Explore / Curate / Build / Govern；Agent/MCP 发现与订阅目录归 Explore；订阅者中心并入 Explore 页内（右上角 console 或页内入口，不再独立二级入口）；创作者中心归 Build（Build 同时承载上架入口、Dify 跳转、Agent Kit 预留）；Explore 引导 button 跳 Build 9/7 首期不做；已回写 spec 002 Clarifications（Session 2026-09-01）；遗留项——PRD §5.1/§5.2 升版对齐与 provider 审批 request 归 Build/Govern 未定论，转 #80 跟踪 | 基线冲突 | docs/prd/GRC-AI-Foundation-Platform-PRD-v1.2.md §5.1/§5.2, spec 002 Clarifications, 会议纪要 2026-08-26 平台导航与详情页设计, UI 0828, watchlist #80 | closed |
| 80 | 【责任人：BA+UX】PRD 一级导航升版对齐 + provider 审批 request 归属——2026-09-01 用户裁定采用新一级导航（Chat/Explore/Curate/Build/Govern，详见 #79），PRD v1.2 §5.1/§5.2 仍为旧 IA，基线文档不直接反写，待走 PRD 升版流程对齐并同步受影响 spec/功能清单；遗留未定论：provider 审批 request 归 Build 还是 Govern（2026-08-26 会议未定） | 基线升版 | docs/prd/GRC-AI-Foundation-Platform-PRD-v1.2.md §5.1/§5.2, spec 002, watchlist #79 | open |

## 文档缺口

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 30 | API 成功响应包络（`ApiResponse`）已规范——ADR-006 定义统一包络（`code:0` 为成功），`error-codes.md` §1 补充成功响应格式与分页结构（2026-08-21） | 文档缺口 | architecture/adr/006-api-response-envelope.md, architecture/cross-cutting/error-codes.md | closed |
| 46 | 需单独 skill/手段保障后端接口请求/返回体正确性与字段说明完整性——**已关闭（2026-08-31 用户指令）**：phase1 工作模式为并行、没有提前 plan，导致无法避免；原缺口：现有 `/contract-change` + 门禁仅覆盖语法与破坏性变更，无对照 spec 验收字段语义/required/枚举/description 完备性与 ADR-006 对齐的专项流程（来源：用户指令 2026-08-21） | 能力缺口 | capabilities/skills/contract-change, gates/scripts/check-contracts, capabilities/prompts/contract-review.prompt.md, ADR-006 | closed |
