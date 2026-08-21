# 适配器：GitHub Spec Kit

Spec Kit 是当前 hub 的 **spec 工作流引擎**（可替换；替换时只动本适配器与其落点文件）。

## 落点文件（Spec Kit 要求固定位置，物理上不在本目录）

| 位置 | 内容 | 归属 |
|------|------|------|
| `.specify/` | 脚本、模板、宪法存放点 | Spec Kit 工具链 |
| `.specify/templates/plan-template.md` | 已定制：强制「涉及服务」「契约影响」两章（满足 [`sop/artifacts.md`](../../sop/artifacts.md)） | **hub 定制，重装时需重新注入** |
| `.specify/memory/constitution.md` | 项目宪法（**事实层**，只是物理上放在这里） | hub |
| `.github/prompts/speckit.*.prompt.md` | Copilot 的斜杠命令 | Spec Kit 生成 |
| `.claude/commands/speckit.*.md` | Claude Code 的斜杠命令（若已生成） | Spec Kit 生成 |
| `capabilities/skills/speckit-*/SKILL.md` | Devin 等 Agent Skills 兼容工具的薄封装（kebab-case 命名，指向 `.github/agents/` 权威提示词，重装引擎后无需改动） | **hub 定制** |

## 安装 / 重装

```powershell
specify init --here --force --ai copilot --script ps   # Copilot 用户
specify init --here --force --ai claude --script ps    # Claude Code 用户（可叠加执行）
```

重装后必须检查两件事：
1. `constitution.md` 未被覆盖（Spec Kit init 会保留，但要核对）；
2. `plan-template.md` 的定制两章仍在，丢失则重新注入。

## SOP 动作 → Spec Kit 命令映射

| SOP 动作 | 命令 |
|----------|------|
| constitution | `/speckit.constitution` |
| specify | `/speckit.specify` |
| clarify | `/speckit.clarify` |
| plan | `/speckit.plan` |
| analyze | `/speckit.analyze` |
| tasks | `/speckit.tasks` |
| implement | `/speckit.implement`（或直接在服务仓库工作区实现） |
| （可选）任务分发为 GitHub issue | `/speckit.taskstoissues`——依赖 `gh` CLI，纯本地触发，非必经步骤 |

> **Devin CLI 接入**：同一批命令经 `.devin/skills/speckit-<cmd>/SKILL.md` 符号链接
> （指向 `.github/agents/speckit.<cmd>.agent.md`）接入，调用形式为 `/speckit-specify`
> 等**连字符**形式（Devin 技能名不支持点号）。

## 卸载 / 更换引擎

删除 `.specify/`、`.github/prompts/speckit.*`、`.claude/commands/speckit.*`，
把宪法移到新引擎约定的位置并更新 `hub.config.yaml` 的 `sources.constitution`。
`specs/` 下的历史工件不受影响（它们遵守的是 `sop/artifacts.md`，不是 Spec Kit 格式）。
