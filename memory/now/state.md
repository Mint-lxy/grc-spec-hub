<!-- 自动区块：由 memory-digest 管线维护摘要性内容；人工可在人审 PR 中订正 -->
# 项目现状总览

> 更新于：2026-W28（占位）· 维持 ≤ 2 页

## 所处阶段
项目启动，第 0 周奠基中。PRD v1.0 已定稿，specs 已拆解为 9 个 feature spec，服务拆分 ADR 已产出。

## 本里程碑目标
- M1：P0 核心交付——平台全链路跑通（目标日期待确认）

## 进行中的 specs
- specs/001-conversation ~ specs/009-notification：均为 Draft 状态，待产出 plan.md

## 当前风险
- 记忆腐化是本体系最大单点风险 → 依赖每周 digest 审核纪律。
- 5 项架构待确认项（护栏实现/BFF/会话存储/Health Check/mgmt 拆分时机）需尽快 PoC。

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
