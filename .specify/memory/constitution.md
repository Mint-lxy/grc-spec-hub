# 平台项目宪法（Constitution）

> 位置：Spec Kit 原生位置 `.specify/memory/constitution.md`（归属事实层，锦点见 `hub.config.yaml` 的 `sources.constitution`）
> 作用：spec 工作流引擎全流程校验的不可协商原则（当前引擎 Spec Kit 在 specify/plan/analyze/implement 各环节校验）。
> 变更方式：宪法本身的修改必须走 PR + 全员评审，并在下方"修订记录"登记。

<!--
维护提示：
- 宪法要短、要硬。每条原则应可被 CI 或人审明确判定"违反 / 未违反"。
- 多服务 + 纯 AI coding 场景下，最容易失控的是"服务边界"与"契约纪律"，因此这两条写得最严。
- 修改任何一条"不可协商"原则前，先在 architecture/adr/ 记录一条 ADR 说明原因。
-->

## 一、Spec 先行（不可协商）

任何代码变更必须可追溯到 `specs/` 下的一个 spec。没有 spec 的需求先走
SOP 的 specify 阶段（各框架命令对照见 `sop/README.md`）。紧急修复可以先改后补，但"补 spec"是合并的前置条件，
且必须在 PR 描述中标注 `hotfix-pending-spec` 并链接后续 spec issue。

## 二、契约先行（不可协商）

任何跨服务接口（REST / 事件 / 共享模型）的新增或变更，必须先在
`contracts/` 提 PR 并通过契约门禁，代码实现只能引用**已合并**的契约版本。
服务内部接口不受此约束。破坏性变更必须获得 `service-map.md` 中列出的
全部消费方确认后方可合并。

## 三、测试先行（不可协商）

实现代码之前先生成测试；测试必须先失败再通过（红-绿）。AI 生成的测试
需满足 `standards/testing.md` 的行为断言要求，**禁止恒真断言**、禁止仅覆盖
happy path、禁止断言实现细节而非行为。

## 四、服务边界

每个服务只能通过 `contracts/` 中声明的接口与其他服务交互：
- 禁止直连他人数据库；
- 禁止绕过契约的隐式耦合（共享内存表、私有 header 约定等）；
- 依赖方向必须符合 `architecture/service-map.md`，新增依赖需先更新地图。

## 五、记忆义务

每个 spec 的最后一个 task 固定为"更新 Project Memory"：
提交 `retro.md` 并对 `memory/now/` 提出相应修改（决策摘要、服务卡、
观察清单）。做不完这个 task 的 spec **不算完成**，不得关闭。

## 六、人类守门点

以下四处必须人审，其余环节 AI 可自主推进：
1. spec 合并（`specs/**/spec.md`）
2. plan 合并（`specs/**/plan.md`）
3. 契约变更合并（`contracts/**`）
4. `memory/now/` 变更合并

coding agent 发起的 PR 必须由**人类** approve，发起人不可自批。

---

## 修订记录

| 版本 | 日期 | 变更摘要 | 关联 ADR/PR |
|------|------|----------|-------------|
| 1.0.0 | 2026-07-12 | 初版：六条原则奠基 | — |
