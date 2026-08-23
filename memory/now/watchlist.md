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
| 44 | 【BA 跟进】非 002/005 spec 未决项继续跟踪：001 模型兜底 UX/输出缓冲首段延迟；003 ~~动态凭据校验深度~~（2026-08-23 已裁定：真实鉴权换取令牌）/Agent Card 重试；004 裁判模型算力并发；006 护栏性能基准/违禁词上限；007 SDK 凭据缓存 TTL（2026-08-23 口径：参照值 60 秒＝当前实现，实现先行不构成既定标准，待架构确认后入 §9.10 审定）；008 平台资源监控告警；009 通知去重/抑制间隔（009 两项已于 2026-08-23 裁定关闭：不去重 + 失败链抑制，待核销）。001 两项已随 spec-kit 重写保留为 spec Open Questions：输出缓冲首段延迟需 Zhang Hao 压测输入（紧急，见 #50 同链路）；模型兜底 UX 提示由 BA 先拟文案草稿 | BA 跟进 | specs/001/003/004/006/007/008/009 各「未决问题」或 plan 待确认节 | open |
| 45 | 【责任人：Zhang Hao】【紧急——spec 001 进 plan 的前置】ADR-007（A2A 协议统一，状态 Proposed）需决策是否 Accept：若 Accept，grc-agent-service 自定义 REST+SSE 端点将替换为 A2A handler（`/.well-known/agent.json` + `POST /a2a`），mgmt-service chat-agent domain 需新增 A2A 客户端，gateway 路由与 `grc-agent-service.yaml` 契约需整体调整；001 已裁定透传上下文归资产（FR-021，需透传接口含会话 ID 字段），该契约影响必须与 ADR-007 的 Accept 决策联动落地；当前不动代码，等 ADR Accept 后再改 | 架构决策 | ADR-007, spec 001 FR-021, grc-agent-service, grc-mgmt-service, grc-api-gateway | open |
| 46 | 【责任人：Zhang Hao】服务 owner 仍为 `@todo-owner`，需填实 `architecture/services.manifest.yaml` 与 `architecture/service-map.md` 的 9 个服务负责人；否则工单认领、契约消费方确认与人审守门点缺少责任闭环 | 责任归属 | architecture/services.manifest.yaml, architecture/service-map.md | open |
| 47 | 【责任人：Zhang Hao】架构/API/横切规范未决项需统一收敛：api-landscape 待评审 11 项、认证授权横切规范、可观测性状态、000-platform plan 中护栏执行与 CI/CD、契约骨架填充优先级；需形成 plan 阶段输入或拆分工单 | 架构/API/横切 | specs/000-platform/api-landscape.md, architecture/cross-cutting/auth.md, architecture/cross-cutting/observability.md, specs/000-platform/plan.md, contracts/ | open |
| 48 | `check-contracts.sh` 未通过——已修复（2026-08-22，合入 main @ cb1c992）：mcp-server/knowledge-engine YAML 引号 ×3、auth-service 7 处 nullable 迁移 3.1 union type、8 处 security 声明补齐（内部服务根级 bearerAuth 对齐 mgmt，healthz/login/verify/refresh/oauth 显式 `security: []`）、saveDocumentChunk 补 chunkId 路径参数、npx 缓存清理、门禁脚本 oasdiff 误报修复（仅 error/warning 级判失败，.sh/.ps1 同步）。人工豁免：chunkId 补齐声明的 `new-request-path-parameter` flag 属无效契约修复，理由记录于合并提交 cb1c992 | 契约门禁 | contracts/, gates/scripts/check-contracts.sh, contracts/POLICY.md | closed |
| 49 | 【责任人：Zhang Hao】远端 main 的 "update api" 提交（eea6cec）删除了 `DELETE /mgmt/knowledge/knowledge-bases/{kbId}` 端点，oasdiff 报 `api-removed-without-deprecation`——真实破坏性变更，未见 service-map 消费方逐一确认记录；需回溯确认删除是否有意、消费方是否知情，必要时补确认或恢复 | 契约治理 | contracts/openapi/grc-mgmt-service.yaml, contracts/POLICY.md, architecture/service-map.md | open |
| 50 | 【责任人：Zhang Hao】【紧急——spec 001 进 plan 的前置】透传缓冲链路的护栏处理机制待确认：spec 001 已裁定透传会话免流式接入（平台缓冲资产完整响应 → 输出侧护栏检测 → 按段回放，2026-08-22 BA Lead 复核采纳），需确认护栏在该链路的处理机制可行——检测位置（网关/护栏服务）、检测超时、长响应缓冲上限；同链路输出缓冲首段延迟需压测输入（spec 001 Open Questions） | 架构决策 | spec 001 FR-022/FR-023, ADR-007, watchlist #1/#45 | open |
| 51 | 【责任人：Li Zhonghao】spec 005 构建管线改动需开发侧跟进（2026-08-23 BA Lead 复核裁定）：① 解析器收敛为 Docling/MinerU，不使用 DeepDoc——实现快照 `Implementation-Snapshot/KB-coding/knowledge-engine` 的 `pipeline_config_validator.py` 合法解析器集合与两份 Api 清单中的 deepdoc 参数需移除；② 切片/增强/解析器/向量化/重排序参数矩阵（FR-038）请审阅可行性；③ 语言提示为中文/英文/德语/自动检测 | 开发跟进 | spec 005 FR-038, Implementation-Snapshot/KB-coding | open |
| 52 | 【架构/开发待确认】准入测评任务整体超时上限——2026-08-23 spec 004 澄清建议值 30 分钟（超时视同执行失败、可重测）；需架构/开发确认可行性后补入 PRD §9.10 参数基线审定，审定前不作为工单基线 | 基线 | spec 004 FR-010, PRD §9.4/§9.10 | open |
| 53 | 【责任人：Zhang Hao 审核】MCP 协议枚举 P0 单值「Streamable HTTP」的技术口径确认——2026-08-23 spec 003 澄清裁定（用户裁定附审核备注）；审核通过后关闭 spec 003 对应 Open Question | 技术审核 | spec 003 FR-013, contracts/openapi/grc-mgmt-service.yaml | open |
| 54 | 通知事件归类一揽子裁定——**已关闭（2026-08-23 spec 009 澄清会话用户裁定）**：中止发布/密钥值轻发布/发布失败合并为一类「资产治理通知（负责人）」（十二 → 十三类），受众统一收窄为负责人侧（密钥值不再通知订阅者——平台与资产的契约非订阅者契约）；轻发布双载荷按受众拆分两条；已回写 PRD M9-1/§9.1.1/版本说明补遗、spec 009 FR-033/FR-034、spec 004 FR-018、CONTEXT.md 与 ADR-0014 补注 | spec 对齐 | spec 009 FR-033, spec 004 FR-018, PRD M9-1 | closed |
| 55 | spec 002/003/004 peer review 与终审——**已关闭（2026-08-23）**：Zeng Ziyang grill 复核 003/004（提交 4b1c90f/57f3008，补入 FR-041~045 等）；用户终审 13 项逐项裁定——采纳 FR-041/042/043/044/045 与版本号/说明口径转正，确认两项自我推翻项（中止不留痕、重测不收紧），驳回 HC 暂缓（#56 关闭），002 增补由用户终审追认；002 维持 Reviewed，003/004 升 Reviewed | 评审 | specs/002/003/004 | closed |
| 56 | Health Check 开关存废分歧——**已关闭（2026-08-23 用户终审）**：维持「HC 强制必选、消除开关」，驳回 peer review 暂缓；补充理由：HC 可关闭则资产失效无法触达时订阅者与平台无从知晓实际服务健康状态；spec 003 FR-007/FR-013 与 PRD 强制表述维持，无回滚 | spec 分歧 | spec 003 FR-007/FR-013, PRD v1.2 版本说明 2026-08-23 补遗 | closed |
| 57 | 【催办，2026-08-23 用户指示】【责任人：Zhang Hao】#45（ADR-007 A2A Accept 决策）与 #50（透传缓冲链路护栏机制 + 首段延迟压测输入）同链路，建议合并为一次架构确认会话一次出结论；二者是 spec 001 进 plan 的前置（plan「涉及服务/契约影响」两章在决策前无法定稿），优先级紧急 | 催办 | watchlist #45/#50, spec 001, ADR-007 | open |
| 58 | 【架构/开发待确认】个人出站凭据一键探测的真实认证调用设计——2026-08-23 spec 007 澄清裁定口径为真实鉴权（与 003 同构，全平台探测强度统一），但对三类目标（平台外资产/平台原生工具/Nexus）的认证调用形态与副作用约束需架构/开发设计确认 | 架构决策 | spec 007 FR-015, spec 003 FR-008 | open |
| 59 | 【责任人：Zhang Hao 决定】**个人模型凭据调用失败的「失效 vs 抖动」判定基线**。背景：个人模型凭据调用失败时平台按失败类型走两个分支——凭据失效类（令牌过期、无权限）＝本次调用改用平台默认凭据 + 可用性快照对应模型置不可用 + 通知本人处理；瞬时故障类（网络抖动、对方超时/临时宕机）＝不改快照、不通知、下次照常再试。判错方向的代价：误判为失效→凭据被冤枉标记不可用且用户收到骚扰通知；误判为抖动→每次调用先失败再兜底且用户不知凭据已坏。需要决定的：以什么信号区分两类——建议基线为 HTTP 401/403＝失效类、网络错误/超时/5xx＝抖动类（Nexus 为 HTTP 网关），混合与非标响应的归类一并裁定。该基线是 spec 007 验收标准「失效类 100% 触发回落与通知、抖动类 0 触发」可测的前提。2026-08-23 BA 明确：非 BA 裁定事项，由 Zhang Hao 处理并决定，spec 007 按待澄清依赖项挂起 | 架构决策 | spec 007 FR-021/SC-003, contracts/openapi/grc-mgmt-service.yaml（vault 子域 report-credential-failure） | open |
| 60 | 【高优——责任人：Zhang Hao 查看确认，2026-08-23 用户指示】凭据体系四类总览与编辑范围矩阵（spec 007「背景与目标」总览表 + FR-017）：四类凭据（PAT 入站/个人出站/资产级服务/平台资源）的无歧义定义、编辑范围（PAT 创建后锁定、平台外调用凭据无可编辑内容、导入通道与 Nexus 凭据仅凭据值可编辑且保存后自动重检/探测）、取消 PAT 重新生成与有效期延长、审计三元组粒度、PAT 到期不提醒仅列表呈现——请高优查看确认与既有实现（python-sdk、mgmt vault 子域）无冲突 | 架构复核 | spec 007, PRD §9.3, grc-python-sdk, grc-mgmt-service | open |

## 文档缺口

| # | 项目 | 类型 | 关联 | 状态 |
|---|------|------|------|------|
| 30 | API 成功响应包络（`ApiResponse`）已规范——ADR-006 定义统一包络（`code:0` 为成功），`error-codes.md` §1 补充成功响应格式与分页结构（2026-08-21） | 文档缺口 | architecture/adr/006-api-response-envelope.md, architecture/cross-cutting/error-codes.md | closed |
| 46 | 需单独 skill/手段保障后端接口**请求参数正确性、返回体正确性、参数字段说明完整**——现有 `/contract-change` + `gates/scripts/check-contracts` 仅覆盖 OpenAPI/AsyncAPI 语法与破坏性变更（oasdiff），`contract-review` 偏消费方影响；**无**对照 spec 验收字段语义、required/类型/枚举、description 完备性、成功/错误体与 ADR-006/`error-codes.md` 对齐的专项流程或门禁（来源：用户指令 2026-08-21） | 能力缺口 | capabilities/skills/contract-change, gates/scripts/check-contracts, capabilities/prompts/contract-review.prompt.md, ADR-006 | open |
