# sop/ — 标准作业流程（框架无关层）

本目录是 hub 的**流程事实源**：用与任何 spec coding 框架无关的语言定义
"一个平台项目从启动到常态运营"的完整 SOP。

- **这里只写"做什么、产出什么、判据是什么"**（阶段 → 工件 → 出口判据 → 守门点）。
- **"用什么命令做"由适配层回答**：[`adapters/`](../adapters/README.md) 把每个阶段映射到
  Spec Kit / Claude Code / Copilot 等具体框架的命令。换框架只换适配器，SOP 不变。
- 所有阶段产出的工件一律落在 hub 的事实层（`specs/` `contracts/` `architecture/` `memory/`），
  格式遵守 [`artifacts.md`](artifacts.md)。

## 阶段状态机

```
阶段0 绑定项目 ─► 阶段1 奠基 ─► 阶段2 声明服务清单 ─► 阶段3 批量孵化
                                                          │
                              ┌───────────────────────────┘
                              ▼
                    阶段4 功能循环（每个 feature 反复走） ─► 阶段5 常态运营（并行持续）
```

| 阶段 | 文件 | 核心产出 | 出口判据（摘要） |
|------|------|----------|------------------|
| 0 绑定项目 | [phases/00-bind-project.md](phases/00-bind-project.md) | `hub.config.yaml` 落实、git 基线 | 项目锚定，守门点路径已受人审保护 |
| 1 奠基 | [phases/01-foundation.md](phases/01-foundation.md) | 宪法、`specs/000-platform`、横切规范、初始记忆 | `[待确认]` 清零 |
| 2 声明服务清单 | [phases/02-declare-services.md](phases/02-declare-services.md) | `services.manifest.yaml` | 覆盖全部服务，依赖单向无环 |
| 3 批量孵化 | [phases/03-onboard-services.md](phases/03-onboard-services.md) | service-map、记忆卡、各服务仓库+hub 接入 | 每个服务仓库能读到 hub 上下文 |
| 4 功能循环 | [phases/04-feature-loop.md](phases/04-feature-loop.md) | spec/plan/tasks/实现/retro | 门禁绿 + 人审过 + memory 已更新 |
| 5 常态运营 | [phases/05-operations.md](phases/05-operations.md) | 周记忆摘要、契约演进、季度归档 | `memory/now/` 精简且新鲜 |

## 四个守门点（必须人审，任何框架下都不可绕过）

`specs/**` · `contracts/**` · `memory/now/**` · 宪法（`.specify/memory/constitution.md`）。

## 命令对照总表（详表见各阶段文件与 adapters/）

| SOP 动作（中立动词） | Spec Kit | Claude Code | Copilot (VS Code) |
|----------------------|----------|-------------|-------------------|
| 写/改宪法 constitution | `/speckit.constitution` | `/speckit.constitution`¹ | `/speckit.constitution` |
| 起草需求 specify | `/speckit.specify` | `/speckit.specify`¹ | `/speckit.specify` |
| 澄清 clarify | `/speckit.clarify` | `/speckit.clarify`¹ | `/speckit.clarify` |
| 出方案 plan | `/speckit.plan` | `/speckit.plan`¹ | `/speckit.plan` |
| 一致性检查 analyze | `/speckit.analyze` | `/speckit.analyze`¹ | `/speckit.analyze` |
| 分解任务 tasks | `/speckit.tasks` | `/speckit.tasks`¹ | `/speckit.tasks` |
| 实现 implement | 在服务仓库工作区实现（引入 hub 后） | 同左 | 同左 |
| 契约变更 | `/contract-change` skill | 同左 | 同左 |
| 服务孵化 | `/onboard-services` · `/new-service` skill | 同左 | 同左 |
| 跨服务排障 | `/cross-service-debug` skill | 同左 | 同左 |
| 项目答疑（带出处） | `/hub-qa` skill | 同左 | 同左 |
| 记忆提炼/收尾 | `capabilities/prompts/` 下 memory-digest · spec-retro | 同左 | 同左 |

¹ Claude Code 的 speckit 命令由 `specify init --ai claude` 生成到 `.claude/commands/`，
见 [`adapters/claude/README.md`](../adapters/claude/README.md)。
skills 是各框架共享的（Agent Skills 开放约定），prompts 是纯 markdown，任何 agent 都可直接执行。

## 修改本目录的规则

- SOP 变更 = 流程变更，走 PR 人审；禁止写入任何框架专属命令（那属于 adapters/）。
- 每个阶段文件必须保持四段结构：**输入 / 步骤 / 产出 / 出口判据**。
