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
| 72 | 【责任人：BA+架构】完善子级目录创建与编辑规则——创建时分别配置「目录控制权限」与「知识库创建权限」两个角色，每个角色设置 2–3 名审批人；创建后仅允许修改目录名称，`Location` 与权限配置不可编辑；字段、角色及不可编辑约束需确认并同步相应 spec/契约（来源：2026-08-28 用户提供的会议待办） | 权限模型 | spec 005, spec 008, contracts/ | open |
| 74 | 【责任人：架构/开发+运维】梳理目录层级调整的运维 SOP——明确标准流程、风险、审批与影响范围；会议提出后台数据库操作，但不得覆盖 spec 000 AC-G8/watchlist #63「禁止人工直接操作数据库」的既有基线，需优先确认是否应通过受控管理接口、迁移任务或自动化作业实施（来源：2026-08-28 用户提供的会议待办） | 运维治理 | spec 000 AC-G8, spec 005, watchlist #63, sop/ | open |

## 环境与账号前置依赖

| # | 项目 | 类型 | 关联 | 责任方 | 状态 |
|---|------|------|------|--------|------|
| 24 | 开发人员 GitHub 账号开通——已完成（用户确认 2026-08-17） | 账号 | 全服务 | `[待确认]` | closed |
| 25 | Alice 应用 admin 账号申请（阻塞 SSO 集成调研验证）——原目标最晚 2026-08-19，2026-08-24 watchlist 质量复核未见最新状态；下一步需补申请状态、新目标日期与责任人 | 账号+集成 | spec 000/007, auth-service | `[待确认]` | open |
| 26 | Azure 账号→SharePoint 方案落地（进行中）——2026-08-24 watchlist 质量复核未见最新检查点；下一步需补落地负责人、当前阶段与下一检查点 | 基础设施 | spec 005 AC-10, mcp-m365-server | `[待确认]` | in-progress |
| 27 | Nexus Teams 创建 + 模型订阅 + 支持模型列表对齐 | 外部依赖 | spec 001/004, agent-service, eval-service | `[待确认]` | closed |
| 28 | Nexus 缺少多模态/OCR 模型，需自行部署（用户指令 2026-08-14）——下一步需确认自部署模型方案、责任人、目标日期与是否影响 P0 交付 | 外部依赖 | parser-engine, knowledge-engine | `[待确认]` | open |
| 73 | 确认 Alice 集成方案——统一确认角色默认分配、创建者默认权限、组织用户账号获取方式，以及 Add Documents 中 `Refresh Frequency` 与 `Schedule` 是否重复。2026-08-31 用户转述业务方 Emma 补充：知识库 Owner 无需向 Alice 单独申请 Contributor 权限；现有 spec 005 已赋予 Owner 覆盖 Contributor 的操作能力，仍待 BA 明确有效权限是否为 `Owner ⊇ Contributor ⊇ Consumer`，并由架构/开发确认 Alice 侧采用角色继承、权限并集还是自动附加角色 | 外部集成/权限模型 | spec 005 FR-019/FR-037c~FR-037f, spec 008, Alice | BA+架构/开发 | open |

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
| 22 | 测评模板初始阈值审定——注意：Zhang Hao 在 main 登记的口径（「安全合规 ≥90% 硬门控；功能质量与性能基线 P0 仅展示不阻断」）与 PRD §9.4 三类模型（提示词注入/意图偏离/内容安全各自独立阈值、三类均达标才算通过）对不上，**待其说明来源后再定**（2026-08-24 用户对账决定） | 基线 | spec 004, PRD §9.4 | open |
| 23 | Alice 同步周期与失败回滚——随 PRD §13.10 #16 确认关闭（2026-08-21） | 外部依赖 | spec 008 | closed |
| 29 | UI/UX 方案未定，阻塞前端工作——现只有 PRD §13.11 视觉与品牌基础规范（深色风格/主色/胶囊按钮/字体）与一份已过期的旧原型（`docs/prd/GRC_AI_Agent_Prototype_v1.html`），无信息架构/交互稿/组件规范；`grc-ai-portal` 的 `docs/design/` 为空 | 前端/设计 | grc-ai-portal, PRD §13.11 | open |
| 32 | 005 FR-013 与 PRD §9.7 冲突——已解决（用户裁定 2026-08-21）：新建库角色模型——建库时指定知识库 Owner+Deputy、平台据此调 Alice 建角色并授予、后续授予由知识库 Owner/Deputy 单级审批；PRD/CONTEXT/旅程/ADR-0013/005 已全链路修订 | spec 冲突 | spec 005, PRD §7 M4-5/§9.7, ADR-0013 | closed |
| 33 | 管理后台「准入测评模板维护」页面归 008-admin；004 仅承载发布链路中的模板消费语义（2026-08-23 Zhang Hao 登记，2026-08-24 用户对账确认）；004 的对应 Open Question 已关闭 | spec 归属 | spec 004/008, PRD §5.2 | closed |
| 34 | 005 User Story 优先级标注（P1/P2/P3，spec-kit 约定）与 PRD 的 P0/P1 批次同名不同义——**约定已裁定（2026-08-25 用户终审 spec 008 时裁定）**：统一采用 006 的写法「Delivery: <PRD 批次> + Story Order: S<n>」，不再使用 spec-kit 的 P1/P2/P3 优先级标注；008 已回写，**剩余动作：005 按同约定改写后本项关闭** | 格式 | spec 005/006/008 | in-progress |
| 35 | PRD §13.10 #3：知识目录与知识库权限细化规则——已确认（2026-08-22 BA 裁定）：目录级角色以 Alice 流程为主，平台仅展示权限 ID、申请入口与同步状态；知识库级维护角色保留 Owner/Deputy 单级审批 | 权限模型 | spec 005, PRD §9.7, ADR-0006 | closed |
| 36 | PRD §13.10 #4：平台事件响应手段边界——已确认（2026-08-22 BA 裁定）：维持现边界，管理员可停用出站调用但不改变资产状态、不承诺阻断直连调用；孤儿资产补员恢复治理 | 合规 | spec 004/008, PRD §9.1, ADR-0009 | closed |
| 37 | PRD §13.10 #5：P1 自助测评需求范围——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不细化模板体系、数据集管理与对比报告范围 | P1 规划 | spec 004 | closed |
| 38 | PRD §13.10 #6：临时文件上传（P1）的护栏检测时机——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定解析与检测时机 | P1 规划 | spec 001, PRD §9.5 | closed |
| 39 | PRD §13.10 #7：库内重复文档识别（P1）相似度口径与处置形态——已确认（2026-08-22 BA 裁定）：仅保留 P1 规划占位，当前 PRD/spec 不裁定口径、阈值与处置形态 | P1 规划 | spec 005 | closed |
| 40 | PRD §13.10 #9：导入通道定时同步（P1）凭据主体与「配置人离职中断」风险处置——已确认（2026-08-22 BA 裁定）：使用配置人个人出站凭据；配置人账号停用/离职/凭据失效时同步暂停并通知知识库 Owner/Deputy | P1 规划 | spec 005 | closed |
| 41 | PRD §13.10 #14：申请人撤回订阅申请是否纳入——已确认（2026-08-22 BA 裁定）：P0 不纳入，待审批申请无申请人出边 | 产品决策 | spec 002, PRD §9.2 | closed |
| 42 | PRD §13.10 #15：审批停滞兜底——已确认（2026-08-22 BA 裁定）：P0 不补系统催办或超时回落；在职但长期不处理由人工沟通解决，死锁回落仅覆盖账号失效 | 产品决策 | spec 002, PRD §9.2 | closed |
| 43 | `spec-sync-prd-v1.2` 分支已并入 main：PRD v1.2 同步 + §13.10 五项澄清 + 002/005 grill 细化已成为主分支基线；合并等待项关闭 | 评审合并 | specs/001–009, docs/prd, memory/now | closed |
| 44 | 【BA 跟进】spec plan 参数子项跟踪（2026-08-24 watchlist 质量复核拆分）：① 004 裁判模型算力与并发配置（plan 阶段）；② 006 护栏性能基准（全文缓冲延迟、窗口检测延迟）；③ 006 违禁词表单表条目上限与单文件大小上限（审定后补 PRD §9.10）；④ 007 SDK 凭据解析缓存 TTL（参照值 60 秒＝当前实现，实现先行不构成既定标准，需架构/开发确认后才入 §9.10）。已核销项不再跟踪：003 动态凭据校验深度、003 Agent Card/工具清单拉取失败自动重试（不自动重试）、009 通知去重/抑制；001 滑动窗口/首段延迟参数统一由 #50 跟踪 | BA 跟进 | specs/004/006/007；watchlist #50 | open |
| 45 | 【责任人：Zhang Hao】【紧急——spec 001 进 plan 的前置】ADR-007（A2A 协议统一，状态 Proposed）需决策是否 Accept：若 Accept，grc-agent-service 自定义 REST+SSE 端点将替换为 A2A handler（`/.well-known/agent.json` + `POST /a2a`），mgmt-service chat-agent domain 需新增 A2A 客户端，gateway 路由与 `grc-agent-service.yaml` 契约需整体调整；001 已裁定透传上下文归资产（FR-021，需透传接口含会话 ID 字段），该契约影响必须与 ADR-007 的 Accept 决策联动落地；当前不动代码，等 ADR Accept 后再改 | 架构决策 | ADR-007, spec 001 FR-021, grc-agent-service, grc-mgmt-service, grc-api-gateway | open |
| 46 | 【责任人：Zhang Hao】服务 owner 仍为 `@todo-owner`，需填实 `architecture/services.manifest.yaml` 与 `architecture/service-map.md` 的 9 个服务负责人；否则工单认领、契约消费方确认与人审守门点缺少责任闭环 | 责任归属 | architecture/services.manifest.yaml, architecture/service-map.md | open |
| 47 | 【责任人：Zhang Hao】架构/API/横切规范未决项需统一收敛：api-landscape 待评审 11 项、认证授权横切规范、可观测性状态、000-platform plan 中护栏执行与 CI/CD、契约骨架填充优先级；需形成 plan 阶段输入或拆分工单 | 架构/API/横切 | specs/000-platform/api-landscape.md, architecture/cross-cutting/auth.md, architecture/cross-cutting/observability.md, specs/000-platform/plan.md, contracts/ | open |
| 48 | `check-contracts.sh` 未通过——已修复（2026-08-22，合入 main @ cb1c992）：mcp-server/knowledge-engine YAML 引号 ×3、auth-service 7 处 nullable 迁移 3.1 union type、8 处 security 声明补齐（内部服务根级 bearerAuth 对齐 mgmt，healthz/login/verify/refresh/oauth 显式 `security: []`）、saveDocumentChunk 补 chunkId 路径参数、npx 缓存清理、门禁脚本 oasdiff 误报修复（仅 error/warning 级判失败，.sh/.ps1 同步）。人工豁免：chunkId 补齐声明的 `new-request-path-parameter` flag 属无效契约修复，理由记录于合并提交 cb1c992 | 契约门禁 | contracts/, gates/scripts/check-contracts.sh, contracts/POLICY.md | closed |
| 49 | 【责任人：Zhang Hao】【合并守门风险】远端 main 的 "update api" 提交（eea6cec）删除了 `DELETE /mgmt/knowledge/knowledge-bases/{kbId}` 端点，oasdiff 报 `api-removed-without-deprecation`——真实破坏性契约变更，未见 service-map 消费方逐一确认记录；需回溯确认删除是否有意、消费方是否知情，并在后续涉及该契约的合并前补齐消费方确认或恢复端点 | 契约治理 | contracts/openapi/grc-mgmt-service.yaml, contracts/POLICY.md, architecture/service-map.md | open |
| 50 | 【责任人：Zhang Hao】【plan 阶段输入/待确认】输出侧护栏机制基线已采纳（2026-08-24 用户裁定）：流式响应＝重叠滑动窗口检测、非流式＝全文缓冲；**命中坚持全文零字留存**——命中时终止上游并瞬时撤回全部已下发内容（含已通过窗口的前缀）、展示安全护栏命中提醒。命中提醒形态已裁定为占位替换＋护栏类型，不再由本项跟踪；待 plan/压测确认窗口大小、重叠长度、检测位置、检测超时、首段延迟、长响应上限与实现可行性；引擎 SaaS/自建见 #1；main 上 Zhang 版含前缀保留口径已被本裁定取代 | 架构/性能 | spec 001 FR-022/FR-023, spec 006 FR-042/FR-043, watchlist #1 | open |
| 51 | 【责任人：Li Zhonghao】spec 005 构建管线改动需开发侧跟进（2026-08-23 BA Lead 复核裁定）：① 解析器收敛为 Docling/MinerU，不使用 DeepDoc——实现快照 `Implementation-Snapshot/KB-coding/knowledge-engine` 的 `pipeline_config_validator.py` 合法解析器集合与两份 Api 清单中的 deepdoc 参数需移除；② 切片/增强/解析器/向量化/重排序参数矩阵（FR-038）请审阅可行性；③ 语言提示为中文/英文/德语/自动检测 | 开发跟进 | spec 005 FR-038, Implementation-Snapshot/KB-coding | open |
| 52 | 【架构/开发待确认】准入测评任务整体超时上限——2026-08-23 spec 004 澄清建议值 30 分钟（超时视同执行失败、可重测）；需架构/开发确认可行性后补入 PRD §9.10 参数基线审定，审定前不作为工单基线 | 基线 | spec 004 FR-010, PRD §9.4/§9.10 | open |
| 53 | MCP 协议枚举 P0 单值「Streamable HTTP」——已确认（Zhang Hao 2026-08-23 审核通过：不兼容旧版 SSE，字段保留枚举结构供未来扩展）；003 对应 Open Question 随之关闭（2026-08-24 对账） | 技术审核 | spec 003 FR-013 | closed |
| 54 | 通知事件归类一揽子裁定——**已关闭**：P0 十三类设计全集确认；新增/补齐类为「资产治理通知」，载荷为中止发布与发布失败；受众按阶段分层（首发前：创建者 + 草稿协作者；首发后：Owner/Deputy）；旧资产凭据更新载荷已随凭据模型修订取消；资产删除不通知。已回写 PRD M9-1、spec 009 FR-033/FR-034 与 spec 004 发布失败/中止发布触发语义 | spec 对齐 | spec 009 FR-033, spec 004 FR-018/FR-042, PRD M9-1 | closed |
| 55 | spec 002/003/004 peer review 与终审——**已关闭（2026-08-23）**：Zeng Ziyang grill 复核 003/004（提交 4b1c90f/57f3008，补入 FR-041~045 等）；用户终审 13 项逐项裁定——采纳 FR-041/042/043/044/045 与版本号/说明口径转正，确认两项自我推翻项（中止不留痕、重测不收紧），驳回 HC 暂缓（#56 关闭），002 增补由用户终审追认；002 维持 Reviewed，003/004 升 Reviewed | 评审 | specs/002/003/004 | closed |
| 56 | Health Check 开关存废分歧——**已关闭（2026-08-23 用户终审）**：维持「HC 强制必选、消除开关」，驳回 peer review 暂缓；补充理由：HC 可关闭则资产失效无法触达时订阅者与平台无从知晓实际服务健康状态；spec 003 FR-007/FR-013 与 PRD 强制表述维持，无回滚 | spec 分歧 | spec 003 FR-007/FR-013, PRD v1.2 版本说明 2026-08-23 补遗 | closed |
| 57 | 原催办已拆分（2026-08-23/24）：#50 的护栏处理机制已裁定（流式滑动窗口/非流式全文；命中零字留存+撤回前缀为用户终审口径），剩余参数转为 plan 阶段输入；spec 001 进 plan 的架构前置仅剩 #45（ADR-007 是否 Accept） | 催办 | watchlist #45/#50, spec 001, ADR-007 | closed |
| 58 | 【架构/开发待确认】个人出站凭据一键探测的真实认证调用设计——2026-08-23 spec 007 澄清裁定口径为真实鉴权（与 003 同构，全平台探测强度统一），但对三类目标（平台外资产/平台原生工具/Nexus）的认证调用形态与副作用约束需架构/开发设计确认 | 架构决策 | spec 007 FR-015, spec 003 FR-008 | open |
| 59 | 【责任人：Zhang Hao 决定】**个人模型凭据调用失败的「失效 vs 抖动」判定基线**。背景：个人模型凭据调用失败时平台按失败类型走两个分支——凭据失效类（令牌过期、无权限）＝本次调用改用平台默认凭据 + 可用性快照对应模型置不可用 + 通知本人处理；瞬时故障类（网络抖动、对方超时/临时宕机）＝不改快照、不通知、下次照常再试。判错方向的代价：误判为失效→凭据被冤枉标记不可用且用户收到骚扰通知；误判为抖动→每次调用先失败再兜底且用户不知凭据已坏。需要决定的：以什么信号区分两类——建议基线为 HTTP 401/403＝失效类、网络错误/超时/5xx＝抖动类（Nexus 为 HTTP 网关），混合与非标响应的归类一并裁定。该基线是 spec 007 验收标准「失效类 100% 触发回落与通知、抖动类 0 触发」可测的前提。2026-08-23 BA 明确：非 BA 裁定事项，由 Zhang Hao 处理并决定，spec 007 按待澄清依赖项挂起 | 架构决策 | spec 007 FR-021/SC-003, contracts/openapi/grc-mgmt-service.yaml（vault 子域 report-credential-failure） | open |
| 60 | 【高优——责任人：Zhang Hao 查看确认，2026-08-23 用户指示，2026-08-24 按新凭据模型重写】新凭据模型与编辑范围矩阵复核：PAT 创建后锁定；资产调用使用订阅者个人凭据——静态凭据由订阅者填入并绑定，凭据值可编辑且保存后重检，动态凭据由平台代颁发入库、不支持用户编辑密钥值、仅支持手动重新颁发；导入通道与 Nexus 模型凭据仅凭据值可编辑且保存后自动重检/探测；平台资源凭据由管理后台维护；审计记录凭据 ID + 凭据类型 + 持有人账号三元组。请确认与 ADR-005、OpenAPI 契约、grc-python-sdk、mgmt vault 子域、grc-mgmt-service 实现边界无冲突 | 架构复核 | ADR-005, spec 007, PRD §9.3, contracts/openapi/grc-mgmt-service.yaml, grc-python-sdk, grc-mgmt-service | open |
| 61 | 【待客户确认】P0 护栏类型枚举暂定为四类（提示词注入/有害内容/意图偏离/违禁词），**不含个人身份信息（PII）检测**——2026-08-24 用户暂定，需客户确认是否接受 P0 不覆盖 PII（PRD §1.1 PII 词条与 CONTEXT.md「护栏」词条已同步标注；spec 006 FR-002） | 客户确认 | spec 006 FR-002, PRD §1.1, CONTEXT.md | open |
| 62 | 【责任人：合规+架构/开发】知识库软删除后 PG 原始 chunk/metadata 保留周期默认值——机制已入 spec（可配置保留周期+统一定时清理，spec 005 FR-042、spec 000 AC-G7，2026-08-25 用户裁定）；具体默认值 [待确认：Security/Compliance/Data Governance 裁定，2026-08-25 会议倾向 60 天，后续可调为一年等] | 合规/基线 | spec 005 FR-042, spec 000 AC-G7 | open |
| 64 | 【责任人：BA+UX】三档可见性的业务化命名——spec 005 FR-011 已用描述性术语「公开可用/公开需申请/完全隐藏」（2026-08-25 用户裁定）；面向业务用户的 UI 展示文案需避免技术术语，名称待定 | 文案 | spec 005 FR-011 | open |
| 65 | 【责任人：BA+架构】管理员/运维前台可见范围待定义——2026-08-25 会议：管理员是否能前台看到所有知识库卡片、是否只能通过数据库审计、是否需要额外特权账号均未定；已确认数据库可查询所有知识库及状态，未规划管理员展示页面；另会议裁定管理员不默认查看私有知识库文档级状态（用户先按前端错误信息重试或提工单，平台级异常由运维后台排查） | 权限模型 | spec 005, spec 008 | open |
| 66 | 【责任人：BA】知识库联系人展示范围与字段——2026-08-28 用户裁定：无权限用户对可发现知识库可在 Information 页看到 Owner 信息；「完全隐藏」知识库仍不向无权限用户暴露。剩余待定仅为 Owner 展示字段（仅姓名，或包含邮箱、部门等）及其他有权限角色是否展示同一字段集 | 产品决策 | spec 005 FR-037f | open |
| 67 | 【责任人：BA】文档上传预检 + 未解析状态推荐配置展示交互——2026-08-25 会议：文档上传后先做格式等基础预检，待解析状态展示当前推荐构建配置、用户可改、未改用推荐值；grill-me 裁定挂起，交互细节待补后进 spec 005 | 产品决策 | spec 005 FR-010/US-8 | open |
| 69 | 【责任人：合规+BA】敏感信息局部打码 vs 护栏整段拦截的机制冲突——2026-08-25 上午会议：客户明文信息（电话/密码）严禁显示，员工姓名等内部信息是否脱敏无标准；现行护栏为整条拦截/全文零字留存（spec 006 FR-041/FR-042），与局部 PII 遮蔽需求存在逻辑冲突；会议暂缓决策，待咨询合规/董事后再定；参考 ChatGPT 实践：允许记住用户主动提供的个人信息 | 合规 | spec 006 FR-041/FR-042, watchlist #61 | open |
| 70 | 【责任人：BA+开发】重建机制细则待续谈终态后回写 spec 005——2026-08-25 上午会议方向：向量模型与向量库绑定不可改；仅构建类参数（parser/chunk/增强）变更激活重建，检索类参数（top_k 等）即时生效不重建；支持单/多文档粒度重建；全库重建需二次确认（输入 confirm 文字），未确认则新配置仅用于后续上传文档；防止全库重建覆盖已调优文档配置。下午续谈后由用户裁定回写 FR-039（现行「保存即触发全库重建」口径待改） | spec 冲突 | spec 005 FR-039/US-8 | open |
| 71 | 【责任人：架构/开发】knowledge/parser/mgmt 契约与 spec 005 对齐差距一揽子（走 contract-change 流程）：①切片四策略专属参数全缺（仅通用 chunkSize/chunkOverlap）；②向量库缺索引类型/距离算法/用量展示；③重排序缺模型选择、topN 下限 1 与 spec 10–50 不符；④语言枚举缺德语、解析器枚举含已裁定不用的 DeepDoc（2026-08-23 裁定）；⑤visibility 仍为两档 [PRIVATE, PUBLIC]，未同步三档（spec 005 FR-011，2026-08-25 用户裁定）；⑥知识库删除契约为「立即不可恢复清理」与 spec 软删除+保留期语义相反；⑦两份契约 ParserConfig 互不一致；⑧`Description` 已裁定为建库必填（spec 005 FR-010，2026-08-30），但 knowledge/mgmt 的 CreateKnowledgeBaseRequest 均未列入 required，且契约现存 maxLength 512、更新接口 maxLength 4000 两套值，而业务字数限制尚 `[待确认]`，不得把现存值当业务基线 | 契约治理 | contracts/openapi/grc-knowledge-engine.yaml, contracts/openapi/grc-parser-engine.yaml, contracts/openapi/grc-mgmt-service.yaml, spec 005 FR-010/FR-011/FR-038/FR-042 | open |
| 75 | 权限展示与申请入口已裁定并回写（2026-08-28 用户裁定）：Viewer 仅见 Name/Update 且不可进详情；Consumer 可见完整列表与详情但不可操作；Contributor/Owner 可见全部状态并可维护、默认 Documents Tab；无权限用户仅见可发现知识库 Information 页并在显著位置获得 Alice 申请入口；完全隐藏知识库仍不可发现。Viewer 的 Alice 映射另由 #73 跟踪，Owner 具体展示字段另由 #66 跟踪 | 权限交互 | spec 005 FR-037c~FR-037f, watchlist #66/#73 | closed |
| 76 | 【责任人：BA+UX】优化知识库创建与配置表单——`Description` 已裁定为必填（2026-08-30 用户裁定，已回写 spec 005 FR-010）；字数限制仍为 `[待确认]`，2026-08-28 会议建议的「不少于 15 字」不作为当前基线。剩余待办：确定字数限制；增加仅作用于当前知识库的默认 Retrieval 检索策略，并明确可配置项、默认值与保存权限 | 表单/检索配置 | spec 005 FR-010/FR-038 | open |
| 77 | 【责任人：BA+UX+开发】调整知识库构建信息展示——移除 `Build Stage Status` 模块，改在 Information 页面静态说明 Chunk、Enhancer、Embedding 等构建流程；Pipeline 增加 Enhancer 阶段；失败时展示具体出错步骤并支持跳转至手动修复页面。Viewer 隐藏 Pipeline、Consumer 只读、Contributor/Owner 可查看全部状态的权限边界已于 2026-08-28 用户裁定并回写 spec 005 FR-037c~FR-037f；剩余待确认项为手动修复页面及入口细节 | 构建交互 | spec 005 FR-025/FR-026/FR-037c~FR-037f/FR-038, grc-ai-portal | open |
| 78 | 【责任人：BA+UX】优化 Overview 页面 KPI——重新设计 KPI 展示内容，突出核心指标，整体保持稳重，并兼顾美观与性能；具体指标集合、计算口径、刷新频率与展示优先级均为 `[待确认]`（来源：2026-08-28 用户提供的会议待办） | KPI/交互 | spec 005, spec 008, grc-ai-portal | open |
| 79 | 【责任人：BA+架构】我的目录分享「统计接口」口径待澄清——2026-09-02 晚会：私人项目小范围 share 统计拟单开一个接口（入参含 Consumer 等角色权限、知识库 id，返回 list；或直接库里联查）。与 spec 005 FR-014「我的目录无 Alice 角色概念、不展示任何角色信息」存在口径冲突——需澄清接口返回的是分享授权级别（可查看/可编辑，FR-058）还是 Alice 角色；若确为新接口，需评估契约影响并走 contract-change 流程 | 接口/权限模型 | spec 005 FR-014/FR-058~FR-061, contracts/, contracts/POLICY.md | open |
| 80 | 【责任人：BA】private（我的目录）项目的判断筛选规则——2026-09-02 晚会原文为「private项目判断筛选？」（带问号未决）：按何种字段与口径区分、筛选 private 项目待明确 | 产品决策 | spec 005 FR-001/FR-014 | open |
| 81 | 【责任人：BA】9.2 晚会「迁移」事项含义待澄清——纪要仅列「迁移」一词，未指明迁移对象（知识库迁移/存量数据迁移/环境迁移）与范围，需补充上下文后再定是否影响 spec | 待澄清 | spec 005 | open |
| 82 | 进度类事项跟踪（2026-09-02 晚会，无 spec 冲突）：①marketplace 需更新开发状态与完成进度；②前端知识库目录部分已完成、权限部分未完成；③知识库进入联调阶段。待后续例会同步核销 | 进度跟踪 | spec 005, grc-ai-portal | open |

## 文档缺口

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 30 | API 成功响应包络（`ApiResponse`）已规范——ADR-006 定义统一包络（`code:0` 为成功），`error-codes.md` §1 补充成功响应格式与分页结构（2026-08-21） | 文档缺口 | architecture/adr/006-api-response-envelope.md, architecture/cross-cutting/error-codes.md | closed |
| 46 | 需单独 skill/手段保障后端接口**请求参数正确性、返回体正确性、参数字段说明完整**——现有 `/contract-change` + `gates/scripts/check-contracts` 仅覆盖 OpenAPI/AsyncAPI 语法与破坏性变更（oasdiff），`contract-review` 偏消费方影响；**无**对照 spec 验收字段语义、required/类型/枚举、description 完备性、成功/错误体与 ADR-006/`error-codes.md` 对齐的专项流程或门禁（来源：用户指令 2026-08-21） | 能力缺口 | capabilities/skills/contract-change, gates/scripts/check-contracts, capabilities/prompts/contract-review.prompt.md, ADR-006 | open |
