<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-mgmt-service 状态卡（更新于 2026-W35）

## 职责与边界
管理服务：资产目录（CRUD/状态机/Marketplace）、订阅引擎（审批链/状态机）、资产创建与质量门控、发布链路（版本/下架/重新上架）、护栏模板管理、密钥库（PAT/个人凭据）、管理后台（治理中心/推荐位/角色映射/模型设置/平台资源注册表）、通知。不做认证（→ grc-auth-service）、不做对话（→ grc-agent-service）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-mgmt-service.yaml, contracts/events/eval-task.asyncapi.yaml, contracts/events/notification.asyncapi.yaml
- 消费契约：contracts/events/eval-result.asyncapi.yaml

## 近期重要变化（最近 4 周）
- W37: spec 015 集成 release `7fdc5a3` 与 AKS runtime，修正 `KE_SERVER_URL`，
  发布 digest `e3c59f02...`。知识库列表、Overview 和真实上传/文档创建/构建链通过；
  `KnowledgeDocumentCreateResponse.jobId` 以可选字段发布到 Hub 2.3。
- W35: Chat 子域落地（spec 001，`6b64af3`）；Marketplace 后端落地（spec 002，`43d9cc0`/`13a0b2c`）；MCP 管理面更新（`6235050`）
- W35: Vault 子域切换新内部 API——`InternalVaultController` 实现 `tokens/verify` + 出站凭据 resolve，对齐 hub 契约 `7c62373`（破坏性变更，版本未升 MAJOR、无消费方确认，见已知问题）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 契约-消费方断裂：vault 新端点已上线实现，但 grc-python-sdk 仍调旧端点 `resolve-model`/`report-credential-failure`，联调会断（digest 2026-W35，关联 watchlist #49 同类）
- 仓内 specs/ 目录（如 specs/004-vault-credential-management/）与 hub specs 并存，注意双事实源漂移
- feature/release260831 领先 main 25 个提交未合并
- 当前全量测试基线仍有 22 failures/32 errors；spec 015 的 19 项目标链路测试通过。
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Spring Boot（多模块：mgmt-service-api + mgmt-service-svc）
<!-- /人工区块 -->
