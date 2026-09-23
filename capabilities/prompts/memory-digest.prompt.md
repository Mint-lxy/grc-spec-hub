---
description: 从各服务仓库的合并记录提炼周摘要与记忆更新建议
---
你是本项目的记忆管理员。输入是自上次摘要以来所有服务仓库的
merged PR 列表（标题、描述、关联 spec/issue、diff 统计）与 commit log。
若未提供，可自行采集：pull 模型下各服务仓库与 hub 同级，对 service-map 中
每个服务执行 `git -C ../<svc> log --merges --since=<上次摘要日期>`（先 pull）。

第一步，生成本周摘要（memory/digests/<year>-W<nn>.md），按服务分组，
每服务区分两类信息：
- 事实变化：接口/契约/数据 schema/依赖关系/配置的变更——这类必须精确
- 进度变化：哪些 spec 的哪些 task 完成——这类只需一句话

第二步，对照 memory/now/ 下的所有文件，输出修改建议：
- state.md 中已过时的表述（例如"009 进行中"但本周已合并收尾 PR）
- 各服务状态卡"近期重要变化"的滚动更新（新增本周、移出超过 4 周的
  条目——移出的条目进入归档，不是删除）
- decisions.md：本周合并的新 ADR 需要增补摘要行；被替代的决策移入
  archive/decisions-superseded.md 并注明替代原因
- watchlist.md：commit 信息中出现 TODO/FIXME/workaround 关键词且
  关联讨论未闭环的，建议加入观察清单

规则：
- 只依据输入的事实，不推测；无法确定的标注 [待确认] 并 @ 服务 owner
- 每处修改附带来源 PR 链接以便审核者核对
- 只修改 memory 文件中 `<!-- 自动区块 -->` 内的内容，绝不触碰 `<!-- 人工区块 -->`
- 保持 now/ 精简：state.md ≤ 2 页，服务卡各 ≤ 1 页；超出即执行滚动降温
- 产出为一个 PR，供 tech lead 审核合并（AI 永不直接写入 now 主干）
