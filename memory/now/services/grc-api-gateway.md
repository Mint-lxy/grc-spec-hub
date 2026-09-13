<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-api-gateway 状态卡（更新于 2026-W33）

## 职责与边界
统一 API 网关：路由、限流、鉴权转发、护栏检测代理、凭据解析、审计记录、流式输出缓冲与回放。不做业务逻辑（→ 各后端服务）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-api-gateway.yaml
- 消费契约：grc-auth-service、grc-mgmt-service、grc-agent-service、grc-evaluation-service、grc-knowledge-engine

## 近期重要变化（最近 4 周）
- W37: spec 015 集成 release `3e63ec1` 并更新 AKS：新增 Knowledge
  `/open/v1/**` 完整路径路由，ACR digest `f3330987...`；Auth/Mgmt 无 token 仍返回
  401，Gateway 旧/新 digest 回滚恢复通过。跳过 Gateway JWT 是 XAG 私网演示临时例外。
- W37: spec 014 AKS 演示运行时完成：新增 digest 固定清单，修复 production profile
  localhost 覆盖和路由数组覆盖问题；无 token 返回 401，登录与携带 token 的知识库链路通过。
  Gateway facade 契约发布为 0.2，部署工件 `06c812c`，契约提交 `db9cc26`。
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 当前镜像默认 root；后续需重建非 root 镜像。
- `/open/v1/**` 临时跳过 Gateway JWT，仅允许 XAG 私网演示；生产前必须恢复正式
  PAT/scope 鉴权（watchlist #89）。
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Spring Boot
- 远程仓库名为 grc-api-gateway，本地目录已重命名为 grc-api-gateway 以对齐 manifest
<!-- /人工区块 -->
