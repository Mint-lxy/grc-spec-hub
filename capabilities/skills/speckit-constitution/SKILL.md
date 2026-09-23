---
name: speckit-constitution
description: "建立/修订项目宪法（Spec Kit /speckit.constitution 命令薄封装）。Use when: 用户调用 /speckit-constitution 或要求修订项目宪法。"
argument-hint: "[principles]"
---

# /speckit-constitution（Spec Kit `/speckit.constitution` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.constitution.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用；为空则按权威文件的交互流程进行。
2. 读取并**严格遵循** `.github/agents/speckit.constitution.agent.md` 的完整指令执行。
3. 宪法属 hub 守门点：改动完成后提示需人审，不自行合并。

命令映射与背景见 `adapters/spec-kit/README.md`。
