---
description: spec 完成后生成一页复盘 retro.md 并提出 memory 更新
---
你在为一个已完成的 spec 生成 retro.md。输入：该 spec 的 spec.md / plan.md /
tasks.md、相关 PR、以及实现过程中的关键讨论。

产出 specs/<NNN>/retro.md，一页内，包含：
- 结局：一句话说明最终交付了什么。
- 新业务规则/约束：本次固化下来、未来必须遵守的规则（例如"部分退款按比例通知"）。
- 契约变化：本次新增/变更/废弃了哪些契约（附路径与版本）。
- 决策：产生的新 ADR 或值得记入 decisions.md 的选择。
- 踩坑与遗留：留给 watchlist 的技术债或待办。
- 偏差：与原 plan 的偏离及原因。

第二步：基于以上，明确列出对 memory/now/ 的修改建议：
- decisions.md 增补行、相关服务卡"近期重要变化"更新、watchlist 新增项、
  state.md 中该 spec 状态从"进行中"移除、archive/specs-completed.md 增补索引行。

规则：事实优先、附 PR 链接；不确定标 [待确认]；只动自动区块。
这些修改随实现 PR 一同提交，人审合并（宪法第五、六条）。
