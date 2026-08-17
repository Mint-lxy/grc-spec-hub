---
name: memory-sync
description: 对齐 hub 记忆层（state/watchlist/decisions）与事实源（ADR/specs/service-map/manifest），发现漂移并生成修正建议。Use when: 定期记忆对齐、怀疑 memory 过期、ADR 或 spec 变更后需要同步 now/ 文件、watchlist 需要刷新。
metadata:
  origin: hub
---

# Memory Sync（记忆对齐）

定期或按需检查 `memory/now/` 与 hub 内各事实源的一致性，发现漂移并输出修正内容。

## 触发时机

- ADR 合并或状态变更后
- Spec 的 §4 未决问题新增/关闭后
- Service-map / manifest 依赖变更后
- 每周 digest 前的预校验
- 用户主动调用 `/memory-sync`

## 铁律

1. **只写自动区块**——`<!-- 人工区块 -->` 永不触碰。
2. **每条变更附出处**——指向 ADR/spec/service-map 的具体行。
3. **不编造**——hub 里没有记录的事实标 `[待确认]`。
4. **精简优先**——state ≤ 2 页、watchlist 按优先级裁剪，超限降温到 digests/。

## 对齐检查清单

按顺序执行以下检查，每项输出「✓ 一致」或「⚠ 漂移 → 修正建议」：

### 1. decisions.md ↔ ADR 目录

- 扫描 `architecture/adr/*.md` 中所有 ADR 的标题、状态、日期
- 与 `memory/now/decisions.md` 表格逐行对比
- 漂移情况：ADR 新增/状态变更/被 supersede 但 decisions.md 未更新

### 2. state.md ↔ 多源交叉

| state.md 段落 | 事实源 | 检查点 |
|---------------|--------|--------|
| 所处阶段 | specs 状态分布 | Draft/In-Progress/Done 占比是否匹配描述 |
| 本里程碑目标 | spec 000 §2 里程碑表 | 目标与关键结果是否一致 |
| 进行中 specs | specs/*/spec.md 头部状态 | 列表是否完整、状态是否准确 |
| 当前风险 | ADR 待确认项数 + spec §4 未决数 | 数量与描述是否匹配 |
| 近期重要变化 | Git log / 已知变更 | 是否遗漏重大变更（4 周窗口） |

### 3. watchlist.md ↔ ADR 待确认 + spec 未决

- 扫描 `architecture/adr/*.md` 中 `- [ ]` 开头的待确认项
- 扫描 `specs/*/spec.md` 中 §4 的 `- [ ]` 未决问题
- 与 watchlist 条目对比：
  - 新增未登记 → 建议添加
  - 已关闭（`- [x]`）但 watchlist 仍为 open → 建议关闭
  - watchlist 有但源文件已删除 → 建议移除

### 4. service-map ↔ manifest 一致性

- 对比 `architecture/service-map.md` 各服务段与 `architecture/services.manifest.yaml`
- 检查：provides / consumes / depends-on 三字段是否一致
- 检查 mermaid 图边是否与 depends-on 字段匹配

### 5. state.md 更新周次

- 检查 state.md 头部 `更新于` 周次是否为当前周（或上周）
- 超过 2 周未更新 → 警告

## 输出格式

```markdown
## Memory Sync Report — {日期}

### ✓ 一致项
- decisions.md ↔ ADR 目录：一致
- service-map ↔ manifest：一致

### ⚠ 漂移项

#### state.md — 当前风险
- **现状**：描述为"5 项架构待确认"
- **事实**：ADR-001 已有 12 项
- **修正**：将"5 项"改为"12 项"，补列新增 7 项摘要
- **出处**：architecture/adr/001-service-split.md L267-L278

#### watchlist.md — 缺失条目
- **新增建议**：#N — {项目名} | {类型} | {关联} | open
- **出处**：{源文件路径}

### 修正动作
1. [ ] 更新 state.md（自动区块）
2. [ ] 更新 watchlist.md
3. [ ] 更新 decisions.md（如有）
```

## 执行步骤

1. **采集事实源**：读取 ADR 目录、所有 spec §4、service-map、manifest。
2. **逐项对比**：按检查清单 §1–§5 执行。
3. **生成报告**：按输出格式列出一致项与漂移项。
4. **提出修正**：对每个漂移项给出具体修正内容（精确到 oldString/newString）。
5. **执行修正**（用户确认后）：更新 `memory/now/` 相关文件。
6. **降温检查**：state 超 2 页 → 将最旧的"近期重要变化"条目移入 `memory/digests/`。

## 不做的事

- 不触碰人工区块
- 不合并守门文件（state/watchlist 修改后仍需人审）
- 不创建新的 memory 文件（只更新已有文件）
- 不修改 specs / ADR / contracts 源文件（只读采集）

## 与其他 skill/流程的关系

| 相关 | 关系 |
|------|------|
| memory-digest（周 digest） | memory-sync 是 digest 的"预检"——先对齐再提炼 |
| architecture-decision-records | ADR 变更后触发 sync 检查 decisions.md |
| prd-sync | PRD 变更后触发 sync 检查 state/specs 一致性 |
| hub-qa 缺口回灌 | qa 发现缺口时建议调用 sync 补录 watchlist |
