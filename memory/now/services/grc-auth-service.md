<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-auth-service 状态卡（更新于 2026-W33）

## 职责与边界
统一身份认证：Alice SSO 对接、Token 颁发与校验、PAT 管理。不做业务授权（→ grc-mgmt-service RBAC 模块）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-auth-service.yaml
- 消费契约：无

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Spring Boot
<!-- /人工区块 -->
