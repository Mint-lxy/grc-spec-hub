# 阶段 1 · 奠基（第 0 周会议，1–3 天）

产出项目"不可协商的事实"：宪法、平台总体 spec、横切规范、初始记忆。

## 输入
- 阶段 0 完成；核心团队到场（这是最重要的一次会议）。

## 步骤
1. **共写宪法**（≤ 2 页）：编辑 [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md)。
   可用框架辅助生成后人审（命令对照见 [`sop/README.md`](../README.md)）。
2. **写平台总体 spec**：[`specs/000-platform/spec.md`](../../specs/000-platform/spec.md)
   （愿景、里程碑、服务划分依据）与 `plan.md`（平台级技术选型）。
3. **落实横切规范**：[`architecture/cross-cutting/`](../../architecture/cross-cutting)
   （auth / observability / error-codes）。
4. **初始化记忆**：把 [`memory/now/state.md`](../../memory/now/state.md) 改成一句真话
   （如"项目启动，M1 目标是 X"）。

## 产出
- 真实宪法、000-platform spec+plan、横切三件套、初始 state.md。

## 出口判据
- [ ] 宪法与 000-platform 的 `[待确认]` 清零，均经人审合并
- [ ] 横切三件套定稿
- [ ] `memory/now/state.md` 有真实内容
