# 适配器：GitHub Copilot（VS Code）

## 在 hub 仓库里用 Copilot

已就位的落点：

| 位置 | 内容 |
|------|------|
| `.github/copilot-instructions.md` | hub 仓库的 agent 指令 |
| `.vscode/settings.json` | `chat.agentSkillsLocations` 指向 `capabilities/skills`（skills 以 `/名称` 调用） |
| `.github/prompts/speckit.*.prompt.md` | Spec Kit 斜杠命令（见 [spec-kit 适配器](../spec-kit/README.md)） |

## 在服务仓库里用 Copilot

服务仓库由 [`templates/service-repo/`](../../templates/service-repo/README.md) 实例化，
自带 `.github/copilot-instructions.md`。推荐用**多根工作区**同时打开服务仓库与 hub：

```jsonc
// svc-order.code-workspace（模板已含）
{
  "folders": [{ "path": "." }, { "path": "../grc-spec-hub" }],
  "settings": {
    "chat.agentSkillsLocations": { "../grc-spec-hub/capabilities/skills": true }
  }
}
```

这样 Copilot agent 既能读到服务代码，又能直接读 hub 事实源并调用 hub skills。
在服务仓库运行一次 hub 的 [`scripts/link-hub`](../../scripts/README.md) 可自动生成/校验以上配置。

## 可选增强（不属于 SOP 必经路径）

- `/speckit.taskstoissues` + GitHub Copilot coding agent：把 tasks.md 分发为服务仓库
  issue 并指派云端 agent。依赖 GitHub SaaS 能力，团队具备条件时自行启用。
