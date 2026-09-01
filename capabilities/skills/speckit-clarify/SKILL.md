---
name: speckit-clarify
description: "对当前 feature spec 做结构化追问澄清并回写答案（Spec Kit /speckit.clarify 命令薄封装）。Use when: 用户调用 /speckit-clarify 或要求澄清 spec 歧义。"
argument-hint: "[focus areas]"
---

# /speckit-clarify（Spec Kit `/speckit.clarify` 的薄封装）

本 skill 是 Spec Kit 命令的 Devin 适配层。权威提示词在
`.github/agents/speckit.clarify.agent.md`（由 `specify init` 生成，
**不要**把内容复制到本文件，避免漂移）。

## 执行方式

1. 用户调用时附带的文本即 `$ARGUMENTS`，直接作为输入使用。
2. 读取并**严格遵循** `.github/agents/speckit.clarify.agent.md` 的完整指令执行。
3. 回写 spec 后提示 `specs/**` 属守门点需人审。

命令映射与背景见 `adapters/spec-kit/README.md`。
