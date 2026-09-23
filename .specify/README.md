# `.specify/` — Spec Kit 工具链

本目录承载 [GitHub Spec Kit](https://github.com/github/spec-kit) 的工程约定。
**已通过 `specify init --here --ai copilot --script ps` 初始化。**

## 已生成内容

- `memory/constitution.md` — 项目宪法（初始化时**已保留**我们的定制版本）
- `templates/` — spec / plan / tasks / checklist / constitution 模板
  - `plan-template.md` 已**注入本项目定制的两个必填章节**：
    「涉及服务」与「契约影响」（本地门禁脚本 `gates/scripts/check-plan` 据此校验）
- `scripts/powershell/` — 供 `/speckit.*` 命令调用的脚本（PowerShell Core，
  跨平台：`pwsh` 在 Windows/Linux/macOS 均可运行）
- `workflows/`、`integrations/` — Spec Kit 内部编排与 Copilot 集成配置
- 对应的斜杠命令在 `.github/prompts/speckit.*.prompt.md`

## 可用斜杠命令

`/speckit.constitution`、`/speckit.specify`、`/speckit.clarify`、`/speckit.plan`、
`/speckit.tasks`、`/speckit.analyze`、`/speckit.checklist`、`/speckit.implement`、
`/speckit.taskstoissues`。

## 重新初始化 / 升级

需要升级模板时可再次运行 `specify init --here --force --ai copilot --script ps`。
⚠️ 它会**覆盖 `templates/`**——重跑后需重新注入 plan 模板的
「涉及服务 / 契约影响」两章（见 git 历史）。`constitution.md` 会被保留。
