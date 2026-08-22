<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W34 · 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.2（与用户旅程 v1.2 差异收敛版）为当前需求基线，specs 已拆解为 9 个 feature spec 并完成 v1.0→v1.2 同步，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）

## 进行中的 specs
- specs/001-conversation ~ specs/009-notification：均为 Draft 状态，待产出 plan.md

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 架构待确认项已收窄至 **1 项**（护栏检测服务实现，待 PoC），其余 11 项均已确认关闭。
- 各 feature spec 未决问题散布在「未决问题」或 plan 待确认章节；PRD §13.10 共 16 项已全部确认或关闭（第 2、10、11、12、16 项于 2026-08-21 确认，第 13 项经设计变更关闭，第 1、3、4、5、6、7、8、9、14、15 项于 2026-08-22 BA 裁定）；开工前必裁项已全部关闭；002/005 Open Questions 已清零，spec 侧遗留待确认以非 002/005 条目与准入测评模板维护归属（004/008）为主。
- 契约门禁已于 2026-08-22 修复并通过（watchlist #48 closed）；遗留一项回溯确认：main 上 "update api" 提交删除 `DELETE /mgmt/knowledge/knowledge-bases/{kbId}` 未经消费方确认（watchlist #49，责任人 Zhang Hao）。
- 里程碑日期（M1/M2/M3）仍为 `[待确认]`。
- 环境与账号阻塞（2 项未闭环）：Alice admin 账号待申请（最晚 2026-08-19）、Azure→SharePoint 方案进行中；GitHub 账号已开通（2026-08-17）。

## 近期重要变化
- 2026-08-22：spec 002 经 BA Lead 逐项复核（14 组差异全部确认采纳、零修改），BA 终审通过，可交架构写 plan；002 无 Zeng Ziyang 提交（其提交仅涉 001，注意其使用本人 SSH key + BA 账号、user name 为 Zeng Ziyang）。
- 2026-08-22：spec 001 的 spec-kit 风格重写（Zeng Ziyang）经 BA Lead 逐项复核（17 项）后整合：15 项澄清裁定采纳（透传上下文归资产、生成期禁发、三类失效只读回看、免流式接入、会话软删除等），3 处修正（去重粒度改按切片对齐 §9.10、软删除留存改脱敏口径、M1-16 过期条目不回植），P0/P1 边界与契约兼容口径按 main 回植；新增 watchlist #50（透传缓冲链路护栏机制待 Zhang Hao 确认）。
- 2026-08-22：`chore/ba-open-items-sync` 合入 main（cb1c992）——PRD §13.10 全部关闭、002/005 待确认清零；Chat 边界收敛为 P0 不调用平台原生 MCP/已上架资产、P1 预留 Chat 调用已订阅 MCP 资产工具；契约兼容字段（tool_call/toolCalls/snapshotAt）保留；契约门禁修复并转绿（含门禁脚本 oasdiff 误报修复）；chunkId 补齐声明的 oasdiff flag 经人工豁免（理由见合并提交）。
- 2026-08-21：ADR-007（A2A 协议统一）产出——agent-service 只暴露 A2A 端点，mgmt-service 为前端提供自定义对话接口，状态 Proposed。
- 2026-08-21：ADR-006（统一成功响应包络 ApiResponse）产出，error-codes.md 补充成功响应格式章节，watchlist #30 关闭。
- 2026-08-21：spec 002/005 经 grill-with-docs 细化评审——002 新增订阅治理闭环（重复申请入口置灰、禁止自审、Owner 免订阅自用、热门榜口径、收藏上限、审批进展粒度等），005 新增 7 组 FR（停用维护面、重跑起点、分享授权约束、重命名唯一、更新接口语义、向量数口径等），全部改动附决策 rationale；新业务规则已回写 PRD v1.2（§9.2/§9.6/§9.7/§9.10/M2/M4/M7）与 CONTEXT.md，§9.10 参数基线已收敛为 28 行。
- 2026-08-22：PRD §13.10 剩余 10 项经 BA interview 裁定并全部关闭；002/005 Open Questions 清零；留存口径改为对话内容与命中原文脱敏/遮蔽后保留 90 天，005 构建失败原因增加「其他内部错误/未知错误」兜底。
- 2026-08-21：PRD §13.10 五项澄清落入 specs——第 2/10/12/16 项确认关闭（含「模型类资源全部经 Nexus 供给」）；第 13 项设计变更：**取消会话级快照**，知识库停用/软删除/回草稿/权限回收均立即生效、进行中会话与新会话一视同仁（001 AC-10、005 FR-032/FR-034/SC-004 等随之改写）。
- 2026-08-21：PRD v1.2 与用户旅程 v1.2 归档至 docs/，specs/001–009 完成 v1.0→v1.2 同步——Chat 能力收窄为两项、平台原生工具仅作知识导入通道、资产凭据按平台内／平台外场景区分、取消人工推荐位（US-21/US-128 删除）、通知 13→12 类。PRD v1.2 补用户故事 5 条（54b、93b、96b、96c、96d，总数 152→157），005 随之补齐分享授权（FR-058~061）、重命名/就绪度/批量参数（FR-055~057）与执行者分级，002 补创作者中心四统计卡；005 建库角色收紧已裁定并落地，准入测评模板维护归属 004/008 仍待开发团队/架构师确认。
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
