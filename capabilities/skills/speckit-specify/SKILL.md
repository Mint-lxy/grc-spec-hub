---
name: speckit-specify
description: "从自然语言功能描述创建/更新 feature spec（Spec Kit /speckit.specify 命令薄封装）。Use when: 用户调用 /speckit-specify 或要求起草新功能规格。"
argument-hint: "<feature description>"
---

# /speckit-specify（Spec Kit `/speckit.specify` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.specify.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`（功能描述），直接使用；不要要求用户重复，除非完全为空。
2. 读取并**严格遵循** `.github/agents/speckit.specify.agent.md` 的完整指令执行（含 Pre-Execution Checks 与 Outline）。
3. spec 还须满足 `sop/artifacts.md` 工件规范；`specs/**` 属守门点，改动完成后提示需人审。

命令映射与背景见 `adapters/spec-kit/README.md`。
