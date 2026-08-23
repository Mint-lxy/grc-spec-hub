---
name: speckit-analyze
description: "对 spec.md/plan.md/tasks.md 做非破坏性跨文档一致性与质量分析（Spec Kit /speckit.analyze 命令薄封装）。Use when: 用户调用 /speckit-analyze 或要求检查工件间一致性。"
---

# /speckit-analyze（Spec Kit `/speckit.analyze` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.analyze.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.analyze.agent.md` 的完整指令执行。
3. 本命令为只读分析：输出报告即可，不自动修改任何工件。

命令映射与背景见 `adapters/spec-kit/README.md`。
