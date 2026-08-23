---
name: speckit-taskstoissues
description: "把 tasks.md 的任务转换为按依赖排序的 GitHub issues（Spec Kit /speckit.taskstoissues 命令薄封装，依赖 gh CLI，非必经步骤）。Use when: 用户调用 /speckit-taskstoissues 或要求把任务分发为 issue。"
---

# /speckit-taskstoissues（Spec Kit `/speckit.taskstoissues` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.taskstoissues.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.taskstoissues.agent.md` 的完整指令执行。
3. 依赖 `gh` CLI 且为纯本地触发、非必经步骤；创建 issue 前先向用户确认目标仓库与清单。

命令映射与背景见 `adapters/spec-kit/README.md`。
