# Specification Quality Checklist: 资产创建与质量门控（spec 003）

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-23
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — 仅引用协议名（A2A）与既有鉴权方式枚举（PRD §1.1 专有名词待遇），未写实现方式
- [x] Focused on user value and business needs — 五个用户故事均从 Owner 视角描述价值
- [x] Written for non-technical stakeholders — 中文业务语言，术语遵循 PRD §1 与写作规范（Owner 恒指资产负责人、无禁用词）
- [x] All mandatory sections completed — User Scenarios & Testing / Requirements / Success Criteria 齐备

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain — 2026-08-23 澄清会话 5 问全部裁定并回写；Open Questions 仅剩 1 条（Agent Card 重试策略，watchlist #44），1 条已随裁定关闭（动态凭据校验深度）
- [x] Requirements are testable and unambiguous — 26 条 FR 均带可验证行为与 PRD 出处
- [x] Success criteria are measurable — SC-001~009 均含量化口径（100%/0 次/具体秒数）
- [x] Success criteria are technology-agnostic (no implementation details) — 无框架/语言/存储表述
- [x] All acceptance scenarios are defined — 五个用户故事共 28 条 Given/When/Then
- [x] Edge cases are identified — 8 条（草稿续填、拉取失败、探测超时、单人创建、重名、审批人失效、YAML 编辑错误）
- [x] Scope is clearly bounded — Non-Goals 7 项 + 邻接 spec 边界（002/004/006/007/008）
- [x] Dependencies and assumptions identified — Assumptions 6 条（含 1 条实现侧合理默认待 plan 确认）

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria — FR 与用户故事场景互相覆盖，附录提供 AC→FR 追溯
- [x] User scenarios cover primary flows — Agent 向导 / MCP 向导 / 门控 / 鉴权凭据 / 审批链五条主路径
- [x] Feature meets measurable outcomes defined in Success Criteria — SC 与 FR 一一对应可验
- [x] No implementation details leak into specification — 通过

## Notes

- 本次为 PRD v1.2 对齐重写（AC 格式 → spec-kit 风格，对齐 spec 001/002/004/005 基准）；新增 10 条 FR 补全 v1.2 与跨 spec 裁定口径（A2A 前置条件、名称唯一校验联动 spec 004 FR-040、负责人冗余有效账号口径、门控快照语义、MCP 无护栏绑定等）。
- 数值均带单位与范围并溯源 PRD §9.10 已审定基线（超时 30 秒/5–120 秒、重试 1 次/0–3 次、探测 10 秒、审批 3 级/10 人）。
- 重写后 Status 维持 Draft，待 peer review 后再升 Reviewed（参照 001/002/004/005 流程）。
- 2026-08-23 澄清会话（5 问）：协作式草稿（FR-004）；Health Check 强制必选、消除开关（FR-007，已回写 PRD；peer review 暂缓经用户终审驳回、维持成立，watchlist #56 关闭）；能力声明只读镜像（FR-010/014）；MCP 托管方式 P0 单值「远程服务（业务方自托管）」（FR-013）；旧动态凭据真实鉴权探测口径已于 2026-08-24 凭据模型修订后撤销（创建者只声明凭据元数据，订阅者侧/平台代颁发侧再真实校验）。
- 2026-08-23 用户终审（Zeng Ziyang peer review 提交 4b1c90f/57f3008）通过，Status 升 Reviewed。
- 2026-08-23/24 全量审阅二次澄清：MCP 协议 P0 单值「Streamable HTTP」（FR-013，Zhang Hao 已审核确认，watchlist #53 closed）；名称占用时点＝提交门控时、草稿可同名（FR-003）；旧密钥值轻发布通道已于 2026-08-24 随凭据模型修订撤销，创建者只声明凭据元数据（FR-008/009/US4/实体同步）。B 类合理默认落 Assumptions（门控串行幂等、草稿乐观锁、审批人配置校验）。PRD 与 hub ADR 已同步回写。
- 2026-08-23 双资产一致性复审（Agent↔MCP，2 问）：MCP 链接配置补齐 Health Check 探测与超时/重试，两类资产接入配置字段集同构（FR-013）；固定/单值协议字段统一只读展示（FR-007/013）。其余七项差异经审计确认为有据设计（测评/护栏/能力声明来源/门控项数/去使用/状态机/通知），保留不拉平。观察项备查：002 侧 Agent 详情页缺「凭据状态」页签（MCP 有），列入 002 复审清单。
- specs/** 属守门点：本次改动未经人审不得合并入主干。
