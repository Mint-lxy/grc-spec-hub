# MCP 登记（Model Context Protocol）

本项目 agent 使用的 MCP server 清单。新增前评估权限最小化与安全边界。

| MCP | 用途 | 状态 | 备注 |
|-----|------|------|------|
| GitHub | 读写 issue/PR、仓库操作 | `[可选]` | 仅在用 GitHub 协作时接入；最小 scope |
| 监控（如 Grafana/Datadog） | 联调时拉取指标/日志 | `[待接入]` | 供 cross-service-debug 用 |
| 工单（如 Jira） | 需求/缺陷同步 | `[待评估]` | |

## 配置约定
- 机密不进仓库，走本地密钥管理/环境变量。
- 每个 MCP 遵循最小权限；只授予所需 scope。
