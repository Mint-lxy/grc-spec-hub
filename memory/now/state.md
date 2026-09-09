<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W36（digest 2026-W35）· 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.2（与用户旅程 v1.2 差异收敛版）为当前需求基线，业务需求已拆解为 9 个 feature spec 并完成 v1.0→v1.2 同步；新增 spec 010/011 承载 AKS GPU 与开发 Milvus 基础能力，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）
- 9 月 MVP 节奏（2026-08-25 Qianqian 推动）：9/7 知识库开放接口供 defi 场景外部调用（INT 端到端首次业务测试）、9/14 与 9 月底分段交付；INT 先行、SSO 与完整权限体系上生产前必须补齐

## 进行中的 specs
- **001–009 共 9 个业务 feature spec 全部 Reviewed（需求面冻结）**：006-guardrail 与 008-admin 于 2026-08-25 经 grill-me 终审升 Reviewed（`b37e029`/`9670628`，用户授权）；基础设施 spec 010/011 于 2026-09-09 完成实现、持久化、回滚与重装验收
- 002/003/004/005/006/007/008/009 可直接进 plan；001 进 plan 前置为 watchlist #45/#50（紧急，Zhang Hao）

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 架构待确认项已收窄至 **1 项**（护栏检测服务实现，待 PoC），其余 11 项均已确认关闭。
- 各 feature spec 未决问题散布在「未决问题」或 plan 待确认章节；PRD §13.10 共 16 项已全部确认或关闭；002/005 Open Questions 已清零，003/004 经三轮澄清+终审后仅剩有归属的 watchlist 项；spec 侧遗留待确认：#22 测评阈值、#44 裁判模型算力与护栏/凭据缓存等架构参数、#52 测评超时 30 分钟审定、#58 个人出站凭据探测设计、#59 个人模型凭据失效 vs 抖动判定。#33 模板维护归属、#53 MCP 协议审核、#54 通知事件归类已关闭；#61 P0 护栏类型是否不含 PII 待客户确认。
- 契约门禁已于 2026-08-22 修复并通过（watchlist #48 closed）；遗留一项回溯确认：main 上 "update api" 提交删除 `DELETE /mgmt/knowledge/knowledge-bases/{kbId}` 未经消费方确认（watchlist #49，责任人 Zhang Hao）。**2026-08-27 新增同类**：`7c62373` 重写 grc-mgmt-service.yaml，vault 内部接口 `resolve-model`/`report-credential-failure` 被替换为 `tokens/verify` + `credentials/{id}/resolve`，版本未升 MAJOR、无消费方确认；消费方 grc-python-sdk 仍调旧端点，凭据解析链路断裂（digest 2026-W35）。
- 分支/基线风险（2026-W35）：全部服务仓库 active 开发在 feature/release260831，main 无回流、release/release260831 全面落后 feature（3~25 提交）；8/31 发版基线待确认。hub 侧 spec-sync-prd-v1.2 残余 1 提交（`2848b62`）未上 main；feat/chat-subdomain-memory-update、watchlist_emma 两分支含 memory/now 改动待处置。
- 里程碑日期（M1/M2/M3）仍为 `[待确认]`。
- 环境与账号阻塞（2 项未闭环）：Alice admin 账号待申请（最晚 2026-08-19）、Azure→SharePoint 方案进行中；GitHub 账号已开通（2026-08-17）。

## 近期重要变化
- 2026-09-09：**开发 Milvus 部署完成**——spec 011 使用 Chart 4.2.49 部署
  Milvus 2.5.12 Standalone + Rocksmq、单副本 etcd/MinIO；三个 64 GiB Premium PVC，
  `milvuspool` 配置 `sku=milvus:NoSchedule`。认证轮换、CRUD/search、逐组件重建、
  Helm rollback、卸载保留 PVC和重装恢复均通过；工件见 knowledge-engine
  `8593554`。生产 HA/备份/监控与许可证审查见 watchlist #86。
- 2026-09-09：**开发 AKS GPU 能力启用**——spec 010 采用现有 `gpupool` + 自管
  NVIDIA Device Plugin v0.18.0；节点配置 `sku=gpu:NoSchedule`，已上报
  `nvidia.com/gpu: 1`，Tesla T4 smoke test、隔离测试、回滚和重装均通过；
  `grc-parser-engine` 部署工件见 `513d51d`。生产复用前仍需重新验收，GPU 监控和
  NVIDIA 镜像许可证见 watchlist #85。
