<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W34 · 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.0 已定稿，specs 已拆解为 9 个 feature spec，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）

## 进行中的 specs
- specs/001-conversation ~ specs/009-notification：均为 Draft 状态，待产出 plan.md

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 架构待确认项已收窄至 **1 项**（护栏检测服务实现，待 PoC），其余 11 项均已确认关闭。
- 各 spec 共 29 项未决问题散布在 §4 章节，其中合规类（4 项）与外部依赖类（Key Vault/Alice/Nexus，5 项）阻塞面最大。
- 里程碑日期（M1/M2/M3）仍为 `[待确认]`。
- 环境与账号阻塞（2 项未闭环）：Alice admin 账号待申请（最晚 2026-08-19）、Azure→SharePoint 方案进行中；GitHub 账号已开通（2026-08-17）。

## 近期重要变化
- 2026-08-21：ADR-007（A2A 协议统一）产出——agent-service 只暴露 A2A 端点，mgmt-service 为前端提供自定义对话接口，状态 Accepted。
- 2026-08-21：ADR-006（统一成功响应包络 ApiResponse）产出，error-codes.md 补充成功响应格式章节，watchlist #30 关闭。
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
