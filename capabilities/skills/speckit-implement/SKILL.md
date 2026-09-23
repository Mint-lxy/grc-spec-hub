---
name: speckit-implement
description: "按 tasks.md 执行实现计划（Spec Kit /speckit.implement 命令薄封装）。Use when: 用户调用 /speckit-implement 或要求开始按任务清单实现。"
---

# /speckit-implement（Spec Kit `/speckit.implement` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.implement.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.implement.agent.md` 的完整指令执行。
3. hub 仓库不放业务代码：实现通常应在对应服务仓库工作区进行（见 `adapters/spec-kit/README.md` 的命令映射备注）；若任务触及 hub 守门点（`specs/**`、`contracts/**`、`memory/now/**`、宪法），完成后提示需人审。

命令映射与背景见 `adapters/spec-kit/README.md`。
