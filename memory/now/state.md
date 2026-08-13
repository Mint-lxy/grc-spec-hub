<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W33 · 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.0 已定稿，specs 已拆解为 9 个 feature spec，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）

## 进行中的 specs
- specs/001-conversation ~ specs/009-notification：均为 Draft 状态，待产出 plan.md

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 12 项架构待确认项（ADR-001 §待确认）：含原始 5 项 + 新增 7 项（模型凭据解析/Gateway 状态投影/knowledge→mcp 凭据链路/knowledge→mgmt 隐藏依赖/会话快照语义/agent 事件消费/eval REST 消费）。
- 各 spec 共 21 项未决问题散布在 §4 章节，其中合规类（3 项）与外部依赖类（Key Vault/Alice/Nexus，4 项）阻塞面最大。
- 里程碑日期（M1/M2/M3）仍为 `[待确认]`。
- 环境与账号阻塞（4 项）：GitHub 账号未开通、Alice admin 账号待申请、Azure→SharePoint 方案进行中、Nexus Teams 与模型列表待对齐——影响开发启动。

## 近期重要变化
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