- 2026-08-28：**知识库会议待办登记与 spec 005 权限回写**——知识库页面角色权限 FR-037c~f 入 spec（`2e72686`，Viewer/Consumer/Contributor-Owner/无权限四档交互边界）；watchlist #75 关闭，新增 #76（建库表单与检索策略）/#77（构建信息展示）/#78（Overview KPI）open（`c6f697f`）。
- 2026-08-27：**mgmt 契约大改写（流程存疑）**——`7c62373` 重写 grc-mgmt-service.yaml（+1849/-992）：vault 内部 API 换成 `tokens/verify` + `credentials/{id}/resolve`；auth-service `a23cf4e` 同分钟联动，mgmt-service 已实现新端点；python-sdk 未跟随（见「当前风险」）。
- 2026-08-24~28：**服务仓库 release260831 冲刺**——ai-portal 落地 Marketplace M1/M3~M9 前端与知识库概览/设置（对齐 005 三档可见性）；mgmt-service 落地 Chat 子域（001）+ Marketplace 后端 + MCP 管理面；knowledge-engine/parser-engine 打通解析链路上传与状态回传；mcp-server 转 monorepo（conf/sharepoint/oss）；agent-service 补 SSE thinking 事件。均在 feature/release260831，未合并 main（详见 digests/2026-W35.md）。
- 2026-08-25：**006/008 经 grill-me 终审升 Reviewed（用户授权）**——006 裁定 4 项（停用终态补验收场景、SC-007 措辞），008 裁定 4 项（FR-052 措辞、补 FR-009、Story 标注统一、FR-011 维持 PRD 口径）；9 个 feature spec 需求面全部冻结。
- 2026-08-25：**005/001/000 经 grill-me 裁定回写（当日两场会议决议）**——005：删除三层语义（向量索引立即物理删／PG 原始 chunk+metadata 按可配置保留期保留供审计排查／平台不支持恢复完整知识库）、可见范围两档扩三档（公开可用／公开需申请／完全隐藏，公共目录默认公开需申请）、构建参数保存权限收敛为仅 Owner/Deputy、Owner/Deputy 空缺双层兜底（上级目录控制角色→Alice 侧管理员或应用账号）、一期静态推荐配置＋按文档类型动态推荐列 P1 扩展点；000：AC-G7 补知识库留存层、新增 AC-G8 统一清理任务（定时执行＋监控告警＋禁人工操作数据库）；001：新增回答渲染 FR-027b/c（表格横滑／代码块高亮行号复制／Mermaid 公式／防闪烁／不强制滚动／长回答折叠）、Chat 多模态本期不支持入 Non-Goals（原生视觉为主路线）；006 与会议口径核对一致零改动。契约与 FR-038/FR-011/FR-042 对齐差距及全部待定项登记 watchlist #62–#71（含 #70 重建机制细则待续谈终态后回写）。上午会议的中间过程状态流呈现为倩倩待办（下周一前补 001 细节、璇璇先评估），本次未改 001 该部分。
- 2026-08-25：**9 月 MVP 节奏（Qianqian 推动）**——9/7 一周优先知识库开放接口供 defi 场景外部系统调用（INT 环境端到端可首次业务测试）、9/14 与 9 月底分段交付，小步快跑 MVP、增强排到 1.1 及之后；INT 先行、SSO 与完整权限体系可滞后但上生产前必须补齐；云资源 PO 已提交（ITT 建独立 Microsoft subscription）；9/7 版本可用简化 UI。里程碑正式日期仍待确认（watchlist #13）。
- 2026-08-24：**凭据模型与负责人模型修订（项目组线下对齐后用户裁定）**——旧资产凭据模型整体取消（一切资产调用使用订阅者个人凭据：静态＝订阅者平台外获取→密钥库填入→详情页绑定；动态＝订阅通过后平台代颁发入库）；创建者只声明凭据元数据、全程不接触密钥值；密钥值轻发布通道撤销；首发成功才产生首位 Owner（中止/失败不产生），首发前指定 Deputy（可多位、≥1 位）自动成为草稿协作者，首发成功时创建者转 Owner、协作者转 Deputy；术语归一（资产侧统一使用创建者、Owner/Deputy、订阅者）。PRD §9.3/§9.1.1/§9.1.2/§4/J1/J2/J8/M2/M3/M7 与 specs 001/002/003/004/007/008/009、CONTEXT、glossary 已同步修订；新凭据模型替代口径由 ADR-005 承载，不新增单独 ADR。同日：006/007/008/009 完成 spec-kit 重写与澄清（006 采纳护栏滑动窗口机制基线＋命中零字留存＋模板不可变模型；007 取消 PAT 重新生成、动作语义统一、凭据编辑矩阵、审计三元组；008 收敛孤儿补员、角色权限并集、P0 模型生命周期只读、连接器技术鉴权与 Nexus 凭据对象引用；009 十三类通知含「资产治理通知」）。
- 2026-08-23：**spec 003/004 完成 spec-kit 重写 + 三轮澄清 + Zeng Ziyang grill 复核 + 用户终审（13 项），Status 升 Reviewed**（PR #2 合入 main @ 7a3c2cc）：004 新增发布任务语义/失败落点+失败通知/放弃修订/删除不通知/执行主体统一（FR-041~045），密钥值曾自热改移入轻发布第三通道（部分调整 v0.9，后续已于 2026-08-24 随旧资产凭据模型取消而撤销），发布全互斥与配置冻结、中止即取消测评、模板发起时快照；003 裁定协作式草稿、HC 强制必选（终审驳回暂缓，#56 关闭）、能力声明只读镜像、MCP 托管/协议单值与接入字段集同构、名称占用时点＝提交门控时。002 增补 Agent 详情页「凭据状态」页签（v1.2 升版遗漏修复，终审追认）。PRD v1.2 版本说明新增 2026-08-23 补遗并全文回写，hub 归档副本与 BA 原件（af17d40）逐字节一致；CONTEXT.md 与 ADR-0014 同步。联合工作区规则增补「基础文档回写流程：AI 起草+人确认提交」。
- 2026-08-23：**spec 001/002/005 需求面冻结（BA Lead）**：三个 spec 的 Status 由 Draft 升为 Reviewed，FR 集合不再增减、后续变更须经 BA Lead 复核；002/005 可直接进 plan，001 进 plan 前置为 watchlist #45/#50（紧急，Zhang Hao）。001 兜底 UX 裁定：一次性横幅提示、不新增站内通知。
- 2026-08-23：BA 工作区（ba-init-toolkit，本地 master 无远端）完成整理提交——设计文档主线 b73d9a8（PRD v0.7–v1.2 全版本归档、用户旅程 v1.0–v1.2、ADR 0014–0016、CONTEXT 47 词条；PRD v1.2 与 spec-hub 版逐字节一致）；Implementation-Snapshot 归档内容经用户确认无实际作用已从磁盘删除并落账（c6c1a6d；git 历史副本在 020f6cd，嵌套仓库 gitlink 已于 263ff7e 从索引移除）；`.devin/` 本地配置不入库。
- 2026-08-23：spec 005 经 BA Lead 逐项复核（19 组）：全部采纳 + 4 处修正——解析器收敛 Docling/MinerU（不使用 DeepDoc，PRD §1.3/M4-12 同步）、语言提示改中文/英文/德语、更新接口显式不支持 ZIP 直接更新、建库角色统一全称表述；补齐 spec-kit 头部与质量检查单；新增 watchlist #51（Li Zhonghao 跟进实现侧 deepdoc 移除与参数矩阵审阅）。
- 2026-08-22：spec 002 经 BA Lead 逐项复核（14 组差异全部确认采纳、零修改），BA 终审通过，可交架构写 plan；002 无 Zeng Ziyang 提交（其提交仅涉 001，注意其使用本人 SSH key + BA 账号、user name 为 Zeng Ziyang）。
- 2026-08-22：spec 001 的 spec-kit 风格重写（Zeng Ziyang）经 BA Lead 逐项复核（17 项）后整合：15 项澄清裁定采纳（透传上下文归资产、生成期禁发、三类失效只读回看、免流式接入、会话软删除等），3 处修正（去重粒度改按切片对齐 §9.10、软删除留存改脱敏口径、M1-16 过期条目不回植），P0/P1 边界与契约兼容口径按 main 回植；新增 watchlist #50（透传缓冲链路护栏机制待 Zhang Hao 确认）。
- 2026-08-22：`chore/ba-open-items-sync` 合入 main（cb1c992）——PRD §13.10 全部关闭、002/005 待确认清零；Chat 边界收敛为 P0 不调用平台原生 MCP/已上架资产、P1 预留 Chat 调用已订阅 MCP 资产工具；契约兼容字段（tool_call/toolCalls/snapshotAt）保留；契约门禁修复并转绿（含门禁脚本 oasdiff 误报修复）；chunkId 补齐声明的 oasdiff flag 经人工豁免（理由见合并提交）。
- 2026-08-21：ADR-007（A2A 协议统一）产出——agent-service 只暴露 A2A 端点，mgmt-service 为前端提供自定义对话接口，状态 Proposed。
- 2026-08-21：ADR-006（统一成功响应包络 ApiResponse）产出，error-codes.md 补充成功响应格式章节，watchlist #30 关闭。
- 2026-08-21：spec 002/005 经 grill-with-docs 细化评审——002 新增订阅治理闭环（重复申请入口置灰、禁止自审、Owner 免订阅自用、热门榜口径、收藏上限、审批进展粒度等），005 新增 7 组 FR（停用维护面、重跑起点、分享授权约束、重命名唯一、更新接口语义、向量数口径等），全部改动附决策 rationale；新业务规则已回写 PRD v1.2（§9.2/§9.6/§9.7/§9.10/M2/M4/M7）与 CONTEXT.md，§9.10 参数基线已收敛为 28 行。
- 2026-08-22：PRD §13.10 剩余 10 项经 BA interview 裁定并全部关闭；002/005 Open Questions 清零；留存口径改为对话内容与命中原文脱敏/遮蔽后保留 90 天，005 构建失败原因增加「其他内部错误/未知错误」兜底。
- 2026-08-21：PRD §13.10 五项澄清落入 specs——第 2/10/12/16 项确认关闭（含「模型类资源全部经 Nexus 供给」）；第 13 项设计变更：**取消会话级快照**，知识库停用/软删除/回草稿/权限回收均立即生效、进行中会话与新会话一视同仁（001 AC-10、005 FR-032/FR-034/SC-004 等随之改写）。
- 2026-08-21：PRD v1.2 与用户旅程 v1.2 归档至 docs/，specs/001–009 完成 v1.0→v1.2 同步——Chat 能力收窄为两项、平台原生工具仅作知识导入通道、资产凭据按平台内／平台外场景区分、取消人工推荐位（US-21/US-128 删除）、通知曾由 13 收敛为 12 类（后续 2026-08-23/24 已由 009 的十三类 P0 设计全集取代）。PRD v1.2 补用户故事 5 条（54b、93b、96b、96c、96d，总数 152→157），005 随之补齐分享授权（FR-058~061）、重命名/就绪度/批量参数（FR-055~057）与执行者分级，002 补创作者中心四统计卡；005 建库角色收紧已裁定并落地，准入测评模板维护归属 004/008 仍待开发团队/架构师确认。
- 2026-08-20：spec 005 知识管理构建管线参数经 5 轮澄清细化（解析器缩减为 Docling/MinerU、切片/增强/向量化/重排序参数枚举）。
- 2026-08-17：ADR-004（API 设计自顶向下）产出，状态 Accepted；全局 api-landscape.md 创建。
- 2026-08-17：ADR-005（凭据解析归属 mgmt-service）产出，状态 Accepted。
- 2026-08-14：ADR-001 架构待确认项批量收窄（11/12 已关闭）：BFF 选 mgmt、不拆分 mgmt、模型凭据经 SDK、会话数据归 mgmt chat-agent domain、gateway 拉取缓存、mcp 自行解析凭据、KB 快照缓存 ID 列表、agent 不订阅事件、eval 改事件驱动、P0 不做 Health Check、knowledge→mgmt 依赖正式声明。
- 2026-08-14：ADR-003（AI SDK）产出——grc-ai-sdk 将凭据解析与模型调用合并，状态 Proposed。
- 2026-08-14：Nexus Teams 创建 + 模型订阅已关闭。
- 2026-08-13：ADR-001 状态升为 Accepted；依赖关系修正（knowledge→parser、agent→mcp、gateway→mcp）同步至 service-map 与 manifest。
- 2026-08-13：PRD v1.0 定稿，9 个 feature spec 拆解完成。
- 2026-08-13：ADR-001（服务拆分）、ADR-002（错误码规范）产出。
- 2026-08-13：services.manifest.yaml 与 service-map.md 填实为 8 服务。
- 2026-08-13：cross-cutting/error-codes.md 落地统一错误码规范。
<!-- /自动区块 -->

<!-- 人工区块 -->
## tech lead 备注
- 第 0 周奠基会后，用真实里程碑与服务替换本页占位内容。
<!-- /人工区块 -->
