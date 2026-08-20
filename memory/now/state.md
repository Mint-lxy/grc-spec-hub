<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W33 · 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.2（与用户旅程 v1.2 差异收敛版）为当前需求基线，specs 已拆解为 9 个 feature spec 并完成 v1.0→v1.2 同步，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）

## 进行中的 specs
- specs/001-conversation ~ specs/009-notification：均为 Draft 状态，待产出 plan.md

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 架构待确认项已收窄至 **1 项**（护栏检测服务实现，待 PoC），其余 11 项均已确认关闭。
- 各 feature spec 共 27 项未决问题散布在「未决问题」章节，其中合规类（3 项）与外部依赖类（Key Vault/Alice，3 项）阻塞面最大；v1.2 同步遗留待确认 2 项（005 建库角色收紧、准入测评模板维护归属）。
- 里程碑日期（M1/M2/M3）仍为 `[待确认]`。
- 环境与账号阻塞（2 项未闭环）：Alice admin 账号待申请（最晚 2026-08-19）、Azure→SharePoint 方案进行中；GitHub 账号已开通（2026-08-17）。

## 近期重要变化
- 2026-08-21：PRD v1.2 与用户旅程 v1.2 归档至 docs/，specs/001–009 完成 v1.0→v1.2 同步——Chat 能力收窄为两项、平台原生工具仅作知识导入通道、资产凭据按平台内／平台外场景区分、取消人工推荐位（US-21/US-128 删除）、通知 13→12 类。PRD v1.2 补用户故事 5 条（54b、93b、96b、96c、96d，总数 152→157），005 随之补齐分享授权（FR-058~061）、重命名/就绪度/批量参数（FR-055~057）与执行者分级，002 补创作者中心四统计卡；遗留待确认 2 项（005 建库角色收紧、准入测评模板维护归属 004/008）。
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
