<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-api-gateway 状态卡（更新于 2026-W33）

## 职责与边界
统一 API 网关：路由、限流、鉴权转发、护栏检测代理、凭据解析、审计记录、流式输出缓冲与回放。不做业务逻辑（→ 各后端服务）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-api-gateway.yaml
- 消费契约：grc-auth-service、grc-mgmt-service、grc-agent-service、grc-evaluation-service、grc-knowledge-engine

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Spring Boot
- 远程仓库名为 grc-api-gateway，本地目录已重命名为 grc-api-gateway 以对齐 manifest
<!-- /人工区块 -->
