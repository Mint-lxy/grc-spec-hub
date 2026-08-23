---
name: speckit-plan
description: "用 plan 模板生成实现规划与设计工件（Spec Kit /speckit.plan 命令薄封装）。Use when: 用户调用 /speckit-plan 或要求为已定 spec 出技术方案。"
argument-hint: "[tech context]"
---

# /speckit-plan（Spec Kit `/speckit.plan` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.plan.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.plan.agent.md` 的完整指令执行。
3. plan 模板已定制：必须包含「涉及服务」「契约影响」两章（见 `sop/artifacts.md` 与 `.specify/templates/plan-template.md`），不得省略。

命令映射与背景见 `adapters/spec-kit/README.md`。
