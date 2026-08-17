<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-mgmt-service 状态卡（更新于 2026-W33）

## 职责与边界
管理服务：资产目录（CRUD/状态机/Marketplace）、订阅引擎（审批链/状态机）、资产创建与质量门控、发布链路（版本/下架/重新上架）、护栏模板管理、密钥库（PAT/个人凭据）、管理后台（治理中心/推荐位/角色映射/模型设置/平台资源注册表）、通知。不做认证（→ grc-auth-service）、不做对话（→ grc-agent-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-mgmt-service.yaml, contracts/events/eval-task.asyncapi.yaml, contracts/events/notification.asyncapi.yaml
- 消费契约：contracts/events/eval-result.asyncapi.yaml

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Spring Boot（多模块：mgmt-service-api + mgmt-service-svc）
<!-- /人工区块 -->
