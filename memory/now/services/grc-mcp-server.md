<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-mcp-server 状态卡（更新于 2026-W35）

## 职责与边界
平台原生 MCP 工具集：mcp-m365-server（SharePoint/OneDrive）、mcp-conf-server（Confluence）、mcp-dp-server（数据平台 ADF/Databricks）、mcp-web-server（Web 抓取）。不做对话编排（→ grc-agent-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：无（被 grc-agent-service 通过 MCP 协议调用）
- 消费契约：无

## 近期重要变化（最近 4 周）
- W35: 仓库转 monorepo 布局——mcp-conf / sharepoint / oss 多 server 同仓（`a2b6ff5`）；confluence mcp design（`7dfd107`）
- W34: Confluence MCP（mcp-conf-server）的 design 与 plan 文档上传（commit `21ffb1c`，08-21）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 分支命名漂移：活跃开发在 `feature/release-260831`（带连字符），旧 `feature/release260831` 未删除，待统一清理
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI（monorepo，4 个独立部署的子模块）
- 子模块：mcp-m365-server, mcp-conf-server, mcp-dp-server, mcp-web-server
<!-- /人工区块 -->
