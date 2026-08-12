# 适配器：Claude Code

## 在 hub 仓库里用 Claude Code

已就位的落点：

| 位置 | 内容 |
|------|------|
| 根 [`CLAUDE.md`](../../CLAUDE.md) | 入口指令（指向 `AGENTS.md`，内容不重复） |
| `.claude/skills/` | 指向 `capabilities/skills/` 的链接（由 [`scripts/link-hub`](../../scripts/README.md) 生成，Windows 上为 junction） |
| `.claude/commands/speckit.*.md` | Spec Kit 斜杠命令（可选，`specify init --ai claude` 生成，见 [spec-kit 适配器](../spec-kit/README.md)） |

skills 链接生成后，`/contract-change`、`/new-service` 等即可在 Claude Code 中直接调用；
`capabilities/prompts/` 下的 prompt 直接让 Claude 读文件执行即可。

## 在服务仓库里用 Claude Code

服务仓库由 [`templates/service-repo/`](../../templates/service-repo/README.md) 实例化，
自带根 `CLAUDE.md`（指向 `AGENTS.md`）。hub 与服务仓库同级 clone 后，
在服务仓库运行一次 hub 的 `scripts/link-hub`，会：

1. 校验 `../grc-spec-hub` 存在且含 `hub.config.yaml`（即是一个 hub）；
2. 生成 `.claude/skills` → `../grc-spec-hub/capabilities/skills` 的链接；
3. 校验 `AGENTS.md` 中的 hub 路径可达。

之后 Claude Code 在服务仓库中即可：读 `AGENTS.md` → 沿相对路径读 hub 的
宪法/记忆卡/契约 → 调用 hub skills。

## 注意

- `.claude/skills` 链接目录已加入 `.gitignore`（各人本地生成，不入库）。
- 不要把 hub 的内容复制进 `.claude/`——适配器只做指针。
