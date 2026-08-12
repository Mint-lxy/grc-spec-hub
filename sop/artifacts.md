# 工件规范（framework-neutral artifacts）

hub 的 spec 工件约定**归 hub 自己定义**，不属于任何框架。任何 spec coding 框架
（Spec Kit / OpenSpec / Claude Code / 手写）产出的文件都必须收敛到这套约定，
这样换框架时历史工件依然可读、门禁依然可校验。

## specs/ 目录布局

```
specs/
  000-platform/          # 平台总体 spec（固定编号 000）
  NNN-<slug>/            # 每个 feature 一个目录，NNN 三位递增
    spec.md              # WHAT/WHY —— 必需
    plan.md              # HOW —— 必需
    tasks.md             # 任务分解 —— 实现前必需
    retro.md             # 收尾复盘 —— spec 完成时必需
    contracts/           # （可选）契约草案，合并时移入根 contracts/
```

## 各工件的必备章节

### spec.md
- 背景与目标（WHY）
- 功能需求（WHAT，可验收的条目）
- 非目标 / 边界
- 未决问题（澄清后清零）

### plan.md（缺以下两章即不过 spec 门禁）
- **涉及服务** —— 列出本 spec 触及的全部服务（对照 `architecture/service-map.md`）
- **契约影响** —— 新增/修改哪些契约；无则明确写"无契约影响"
- 技术方案与取舍

### tasks.md
- 按**服务**分组；可并行任务标 `[P]`
- 最后一个任务固定为：**更新 Project Memory**（宪法第五条）

### retro.md
- 本 spec 沉淀的新规则/新事实（供 memory/now/ 采纳）
- 偏差记录：实现与 plan 不一致之处及原因

## 命名与追溯

- spec 目录号 `NNN` 全库唯一递增；提交信息与服务仓库 PR 必须引用 `specs/NNN-<slug>`。
- 工件内所有暂无法确定的信息标 `[待确认]`，进入实现前必须清零或转为 issue。

## 与框架模板的关系

- Spec Kit 的 `.specify/templates/` 已定制为满足本规范（plan 模板含两章）。
- 接入其它框架时，适配器必须保证产出物满足本文件——这是适配器的验收标准之一。
