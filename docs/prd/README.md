# PRD（产品需求文档）

本目录存放**业务需求源文件**——即 spec 的上游输入。

## 定位

- PRD 是 spec 工件的**输入源**，不是 hub 管理的工件类型。
- Feature spec（`specs/NNN-<slug>/spec.md`）从 PRD 中萃取可验收条目；
  plan 从 PRD 的技术决策章节获取约束。
- Agent 起草 spec 时引用本目录的 PRD 作为上下文。

## 使用方式

```
# 在 hub 工作区对 agent 说：
读 docs/prd/GRC-AI-Foundation-Platform-PRD-v1.2.md 的 §X 章节，
基于其中的功能 Y 起草 specs/NNN-<slug>/spec.md
```

## 文件清单

| 文件 | 版本 | 说明 |
|------|------|------|
| GRC-AI-Foundation-Platform-PRD-v1.2.md | v1.2 | 平台总体 PRD（当前基线，与用户旅程 v1.2 差异收敛版），152 条用户故事，通知 12 类，覆盖 P0+P1 |
| GRC-AI-Foundation-Platform-PRD-v1.0.md | v1.0 | 历史版本，已被 v1.2 取代；specs/000–009 的拆解基线 |
| GRC-AI-Foundation-Platform-PRD-v0.9.md | v0.9 | 历史版本，已被 v1.0 取代 |

用户旅程源文件见 [`../user_journey/`](../user_journey/)（当前基线 v1.2）。
