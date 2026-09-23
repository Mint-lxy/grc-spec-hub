# GRC spec Hub — Copilot 指令

本文件是 **hub 仓库自身**的 Copilot 指令。通用 agent 规则的唯一事实源在根
[`AGENTS.md`](../AGENTS.md)——**先读它**；本文件把最关键的约束内联，减少间接跳转。

## 强制工作流（每次任务前回忆）

1. **改 spec**（`specs/**`）→ 必须遵守 `sop/artifacts.md` 工件规范；plan 必须含「涉及服务」「契约影响」两章。
2. **改架构**（`architecture/**`）→ 跨服务决策**先写 ADR**（`architecture/adr/NNN-xxx.md`），再更新横切/service-map；ADR 合并后必须同步更新 `memory/now/decisions.md`。
3. **改契约**（`contracts/**`）→ 先读 `contracts/POLICY.md`；破坏性变更必须列消费方并逐一确认。
4. **改记忆**（`memory/**`）→ 只写"自动区块"，永不触碰"人工区块"；每条事实附来源。
5. **任何改动完成后**→ 检查是否需要同步更新 `memory/now/state.md`（项目现状）。

## 不可违反的规则

- **不编造**：hub 里没有记录的事实，标 `[待确认]`，不许推测填充。
- **不自行合并守门点**：`specs/**`、`contracts/**`、`memory/now/**` 必须人审。
- **错误码必须注册**：新增接口错误必须在 `architecture/cross-cutting/error-codes.md` 注册编码。
- **服务前缀对照 ADR-001**：涉及服务归属问题参照 `architecture/adr/001-service-split.md` 的 D2 模块表与 D12 映射表。

## 操作检查清单（完成任务后逐条核对）

- [ ] 新增/修改的 ADR → `memory/now/decisions.md` 已同步？
- [ ] 新增/修改的 spec → `memory/now/state.md` 的「进行中 specs」已更新？
- [ ] 新增的服务/模块 → `architecture/services.manifest.yaml` 和 `service-map.md` 已同步？
- [ ] 新增的错误码 → `cross-cutting/error-codes.md` 已注册？
- [ ] 涉及 PRD 章节 → spec 头部标注了 PRD 来源版本号？

## Copilot / VS Code 特定

- skills 通过工作区设置 `chat.agentSkillsLocations`（`.vscode/settings.json` 已预置）
  发现，`/名称` 调用；Spec Kit 命令是 `.github/prompts/speckit.*`（`/speckit.*` 调用）。
- 接入细节见 `adapters/copilot/README.md`。

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

