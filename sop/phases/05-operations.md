# 阶段 5 · 常态运营（持续）

保持记忆新鲜、契约有序演进、SOP 自我修正。全部为**人触发的本地节拍**，不依赖 CI。

## 节拍

| 频率 | 动作 | 入口 |
|------|------|------|
| 每周一（~15 分钟） | 运行 memory-digest：采集本周各服务合并记录 → 提炼 → 记忆 PR → 人审 | [`memory-digest` prompt](../../capabilities/prompts/memory-digest.prompt.md)（在 hub 工作区对任意 agent 执行） |
| 每双周 | 检视 [`watchlist.md`](../../memory/now/watchlist.md) 与门禁豁免 | 人工 |
| 每季度 | 归档压缩：周摘要 → `memory/archive/digests/<Q>.md`；宪法回顾 | [`memory/PIPELINE.md`](../../memory/PIPELINE.md) 降温规则 |
| 事件驱动 | 契约变更走 [`/contract-change`](../../capabilities/skills/contract-change/SKILL.md)；新服务走 `/new-service` | skills |

## 健康度红线

- `memory/now/state.md` 超过 14 天未更新 → 周会追问。
- 记忆 PR 积压超过 5 个工作日 → 升级处理（记忆腐化是本体系最大单点风险）。
- `memory/now/` 超限（state > 2 页、服务卡 > 1 页）→ 立即降温，不许就地堆积。

## 出口判据（持续满足）
- [ ] now/ 精简且新鲜；每条事实有来源 PR 链接
- [ ] 契约变更零"未通知消费者"事故
- [ ] SOP 与实际执行偏差在 retro 中被记录并回改 sop/
