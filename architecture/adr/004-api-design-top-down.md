# ADR-004: API 设计采用自顶向下流程——先全局概览再逐服务契约化

> 状态：Accepted
> 日期：2026-08-17 · 决策者：@nzhang · 关联 spec：`specs/000-platform`

## 背景

项目已完成服务拆分（ADR-001）和 9 个 feature spec 的 WHAT/WHY 定义（specs/001–009），
但所有 feature 均未产出 plan.md，`contracts/` 下也没有任何正式契约。
团队需要一种系统化的方式推进 API 设计，使各服务的接口在动手写 plan 和 contract 之前
就能在全局层面对齐——避免各 feature 各自定义接口时出现重复端点、职责冲突或跨服务依赖遗漏。

## 决策

采用**三阶段自顶向下**的 API 设计流程：

1. **全局概览** — 在 `specs/000-platform/api-landscape.md` 中，按服务分组列出所有粗粒度 API 端点（HTTP 方法 + 路径 + 一句话描述 + 所属 spec），不含请求/响应 schema。
2. **评审确认** — 以此概览为蓝本组织团队评审，确认各服务的职责边界和端点归属。
3. **逐 feature 契约化** — 评审通过后，按 feature 编写 `specs/NNN/plan.md`（含 API 章节），并将确定的接口沉淀为 `contracts/openapi/*.yaml` 正式契约。

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 各 feature 直接写 contract | 去中心化，各组并行 | 缺乏全局视角，端点重复/冲突风险高，服务边界争议后置 | 服务间依赖密集（ADR-001 D7 列出 6 个事件主题），需要先对齐 |
| 一次性写完所有 OpenAPI 契约 | 一步到位 | 粒度太细、工作量太大、评审周期长，且需求尚有 open items | 投入产出比差，易过早过度设计 |

## 影响

- 受影响服务：全部（api-landscape 覆盖所有服务的对外端点）
- 契约影响：本 ADR 不直接产出 contract，但约定 contract 必须从 api-landscape 评审结论衍生
- 迁移/回滚：如发现自顶向下流程过重，可随时切换为按 feature 独立出 contract

## 后果

### 正面
- 端点归属和服务边界在动手前就有全局共识
- 减少后期跨服务接口冲突和返工
- api-landscape.md 可作为新成员 onboarding 的 API 速查手册

### 负面
- 增加一层中间产物（api-landscape.md），需要维护其与正式 contract 的一致性
- 评审环节可能成为瓶颈，需控制评审粒度避免陷入细节
