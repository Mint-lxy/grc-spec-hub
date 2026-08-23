# Specification Quality Checklist: 密钥库与凭据体系（spec 007）

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-23
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — 仅引用协议/服务名作边界参照，未写实现方式
- [x] Focused on user value and business needs — 五个用户故事按角色视角（外部系统集成者、订阅者、凭据持有人、知识维护员、全员）组织
- [x] Written for non-technical stakeholders — 中文业务语言，术语遵循 PRD §1 与写作规范
- [x] All mandatory sections completed — User Scenarios & Testing / Requirements / Success Criteria 齐备

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain — 未决项以 Open Questions 两条承载（SDK 缓存 TTL 对账、失败判定细化，watchlist #44）
- [x] Requirements are testable and unambiguous — 22 条 FR 均带可验证行为与 PRD 出处
- [x] Success criteria are measurable — SC-001~009 均含量化口径（100%/0 次/具体数值）
- [x] Success criteria are technology-agnostic (no implementation details) — 无框架/语言/存储表述
- [x] All acceptance scenarios are defined — 五个用户故事共 21 条 Given/When/Then
- [x] Edge cases are identified — 7 条（下架联动、探测超时、全禁用兜底、多凭据排序、失败归类、账号恢复、管理员停用优先）
- [x] Scope is clearly bounded — Non-Goals 5 项 + 邻接 spec 边界（003/004/005/008）
- [x] Dependencies and assumptions identified — Assumptions 5 条（Key Vault 已确认、Nexus 全量供给已确认等）

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria — FR 与用户故事场景互相覆盖，附录提供 AC→FR 追溯
- [x] User scenarios cover primary flows — PAT 入站 / 平台外调用 / 模型类解析 / 导入通道 / 管理体验五个面
- [x] Feature meets measurable outcomes defined in Success Criteria — SC 与 FR 一一对应可验
- [x] No implementation details leak into specification — 通过

## Notes

- 本次为 PRD v1.2 对齐重写（AC 格式 → spec-kit 风格，对齐 001~005、009 基准）。
- **关键修正**：原 AC-17「密钥值属热改类」已过时——按 2026-08-23 裁定更新为「鉴权声明版本类、密钥值轻发布通道、通知收窄为全体负责人」（FR-034）。
- 重写补齐 §9.10 已审定基线：PAT 上限 20 个/永不过期、个人模型凭据上限 5 条、检测与探测超时 10 秒；补触发人枚举（FR-020）与适用域边界（FR-022）；补知识库三接口权限与我的目录分级（FR-041）。
- 重写后 Status 维持 Draft，待 peer review 后升 Reviewed（参照 001~005、009 流程）。
- specs/** 属守门点：本次改动未经人审不得合并入主干。
- 2026-08-23 澄清会话（5 问）：动作语义统一（停用可逆/删除终态/撤销并入删除，FR-003/011）；平台外调用凭据不设独立有效期（FR-011）；SDK TTL 记录为架构待确认项（参照 60 秒，实现非权威）；探测口径统一真实鉴权（FR-015，设计留 watchlist #58）；失效 vs 抖动判定基线转 Zhang Hao 决定（非 BA 裁定，挂为待澄清依赖项，watchlist #59）。PRD M7-1/M7-4/J8-1/§9.3/版本说明与 CONTEXT/glossary 已级联回写。
