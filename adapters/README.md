# adapters/ — 框架适配层

hub 的 SOP（[`sop/`](../sop/README.md)）与事实层是**框架无关**的。
本目录回答唯一问题：**"用某个具体 AI coding 框架时，怎么接上 hub？"**

## 铁律

1. **适配器只做指针与命令映射，不放事实**。spec/契约/记忆/标准/skill 的唯一副本
   都在事实层；适配器里出现第二份内容即 bug。
2. **换框架 = 换适配器**。SOP 阶段文件（sop/phases/）永不出现框架专属命令。
3. **新适配器的验收标准**：跑完 [`sop/phases/04-feature-loop.md`](../sop/phases/04-feature-loop.md)
   一整圈，产出物满足 [`sop/artifacts.md`](../sop/artifacts.md)。

## 已支持的框架

| 适配器 | 状态 | 说明 |
|--------|------|------|
| [spec-kit/](spec-kit/README.md) | ✅ 已接入 | GitHub Spec Kit（`.specify/` + speckit 命令），spec 工作流引擎 |
| [claude/](claude/README.md) | ✅ 已接入 | Claude Code（根 `CLAUDE.md` + `.claude/`） |
| [copilot/](copilot/README.md) | ✅ 已接入 | GitHub Copilot / VS Code（`.github/copilot-instructions.md` + 工作区设置） |
| openspec/ | ⬜ 未接入 | 需要时按上述验收标准新建 |

## 共享的能力资产（所有适配器都指向同一处）

- **skills**：[`capabilities/skills/`](../capabilities/README.md)，遵循
  [Agent Skills](https://agentskills.io) 开放约定（`<name>/SKILL.md`），
  Claude Code / Copilot 原生可发现，其它工具指向该目录即可。
- **prompts**：[`capabilities/prompts/`](../capabilities/prompts)，纯 markdown，
  任何 agent 读了就能执行。
- **中立入口**：仓库根的 [`AGENTS.md`](../AGENTS.md)——多数 agent 工具
  （Claude Code / Copilot / Cursor / Codex 等）都会自动读取的开放约定。

## 服务仓库侧的接入

服务仓库不复制 hub 内容，而是**同级目录 clone + link**（pull 模型）：
见 [`scripts/README.md`](../scripts/README.md) 与
[`templates/service-repo/`](../templates/service-repo/README.md)。
