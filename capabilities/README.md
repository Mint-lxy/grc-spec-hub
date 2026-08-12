# capabilities/ — 能力资产（唯一家）

可复用的 AI 能力清单。这里是 skills/prompts/mcp 的**权威副本**，与具体 AI 工具解耦；
各工具通过 [`adapters/`](../adapters/README.md) 的指针指向本目录，而非搬运副本。

- **skills（放在 [`skills/`](skills)，`/名称` 调用，遵循 [Agent Skills](https://agentskills.io) 约定）**
  - [`/onboard-services`](skills/onboard-services/SKILL.md) · [`/new-service`](skills/new-service/SKILL.md) · [`/contract-change`](skills/contract-change/SKILL.md) · [`/cross-service-debug`](skills/cross-service-debug/SKILL.md) · [`/hub-qa`](skills/hub-qa/SKILL.md)
  - 发现方式：VS Code/Copilot 用 `chat.agentSkillsLocations`（本仓库 [`.vscode/settings.json`](../.vscode/settings.json) 已预置）；
    Claude Code 用 `.claude/skills` 链接（`scripts/link-hub` 生成）；其它工具见 adapters/。
- `prompts/` — 提示词权威副本（纯 markdown，任何 agent 读了就能执行）
  - `memory-digest` · `contract-review` · `spec-retro` · `integration-check`
- `mcp/registry.md` — 本项目使用的 MCP server 登记
