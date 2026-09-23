---
name: speckit-tasks
description: "基于设计工件生成可执行、按依赖排序的 tasks.md（Spec Kit /speckit.tasks 命令薄封装）。Use when: 用户调用 /speckit-tasks 或要求把 plan 拆成任务清单。"
argument-hint: "[options]"
---

# /speckit-tasks（Spec Kit `/speckit.tasks` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.tasks.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.tasks.agent.md` 的完整指令执行。

命令映射与背景见 `adapters/spec-kit/README.md`。
