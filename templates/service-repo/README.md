# templates/service-repo — 服务仓库脚手架

用 `/new-service` 或 `/onboard-services` skill 孵化服务时实例化本目录。

映射：
| 模板 | 目标路径（服务仓库） |
|------|----------------------|
| `AGENTS.template.md` | `AGENTS.md`（任意 agent 的统一入口） |
| `CLAUDE.template.md` | `CLAUDE.md`（Claude Code 入口，指向 AGENTS.md） |
| `copilot-instructions.template.md` | `.github/copilot-instructions.md` |
| `instructions/*.instructions.md` | `.github/instructions/` |

占位符（孵化时替换）：
`{{SERVICE_NAME}}`、`{{HUB_REPO}}`、`{{HUB_DIR}}`（hub 的目录名，通常 `grc-spec-hub`）、
`{{BUILD_CMD}}`、`{{TEST_CMD}}`。

实例化后，在服务仓库根目录运行 hub 的 [`scripts/link-hub`](../../scripts/README.md)
完成接线（skills 链接 + 多根工作区 + 校验）。服务仓库**不保存 hub 内容副本**：
上下文一律沿 `../{{HUB_DIR}}/` 相对路径直接读 hub（pull 模型）。
