# Spec 看板（specs/）

全平台**唯一的需求事实源**。任何代码变更都必须能追溯到这里的一个 spec（宪法第一条）。

## 目录约定

工件规范的唯一事实源是 [`sop/artifacts.md`](../sop/artifacts.md)（框架无关）：

- `000-platform/` — 平台级总体 spec：愿景、服务划分依据、里程碑。它是所有
  feature spec 的上位约束。
- `NNN-<feature-slug>/` — 每个 feature 一个目录，编号自增：
  - `spec.md` — WHAT/WHY：用户故事、验收标准
  - `plan.md` — HOW：技术方案（必须含"涉及服务"与"契约影响"两章）
  - `tasks.md` — 任务分解（标注目标服务与 `[P]` 并行标记）
  - `contracts/` — 本 feature 引入/变更的契约草案
  - `retro.md` — 完成后的一页复盘（喂给 memory）

## 一个 feature 的生命周期

中立动词 → 具体命令的对照见 [`sop/README.md`](../sop/README.md)；下例为 Spec Kit 写法：

```
specify   -> spec.md                     ── 人审合并
clarify   -> 回写 spec.md 澄清项
plan      -> plan.md + contracts/ 草案    ── 人审合并
analyze   -> 跨文档一致性检查（只读）
tasks     -> tasks.md（按服务分组，[P] 并行）
[各服务并行实现] -> 服务仓库 + hub 同级工作区，本地门禁 + 人审
[集成验证]        -> 契约一致性 + integration-check
[收尾 task]        -> spec-retro 生成 retro.md，更新 memory/now/  ── 人审合并
```

新建 feature 目录时，从 `.specify/templates/` 复制模板作为起点
（或用你所选框架的模板，但产出物必须满足 `sop/artifacts.md`）。
