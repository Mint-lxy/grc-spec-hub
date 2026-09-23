# 阶段 4 · 功能实现循环（每个 feature 反复走）

从需求进入到 memory 更新的完整节拍。中立动词 → 具体命令的映射见
[`sop/README.md`](../README.md) 对照表与 [`adapters/`](../../adapters/README.md)。

## 输入
- 一个新需求；阶段 3 已完成（相关服务已孵化）。

## 步骤

### 在 hub（spec 侧）
1. **specify**：起草 `specs/NNN-<slug>/spec.md`（WHAT/WHY）→ **人审合并**。
2. **clarify**：追问边界与歧义，回写 spec。
3. **plan**：产出 `plan.md`，必含「涉及服务」「契约影响」两章 → **人审合并**。
4. **契约先行**（若有契约影响）：走 [`/contract-change`](../../capabilities/skills/contract-change/SKILL.md)
   ——草案、破坏性判定、消费者确认、合并（守门点）。代码只引用已合并契约。
5. **analyze**：跨文档一致性检查，清零 CRITICAL。
6. **tasks**：产出 `tasks.md`（按服务分组、`[P]` 标并行、末尾固定"更新 Project Memory"）。

### 在各服务仓库（实现侧，可并行）
7. 打开"服务仓库 + hub 同级目录"工作区；**先拉新 hub**（`git -C ../<hub> pull`），
   再按服务仓库 `AGENTS.md` 指引读上下文：宪法 → 本服务记忆卡 → 相关契约 → service-map。
8. **先写测试**（先红），再实现（转绿）；禁止恒真断言（[testing 标准](../../standards/testing.md)）。
9. 提 PR：跑本地门禁（lint / 单测 / 契约检查，见 [`gates/GATES.md`](../../gates/GATES.md)）
   → **人审**（发起人不可自批）→ 合并。PR 必须引用 `specs/NNN-<slug>`。

### 回到 hub（收尾）
10. **集成验证**：跨服务场景用 [`integration-check`](../../capabilities/prompts/integration-check.prompt.md)
    沿依赖链核对契约一致性。
11. **retro + 记忆**：用 [`spec-retro`](../../capabilities/prompts/spec-retro.prompt.md) 生成
    `retro.md`，同一 PR 更新 `memory/now/`（decisions / 服务卡 / watchlist / state）→ **人审合并**。

## 产出
- spec/plan/tasks/retro 四工件；各服务实现 PR；memory/now 更新。

## 出口判据（缺一不可，否则该 spec 不算完成）
- [ ] 本地门禁全绿、人审通过
- [ ] 契约影响已按 POLICY 处理（消费者确认齐全）
- [ ] retro.md 与 memory/now 更新已合并
