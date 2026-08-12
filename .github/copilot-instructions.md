# GRC spec Hub — Copilot 指令

本文件是 **hub 仓库自身**的 Copilot 指令。通用 agent 规则的唯一事实源在根
[`AGENTS.md`](../AGENTS.md)——**先读它**；本文件只补充 Copilot 特定事项，内容不重复。

## Copilot / VS Code 特定

- skills 通过工作区设置 `chat.agentSkillsLocations`（`.vscode/settings.json` 已预置）
  发现，`/名称` 调用；Spec Kit 命令是 `.github/prompts/speckit.*`（`/speckit.*` 调用）。
- 接入细节见 `adapters/copilot/README.md`。

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

