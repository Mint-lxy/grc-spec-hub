# `.github/prompts/`

此目录存放**可斜杠调用**的 prompt 文件（`*.prompt.md`）。

## 已安装：Spec Kit 命令

`specify init` 已生成以下命令（对应 `.github/agents/speckit.*.agent.md`）：

| 命令 | 作用 |
|------|------|
| `/speckit.constitution` | 建立/修订项目宪法 |
| `/speckit.specify` | 生成 spec（WHAT/WHY） |
| `/speckit.clarify` | 结构化追问澄清歧义 |
| `/speckit.plan` | 生成 plan（HOW，含定制的「涉及服务/契约影响」两章） |
| `/speckit.tasks` | 生成任务分解 |
| `/speckit.analyze` | 跨文档一致性检查 |
| `/speckit.checklist` | 生成质量检查单 |
| `/speckit.implement` | 执行实现 |
| `/speckit.taskstoissues` | 把任务分发为各服务仓库 issue |

## 本项目自定义 prompt

权威副本维护在 `capabilities/prompts/`（单一事实源）：
`memory-digest`、`contract-review`、`spec-retro`、`integration-check`。
若希望它们也能在 hub 内斜杠调用，可在此建同名薄封装，保持
`capabilities/prompts/` 为权威副本以避免漂移。
