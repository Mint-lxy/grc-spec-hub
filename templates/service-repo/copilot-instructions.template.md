# {{SERVICE_NAME}} — Copilot 指令

> 由 hub `templates/service-repo/` 实例化。占位 `{{...}}` 在孵化时替换。
> 通用规则见根 `AGENTS.md`（本文件只补充 Copilot/VS Code 特定事项，内容不重复）。

## 必读

开始任何任务前，先按根 `AGENTS.md` 的顺序读 hub（`../{{HUB_DIR}}/`）的
宪法、本服务记忆卡、相关契约与 service-map。hub 不可达时停下来提示用户运行
`../{{HUB_DIR}}/scripts/link-hub.ps1`。

## VS Code 工作区

用仓库根的 `*.code-workspace` 打开（多根：本仓库 + hub），hub 的 skills
（`/contract-change`、`/cross-service-debug` 等）即可直接调用。

## 提交与 PR

- 祈使句提交，引用 hub 的 `specs/NNN-<slug>`。
- 你（coding agent）的 PR 必须由**人类** approve，发起人不可自批。

## 服务内部设计文档

hub spec 覆盖需求与跨服务方案，服务内部技术设计在 `docs/design/` 维护，
服务内部架构决策在 `docs/adr/` 记录。跨服务决策放 hub `architecture/adr/`。
