# API Landscape — 全局接口概览

> **状态**：Draft — 待团队评审
> **日期**：2026-08-22
> **关联 ADR**：[ADR-004](../../architecture/adr/004-api-design-top-down.md)
> **使用方式**：评审通过后，按 feature 拆入各 `specs/NNN/plan.md`，再沉淀为 `contracts/openapi/*.yaml`

本文档列出平台所有服务的**粗粒度 API 端点**（HTTP 方法 + 路径 + 一句话描述 + 关键出入参），
用于在编写正式 contract 之前对齐服务职责边界和端点归属。

**约定**：
- 路径前缀 `/api/v1` 由网关统一加，下表省略
- `{id}` 等为路径参数
- 「请求要点」「响应要点」仅列核心字段，非完整 schema，`?` 表示可选
- 「Spec」列标注端点主要来源的 feature spec 编号
- 标 `[内部]` 的端点仅限服务间调用，不经网关暴露
- 标 `[开放]` 的端点通过 PAT 认证对外部系统开放

---

## 1. grc-api-gateway

网关本身不提供业务 API，负责路由转发、鉴权、护栏、凭据注入、审计、流式缓冲回放。
以下为网关自身需暴露的运维/管理端点：

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/health` | 健康检查 | — | `{ status, checks[] }` | 000 |
| GET | `/ready` | 就绪检查 | — | `{ status }` | 000 |

---

## 2. grc-auth-service

> 服务契约基址为 `/auth`；网关统一追加 `/api/v1`。成功响应使用共享 `ApiResponse` 包络，核心业务字段位于 `data`；错误响应使用根级 `code/message/detail/traceId/timestamp/path` 结构。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/auth/login` | 使用账号密码登录并签发 Token | `{ username, password, clientType? }` | `{ userId, username, accessToken, refreshToken?, expiresIn }` | 001 |
| GET | `/auth/users/{userId}` | 获取用户信息 | Header: `Authorization`; Path: `userId` | `{ id, username, displayName, email, accountStatus, tenantId? }` | 001 |
| POST | `/auth/verify` | 校验 Access Token 并返回用户上下文 | `{ token }` | `{ valid, userId, roles[], tenantId?, exp }` | 001 |
| POST | `/auth/logout` | 登出并吊销当前登录态 | Header: `Authorization: Bearer <token>` | `data: null` | 001 |
| POST | `/auth/refresh` | 轮换 Refresh Token 并签发新 Token 对 | `{ refreshToken, clientId }` | `{ accessToken, refreshToken, expiresIn }` | 001 |
| GET | `/auth/oauth/authorize` | 创建 OIDC 授权请求并生成一次性 state | — | `{ url, state, expireIn: 180 }` | 003 |
| GET | `/auth/oauth/callback` | 完成 OIDC 回调登录、用户映射并签发平台 Token | `?code, state` | `{ accessToken, refreshToken?, expiresIn, userInfo, roles[], permissions[] }` | 003 |
| POST | `/auth/alice/users/sync` | `[内部]` 手动触发 Alice 用户同步 | — | `{ correlationId, triggerType, status }` | 002 |
| GET | `/auth/alice/users/sync-jobs/{correlationId}` | `[内部]` 查询 Alice 用户同步任务 | Path: `correlationId` | `{ correlationId, triggerType, status, tasks[] }` | 002 |

### 2.1 设计中但当前未落地的登录日志接口

登录日志设计文档定义了以下管理接口，但当前 auth-service 源码尚未提供对应 Controller；形成实现和契约后再转入上表的已落地端点清单。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/auth/login-log/page` | `[设计]` 分页查询登录日志 | `?pageNum, pageSize, userId?, usernameCn?, usernameEn?, sceneCd?, loginStatus?, startTime?, endTime?` | `{ records[], total }` | 001 |
| DELETE | `/auth/login-log/clean-old` | `[设计]` 清除一个月前登录日志 | — | 删除结果 | 001 |
| DELETE | `/auth/login-log/clean-all` | `[设计]` 清除全部登录日志 | — | 删除结果 | 001 |

---

## 3. grc-mgmt-service

> 当前服务接口使用 `/mgmt/{domain}` 作为服务内路由前缀；经网关暴露时仍由网关统一加 `/api/v1`。
> 服务统一返回 `ApiResponse` 包络，具体业务字段以对应 feature contract 为准。

### 3.1 Marketplace 资产（002-marketplace / 005-marketplace-redesign）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgmt/marketplace/assets` | 创建资产 | `{ type, name, description?, ... }` | `{ assetId, ... }` | 002/003 |
| GET | `/mgmt/marketplace/assets` | 查询资产列表 | `?page, pageSize, keyword?, type?, status?` | `{ records[], total }` | 002 |
| GET | `/mgmt/marketplace/assets/{assetId}` | 查询资产详情 | — | `{ assetId, name, type, owner, status, ... }` | 002 |
| PUT | `/mgmt/marketplace/assets/{assetId}` | 更新资产 | `{ name?, description?, ... }` | 更新后的资产 | 003 |
| POST | `/mgmt/marketplace/assets/{assetId}/precheck` | 执行发布前预检 | — | `{ passed, checks[], ... }` | 005 |
| POST | `/mgmt/marketplace/assets/{assetId}/publish` | 发布资产 | — | `{ assetId, status, ... }` | 004/005 |
| POST | `/mgmt/marketplace/assets/{assetId}/unpublish` | 下架资产 | — | `{ data: null }` | 004 |
| POST | `/mgmt/marketplace/assets/{assetId}/archive` | 归档资产 | — | `{ data: null }` | 004 |
| POST | `/mgmt/marketplace/assets/{assetId}/transfer-owner` | 转移资产 Owner | `{ newOwnerId }` | `{ assetId, ownerId, ... }` | 005 |
| POST | `/mgmt/marketplace/assets/yaml-preview` | 预览资产 YAML | `{ ...assetConfig }` | `{ yaml, ... }` | 003 |
| DELETE | `/mgmt/marketplace/assets/draft/{assetId}` | 删除编辑态缓存 | — | `{ data: null }` | 003 |

### 3.2 Marketplace 订阅与审批（002-marketplace / 005-marketplace-redesign）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/mgmt/marketplace/assets/{assetId}/subscribe/page-init` | 初始化订阅提交页 | — | `{ asset, terms, approvalConfig, ... }` | 002 |
| POST | `/mgmt/marketplace/assets/{assetId}/subscribe` | 提交订阅申请 | `{ ...subscriptionRequest }` | `{ subscriptionId, status, ... }` | 002/005 |
| GET | `/mgmt/marketplace/subscriber-center/summary` | 查询订阅者中心统计 | — | `{ ...summary }` | 002 |
| GET | `/mgmt/marketplace/subscriptions` | 查询我的订阅 | `?page, pageSize, status?` | `{ records[], total }` | 002 |
| GET | `/mgmt/marketplace/subscriptions/{subscriptionId}` | 查询订阅详情 | — | `{ subscriptionId, status, approvalProgress[], ... }` | 002 |
| POST | `/mgmt/marketplace/subscriptions/{subscriptionId}/resubmit` | 驳回后重新提交订阅 | `{ ...subscriptionRequest }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgmt/marketplace/subscriptions/{subscriptionId}/cancel` | 取消订阅申请 | — | `{ data: null }` | 002 |
| GET | `/mgmt/marketplace/approval-flows/{flowId}` | 查询审批流详情 | — | `{ flowId, steps[], status, ... }` | 005 |
| GET | `/mgmt/marketplace/approval-flows/my-pending` | 查询我的待审批事项 | `?page, pageSize` | `{ records[], total }` | 005 |
| POST | `/mgmt/marketplace/approval-flows/{flowId}/steps/{stepId}/approve` | 审批通过当前步骤 | `{ comment? }` | `{ flowId, stepId, status, ... }` | 005 |
| POST | `/mgmt/marketplace/approval-flows/{flowId}/steps/{stepId}/reject` | 驳回当前审批步骤 | `{ reason }` | `{ flowId, stepId, status, ... }` | 005 |
| GET | `/mgmt/marketplace/creator-center/summary` | 查询创作者中心统计 | — | `{ ...summary }` | 005 |
| GET | `/mgmt/marketplace/creator-center/assets` | 查询创作者资产 | `?page, pageSize, status?` | `{ records[], total }` | 005 |
| GET | `/mgmt/marketplace/creator-center/pending-subscriptions` | 查询待处理订阅 | `?page, pageSize` | `{ records[], total }` | 005 |
| GET | `/mgmt/marketplace/creator-center/pending-publish-assets` | 查询待发布资产 | `?page, pageSize` | `{ records[], total }` | 005 |
| GET | `/mgmt/marketplace/creator-center/assets/{assetId}/console` | 查询创作者资产控制台 | — | `{ asset, subscriptions, publishState, ... }` | 005 |
| PUT | `/mgmt/marketplace/creator-center/assets/{assetId}/subscription-settings` | 保存订阅设置 | `{ ...subscriptionSettings }` | 更新后的订阅设置 | 005 |
| POST | `/mgmt/marketplace/creator-center/subscriptions/{subscriptionId}/decision` | 处理订阅审批决定 | `{ decision, reason? }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgmt/marketplace/creator-center/subscriptions/{subscriptionId}/revoke` | 撤回订阅处理结果 | `{ reason? }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgmt/marketplace/assets/{assetId}/publish-evaluations` | 创建发布测评 | `{ ...evaluationRequest }` | `{ evaluationId, status, ... }` | 005 |
| GET | `/mgmt/marketplace/assets/{assetId}/publish-evaluations/{evaluationId}` | 查询发布测评 | — | `{ evaluationId, status, checks[], ... }` | 005 |
| GET | `/mgmt/marketplace/tags` | 查询全部资产标签 | — | `{ items[] }` | 002 |

### 3.3 知识库门面（005-knowledge）

知识库接口由 mgmt-service 对 knowledge-engine 提供前端门面；Stage 运行与任务查询中标 `[内部]` 的接口仅供平台服务调用。**知识目录由 mgmt-service 直接实现并持有目录、目录权限及 Alice 角色映射，不再透传到 knowledge-engine；knowledge-engine 仅通过 `directoryId` 引用目录。**

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/mgmt/knowledge/directories/tree` | 查询知识目录树 | `?includeKbCount?, keyword?, directoryType?` | `{ publicDirectories[], personalDirectories[] }` | 005 |
| POST | `/mgmt/knowledge/directories` | 创建知识目录 | `{ name, parentId?, ... }` | `{ directoryId, ... }` | 005 |
| PATCH | `/mgmt/knowledge/directories/{directoryId}/rename` | 重命名目录 | `{ name }` | `{ directoryId, name, ... }` | 005 |
| PATCH | `/mgmt/knowledge/directories/{directoryId}` | 更新目录 | `{ ...directoryConfig }` | 更新后的目录 | 005 |
| DELETE | `/mgmt/knowledge/directories/{directoryId}` | 删除目录 | — | `{ directoryId, deleted: true }` | 005 |
| POST | `/mgmt/knowledge/tags` | 创建知识库标签 | `{ name }` | `{ tagId, name }` | 005 |
| GET | `/mgmt/knowledge/tags` | 查询知识库标签 | — | `{ items[] }` | 005 |
| POST | `/mgmt/knowledge/knowledge-bases` | 创建知识库 | `{ name, directoryId, pipelineConfig{parser, chunking, enhance, embedding, vectorStore} }` | `{ kbId, status, ... }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases` | 查询知识库列表 | `?directoryId?, keyword?, status?, retrievalReady?, page?, pageSize?` | `{ records[], total }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}` | 查询知识库详情 | — | `{ kbId, pipelineConfig, status, ... }` | 005 |
| PATCH | `/mgmt/knowledge/knowledge-bases/{kbId}/config` | 更新知识库默认配置 | `{ pipelineConfig }` | `{ pipelineConfig, effectScope: "future-builds-only" }` | 005 |
| POST | `/mgmt/knowledge/knowledge-bases/{kbId}/documents` | 创建知识库文档 | `{ fileId, ...documentConfig }` | `{ docId, status, ... }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents` | 查询文档列表 | `?keyword?, sourceType?, status?, retrievalReady?, page?, pageSize?` | `{ records[], total }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/stats` | 查询知识库统计 | — | `{ ...statistics }` | 005 |
| GET | `/mgmt/knowledge/{kbId}/documents/{docId}` | 查询文档详情 | — | `{ documentId, status, ... }` | 005 |
| PATCH | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/stage-config` | 更新文档 Stage 配置 | `{ stageConfig }` | `{ stageConfig, ... }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks` | 查询文档切片 | `?jobId?, page?, pageSize?, snippetContext?` | `{ records[], total }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks/{chunkId}` | 查询切片详情 | `?jobId?, snippetContext?` | `{ chunkId, content, sourceSnippet, ... }` | 005 |
| PUT | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks/{chunkId}` | 保存文档切片 | `{ content, metadata? }` | `{ chunkId, content, ... }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/pages/{page}` | 查询文档页面工作台 | `page>=1` | `{ page, parseContent, chunks, summaryAndTags, parseInfo }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/parse` | 查询文档解析产物 | `?jobId?` | `{ ...parseArtifact }` | 005 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/documents/{docId}/enhance/{enhanceType}` | 查询文档增强产物 | `?jobId?, page?, pageSize?` | `{ records[], total }` | 005 |
| POST | `/mgmt/knowledge/knowledge-bases/{kbId}/build-jobs` | 创建批量构建任务 | `{ documentIds?, runMode? }` | `{ jobId, status, ... }` | 005 |
| GET | `/mgmt/knowledge/jobs/{jobId}` | `[内部]` 查询构建任务 | — | `{ jobId, status, stages[], ... }` | 005 |
| POST | `/mgmt/knowledge/documents/{docId}/stages/{stageType}/run` | `[内部]` 运行文档 Stage | `{ ...stageConfig }` | `{ jobId, status, ... }` | 005 |
| POST | `/mgmt/knowledge/retrievals` | 执行知识检索 | `{ knowledgeBaseIds[], query, retrievalConfig?, topK? }` | `{ results[] }` | 005 |
| POST | `/mgmt/knowledge/knowledge-bases/{kbId}/publish` | 发布知识库 | — | `{ kbId, status: "available", ... }` | 005 |
| POST | `/mgmt/knowledge/knowledge-bases/{kbId}/offline` | 下线知识库 | — | `{ kbId, status, ... }` | 005 |
| GET | `/mgmt/knowledge/platform-resources/vector-store-instances` | 查询可用向量库实例 | `?type?` | `{ data[] }` | 005 |
| GET | `/mgmt/knowledge/directories/{directoryId}/permissions` | 查询目录权限 | — | `{ ...permissionSnapshot }` | 007 |
| GET | `/mgmt/knowledge/knowledge-bases/{kbId}/permissions` | 查询知识库权限 | — | `{ ...permissionSnapshot }` | 007 |

### 3.4 RBAC 与权限（001-create-mgt-service-modules / 003-rbac-permission-mgmt）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgmt/rbac/users` | 创建用户 | `{ ...user }` | `{ userId, ... }` | 001/003 |
| GET | `/mgmt/rbac/users/{userId}` | 查询用户详情 | — | `{ userId, ... }` | 001/003 |
| PUT | `/mgmt/rbac/users/{userId}` | 更新用户 | `{ ...user }` | 更新后的用户 | 003 |
| DELETE | `/mgmt/rbac/users/{userId}` | 删除用户 | — | `{ data: null }` | 003 |
| GET | `/mgmt/rbac/users` | 查询用户列表 | `?keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 001/003 |
| POST | `/mgmt/rbac/users/{userId}/enable` | 启用用户 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/users/{userId}/disable` | 禁用用户 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/users/{userId}/lock` | 锁定用户 | — | `{ data: null }` | 003 |
| PUT | `/mgmt/rbac/users/{userId}/roles` | 替换用户角色 | `{ roleIds[] }` | `{ userId, roleIds[] }` | 003 |
| POST | `/mgmt/rbac/users/{userId}/roles/{roleId}` | 为用户授予角色 | — | `{ data: null }` | 003 |
| DELETE | `/mgmt/rbac/users/{userId}/roles/{roleId}` | 移除用户角色 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/roles` | 创建角色 | `{ ...role }` | `{ roleId, ... }` | 003 |
| GET | `/mgmt/rbac/roles/{roleId}` | 查询角色详情 | — | `{ roleId, ... }` | 003 |
| PUT | `/mgmt/rbac/roles/{roleId}` | 更新角色 | `{ ...role }` | 更新后的角色 | 003 |
| DELETE | `/mgmt/rbac/roles/{roleId}` | 删除角色 | — | `{ data: null }` | 003 |
| GET | `/mgmt/rbac/roles` | 查询角色列表 | `?keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 003 |
| POST | `/mgmt/rbac/roles/{roleId}/enable` | 启用角色 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/roles/{roleId}/disable` | 禁用角色 | — | `{ data: null }` | 003 |
| PUT | `/mgmt/rbac/roles/{roleId}/permissions` | 替换角色权限 | `{ permissionIds[] }` | `{ roleId, permissionIds[] }` | 003 |
| POST | `/mgmt/rbac/roles/{roleId}/permissions/{permissionId}` | 为角色授予权限 | — | `{ data: null }` | 003 |
| DELETE | `/mgmt/rbac/roles/{roleId}/permissions/{permissionId}` | 移除角色权限 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/permissions` | 创建权限 | `{ ...permission }` | `{ permissionId, ... }` | 003 |
| GET | `/mgmt/rbac/permissions/{permissionId}` | 查询权限详情 | — | `{ permissionId, ... }` | 003 |
| PUT | `/mgmt/rbac/permissions/{permissionId}` | 更新权限 | `{ ...permission }` | 更新后的权限 | 003 |
| DELETE | `/mgmt/rbac/permissions/{permissionId}` | 删除权限 | — | `{ data: null }` | 003 |
| GET | `/mgmt/rbac/permissions` | 查询权限列表 | `?resourceType?, keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 003 |
| POST | `/mgmt/rbac/permissions/{permissionId}/enable` | 启用权限 | — | `{ data: null }` | 003 |
| POST | `/mgmt/rbac/permissions/{permissionId}/disable` | 禁用权限 | — | `{ data: null }` | 003 |
| GET | `/mgmt/rbac/permissions/effective/self` | 查询当前用户有效权限 | — | `{ permissions[], roles[] }` | 003 |
| GET | `/mgmt/rbac/permissions/effective` | 查询指定用户有效权限 | `?userId` | `{ permissions[], roles[] }` | 003 |
| POST | `/mgmt/rbac/check` | 检查当前用户权限 | `{ resource, action, ... }` | `{ allowed, reason? }` | 003 |
| POST | `/mgmt/rbac/internal/check` | `[内部]` 检查服务间调用权限 | `{ userId?, resource, action, ... }` | `{ allowed, reason? }` | 003 |

### 3.5 凭据库与 PAT（004-vault / 007-credential）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgmt/vault/inbound/tokens` | 签发 PAT | `{ name, scopes[], expiresAt? }` | `{ id, token(仅返回一次), scopes[], ... }` | 007 |
| GET | `/mgmt/vault/inbound/tokens` | 查询 PAT 列表 | `?page?, pageSize?, status?` | `{ records[], total }` | 007 |
| GET | `/mgmt/vault/inbound/tokens/{id}` | 查询 PAT 详情 | — | `{ id, maskedToken, status, ... }` | 007 |
| POST | `/mgmt/vault/inbound/tokens/{id}/regenerate` | 重新生成 PAT | `{ ...regenerateRequest }` | `{ id, token(仅返回一次), ... }` | 007 |
| PUT | `/mgmt/vault/inbound/tokens/{id}/status` | 更新 PAT 状态 | `{ status }` | `{ data: null }` | 007 |
| DELETE | `/mgmt/vault/inbound/tokens/{id}` | 逻辑删除 PAT | — | `{ data: null }` | 007 |
| GET | `/mgmt/vault/inbound/tokens/stats` | 查询 PAT 统计 | — | `{ ...stats }` | 007 |
| POST | `/mgmt/vault/outbound/credentials` | 创建出站凭据 | `{ targetType, targetId, credentialType, credentials{} }` | `{ id, maskedValue, ... }` | 007 |
| GET | `/mgmt/vault/outbound/credentials` | 查询出站凭据列表 | `?page?, pageSize?, targetType?, status?` | `{ records[], total }` | 007 |
| GET | `/mgmt/vault/outbound/credentials/{id}` | 查询出站凭据详情 | — | `{ id, maskedValue, ... }` | 007 |
| PUT | `/mgmt/vault/outbound/credentials/{id}` | 更新出站凭据 | `{ credentialType?, credentials?{} }` | `{ id, maskedValue, ... }` | 007 |
| PUT | `/mgmt/vault/outbound/credentials/{id}/status` | 更新出站凭据状态 | `{ status }` | `{ data: null }` | 007 |
| DELETE | `/mgmt/vault/outbound/credentials/{id}` | 删除出站凭据 | — | `{ data: null }` | 007 |
| GET | `/mgmt/vault/outbound/credentials/presets` | 查询认证参数预设 | — | `{ targetType: [...presets] }` | 007 |
| GET | `/mgmt/vault/outbound/credentials/presets/{targetType}/{targetId}` | 查询目标资源认证预设 | — | `{ ...preset }` | 007 |
| GET | `/mgmt/vault/outbound/credentials/stats` | 查询出站凭据统计 | — | `{ ...stats }` | 007 |
| POST | `/mgmt/vault/inbound/tokens/verify` | `[内部]` 验证 PAT | `{ token }` | `{ valid, userId?, scopes[], ... }` | 007 |
| GET | `/mgmt/vault/outbound/credentials/{id}/resolve` | `[内部]` 解析出站凭据明文 | — | `{ credentialId, credentialType, fields{} }` | 007 |
| GET | `/mgmt/vault/audit` | 查询凭据审计日志 | `?credentialId?, action?, startTime?, endTime?, page?, size?` | `{ records[], total, page, size }` | 007 |
| POST | `/mgmt/vault/inbound/resolve-asset` | `[内部]` 资产凭据解析（gateway 调用） | `{ assetId, userId }` | `{ resolved, credential{type, token}, source: "asset_service"\|"personal", targetEndpoint }` | 007 |
| POST | `/mgmt/vault/inbound/resolve-model` | `[内部]` 模型凭据解析（AI SDK 调用） | `{ userId }` | `{ resolved, credential{type, token}, source: "personal"\|"platform_default", availableModels[] }` | 007 |

### 3.6 文件服务（横切）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgmt/file/files/upload-sessions` | 创建上传会话 | `{ fileName, contentType, size, bizType, bizRefId? }` | `{ sessionId, uploadUrl, ... }` | 000/002 |
| POST | `/mgmt/file/files/upload-sessions/batch` | 批量创建上传会话 | `{ items[] }` | `{ items[] }` | 000 |
| POST | `/mgmt/file/files/upload-sessions/{sessionId}/complete` | 完成上传会话 | `{ parts?, checksum? }` | `{ fileId, status, ... }` | 000 |
| GET | `/mgmt/file/files/{fileId}` | 查询文件详情 | — | `{ fileId, fileName, size, status, ... }` | 000 |
| POST | `/mgmt/file/files/{fileId}/download-url` | 获取文件下载 URL | `{ ttlSeconds?, usage? }` | `{ downloadUrl, expiresAt, ... }` | 000 |
| DELETE | `/mgmt/file/files/{fileId}` | 删除文件 | — | `{ deleted: true }` | 000 |
| POST | `/mgmt/file/files/results` | 注册处理结果文件 | `{ fileName, blobPath, ... }` | `{ fileId, ... }` | 000 |
| POST | `/mgmt/file/internal/files/{fileId}/download-url` | `[内部]` 获取文件下载 URL | `{ usage, ttlSeconds?, requestId? }` | `{ sasUrl, expiresAt, contentType, size }` | 000/005 |
| POST | `/mgmt/file/internal/files/results` | `[内部]` 注册解析结果文件 | `{ ...resultFile }` | `{ fileId, ... }` | 005 |

### 3.7 Chat 会话与知识库挂载（001-agent-service-platform-chat）

> **数据归属调整**（评审结论，见下方说明）：会话（session）、知识库挂载关系、消息历史
> 三类业务数据的权威均归 **grc-mgmt-service**，不归 grc-agent-service。
> grc-agent-service 不维护业务表，只在收到一次"发消息"请求时，经内部接口向本服务取
> 会话上下文（挂载了哪些知识库、历史消息是什么），生成完成后再经内部接口回写。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgmt/chat/sessions` | 创建会话 | `{ assetId?(平台Chat为空), modelId?, title? }` | `{ id, assetId, title, createdAt }` | 001 |
| GET | `/mgmt/chat/sessions` | 会话列表 | `?page, size, keyword?, assetId?` | `{ items[]{id, assetId?, assetName?, title, lastMessageAt}, total }` | 001 |
| GET | `/mgmt/chat/sessions/{id}` | 会话详情（含历史消息） | — | `{ id, assetId, title, modelId, messages[]{id, role, content, citations[]?, thinkingProcess?, createdAt}, knowledgeMounts[] }` | 001 |
| PATCH | `/mgmt/chat/sessions/{id}` | 重命名会话 | `{ title }` | 更新后的会话摘要 | 001 |
| DELETE | `/mgmt/chat/sessions/{id}` | 删除会话（软删除，消息记录保留审计留痕） | — | `204 No Content` | 001 |
| PUT | `/mgmt/chat/sessions/{id}/knowledge-mounts` | 挂载/卸载知识库（校验用户对目标知识库的访问权限） | `{ knowledgeBaseIds[] }` | `{ mounts[]{knowledgeBaseId, name, snapshotAt} }` | 001 |
| GET | `/mgmt/chat/sessions/{id}/knowledge-mounts` | 已挂载知识库列表 | — | `{ mounts[]{knowledgeBaseId, name, directoryPath} }` | 001 |
| GET | `/mgmt/internal/chat/sessions/{id}/context` | `[内部]` 查询会话上下文（供 grc-agent-service 调用） | `?includeHistory?` | `{ sessionId, knowledgeBaseIds[], modelId?, messages[]{role, content, citations[]?, createdAt} }` | 001 |
| POST | `/mgmt/internal/chat/sessions/{id}/messages` | `[内部]` 追加一条已生成的消息（供 grc-agent-service 在生成完成后回写） | `{ role, content, citations[]?, thinkingProcess? }` | `{ messageId, createdAt }` | 001 |

**补充说明**：

- 本节内容来自 grc-agent-service 技术方案验证过程中的一次架构调整：原方案里会话/知识库挂载/消息历史都由
  grc-agent-service 自建 Postgres 持久化（`chat_sessions`/`chat_records` 两张表），评审后改为本节这个模型——
  grc-agent-service 不建业务表，改成无状态的推理执行引擎，数据权威统一收敛到 grc-mgmt-service。
- `GET .../context` 与 `POST .../messages` 两个内部接口的具体调用时序：grc-agent-service 收到
  `POST /chat/sessions/{id}/messages`（见 §4）后，先同步调 `GET .../context` 取挂载的知识库与历史消息，
  推理/生成完成后再调 `POST .../messages` 回写这一轮的用户输入与最终回复；中途生成失败或被中止是否也要
  回写（写部分内容还是不写），待评审确认。
- 知识库挂载权限校验（无权限的 `knowledgeBaseId` 建议静默剔除、返回实际生效的 `mounts[]`，而非整体报错）
  与 grc-mgmt-service 自己的 RBAC 校验（`/mgmt/rbac/internal/check`，`CATALOG` 类型）复用同一套判定逻辑。
- `KnowledgeMount.snapshotAt` 是既有契约字段名，P0 不赋予会话级检索快照语义；检索授权、知识库状态与可检索范围均按检索时刻实时判断。字段可返回 `null` 或挂载记录时间，未来如需改名另走契约版本迁移。
- `ChatMessage.toolCalls` 与追加消息请求中的 `toolCalls` 为既有契约兼容字段；P0 平台 Chat 不产生、不展示平台原生工具（平台原生 MCP）调用记录，该字段仅为 P1 Chat 调用已订阅 MCP 资产工具能力预留。

### 3.8 当前未在 grc-mgmt-service 中落地的总览接口

以下能力仍在平台 API 草案或上位设计中，但当前服务源码未发现对应控制器，暂不作为本节已实现端点：Agent 配置 `/mgmt/agents/**`、菜单 `/mgmt/menus/**`、通知 `/notifications/**`、护栏模板 `/guardrail-templates/**`、管理后台 `/admin/**` 及旧版个人出站凭据 `/credentials/personal/**`。待对应 feature 实现并形成契约后再补入本节。

---

## 4. grc-agent-service

> **架构调整**（对应 §3.7 说明）：grc-agent-service 是**无状态的推理执行引擎**，不建业务表，
> 不拥有 session / 知识库挂载关系 / 消息历史的权威数据——这些归 grc-mgmt-service。
> 本节只保留"执行一次推理"相关的端点；会话的创建/列表/详情/重命名/删除/知识库挂载管理见 §3.7。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/chat/sessions/{id}/messages` | 发送消息（SSE 流式）。内部先同步调用 `grc-mgmt-service` 的 `GET /mgmt/internal/chat/sessions/{id}/context` 取挂载知识库与历史消息，生成完成后调用 `POST /mgmt/internal/chat/sessions/{id}/messages` 回写这一轮问答 | `{ content, deepAnalysis?: bool }` | SSE stream: `event: delta\|citation\|thinking\|done`；既有 `tool_call` 事件兼容保留，P0 平台 Chat 不产生 | 001 |
| POST | `/chat/sessions/{id}/messages/{msgId}/regenerate` | 重新生成回复（取上下文/回写逻辑同上） | — | SSE stream（同上） | 001 |
| POST | `/chat/sessions/{id}/cancel` | 中止正在进行的流式生成 | — | `{ id, cancelled: bool }` | 001 |

**补充说明（来自 grc-agent-service 技术方案验证，供本节评审参考）**：

- `tool_call` SSE 事件属于既有契约兼容保留：P0 平台 Chat 不调用平台原生工具（平台原生 MCP）、不产生该事件；该事件只为 P1 Chat 调用已订阅 MCP 资产工具能力预留，不能作为 P0 对话链路接入 grc-mcp-server 的依据。
- `POST /chat/sessions/{id}/cancel` 是 SSE 流式场景下的硬需求：客户端断开连接不代表服务端已停止生成，
  需要显式信号；已用真实 LLM 网关验证过中止时序（并发触发 cancel 与流式读取的竞态需要客户端边读流边中止，
  单纯断连不保证及时停止）。中止生成端点未列请求体是因为语义上不需要额外参数，仅路径 `{id}` 标识要中止的
  会话；如果同一会话允许并发多轮生成，可能需要额外的 `messageId` 参数区分中止哪一轮，待评审确认是否存在
  这种并发场景。
- `citations[]`/`thinkingProcess`：会话消息触发知识库检索与深度分析时的记录；流式场景对应 SSE
  `citation`/`thinking` 事件。这些字段最终由 grc-agent-service 生成完成后经内部接口回写给
  grc-mgmt-service 持久化，grc-agent-service 自身不存。
- `deepAnalysis` 字段的具体行为（更长的工具调用轮数上限？还是切换到支持推理链路输出的模型？）待产品/架构明确。
- **待明确**：`GET .../context` 与 `POST .../messages` 两个内部接口的调用时序中，若生成过程中途失败或被
  中止，是否仍要回写已生成的部分内容（还是整轮丢弃不存）？grc-agent-service 完全无状态后，`cancel_registry`
  这类"进行中生成"的标记只能是 grc-agent-service 自己进程内/Redis 的技术态缓存，不能指望 grc-mgmt-service
  代为维护（它不知道具体是哪个 grc-agent-service 实例在处理这条流）。
- 知识库权限校验（`/mgmt/rbac/internal/check`，`CATALOG` 类型）由 grc-mgmt-service 在处理
  `PUT /mgmt/chat/sessions/{id}/knowledge-mounts` 时执行，grc-agent-service 不再需要自己调用校验——
  它拿到的 `knowledgeBaseIds[]`（经 `GET .../context` 返回）已经是校验过、生效的挂载结果。

---

## 5. grc-evaluation-service

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/evaluations` | `[内部]` 触发测评任务 | `{ assetId, versionId, endpoint, checks[]: "prompt_injection"\|"intent_drift"\|"content_safety" }` | `{ id, status: "running", startedAt }` | 004 |
| GET | `/evaluations/{id}` | `[内部]` 查询测评结果 | — | `{ id, assetId, status: "running"\|"passed"\|"failed", score?, threshold, checks[]{type, passed, score}, completedAt? }` | 004 |
| GET | `/evaluations/{id}/report` | `[内部]` 测评详细报告 | — | `{ id, checks[]{type, testCases[]{input, output, score, flagged}}, summary }` | 004 |

---

## 6. grc-knowledge-engine

> 本服务退为**门面之后的内部服务**，不直接面向前端。前端通过 mgmt-service `/mgt/knowledge/**`（§3.3）门面调用。
> 直接调用方：mgmt-service（知识库、文档与构建门面）、agent-service（检索）。知识目录不属于本服务，由 mgmt-service 直接实现；本服务只保存并使用 `directoryId` 引用。

### 6.1 目录能力归属

目录树、目录生命周期、目录权限和角色授予接口统一归属 mgmt-service，见 §3.3。本服务不提供 `/knowledge/directories/**` 接口，也不保存目录或目录权限真相。

知识库创建、查询和数据可见性过滤涉及目录时，mgmt-service 负责校验 `directoryId`、目录层级及调用者权限；knowledge-engine 接收已校验的目录上下文并维护知识库的 `directoryId` 引用。跨服务不得共享目录表或绕过 mgmt-service 直接读写目录数据。

- 需同步修改 spec 005、knowledge-engine OpenAPI、mgmt-service OpenAPI、service-map/manifest 及消费者契约测试；

### 6.2 知识库

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/knowledge/knowledge-bases/pipeline-options` | 查询建库可选参数（前端表单渲染依据，不硬编码枚举） | — | `{ parser{types[], options{}}, chunking{}, enhance{}, embedding{}, vectorStore{}, retrieval{} }` | 005 |
| POST | `/knowledge/knowledge-bases` | 创建知识库 | `{ directoryId, name, description?, visibility?, pipelineConfig{parser, chunking, enhance, embedding, vectorStore, retrieval} }` | `{ kbId, name, status: "DRAFT", embedding{model, dimensions, fingerprint}, vectorStore{type, collection}, myRoles[] }` | 005 |
| GET | `/knowledge/knowledge-bases` | 查询知识库列表（按调用者可见范围过滤） | `?directoryId?, status?, keyword?, scope?, retrievalReady?, page?, pageSize?` | `{ items[]{kbId, name, status, hasFailedDocs, myRoles[], ...}, total }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}` | 查询知识库详情 | — | `{ kbId, pipelineConfig, status, stats{}, rebuildLock?, ... }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/update` | 更新知识库基础信息（名称 / 描述 / 可见范围，不含管线参数） | `{ name?, description?, visibility? }` | 更新后的知识库摘要 | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/pipeline-config` | 保存库级构建参数 | `{ parser?, chunking?, enhance?, retrieval? }` | `{ batchJobId?, affectedDocs?, rebuildRequired? }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/publish` | 发布知识库（草稿→可用） | — | `{ kbId, status: "ACTIVE" }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/offline` | 下线知识库（可用→已停用） | — | `{ kbId, status: "DISABLED", disabledAt }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/delete` | 删除知识库（须先下线，软删除 + 回收向量） | — | `{ kbId, deleted: true, vectorReclaimJobId }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/stats` | 查询知识库统计 | — | `{ docTotal, docVectorized, docFailed, chunkTotal, vectorCount, rebuildProgress? }` | 005 |

### 6.3 文档

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/knowledge/knowledge-bases/{kbId}/documents/imports` | 导入文档（四通道统一批量入口） | `{ sourceType, items[], overwrite?, autoBuild?, runMode?, override?{parser?, chunking?, enhance?} }` | `{ batchJobId?, accepted[], rejected[] }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents` | 查询文档列表 | `?status?, keyword?, retrievalReady?, failedFirst?, page?, pageSize?` | `{ items[]{docId, name, status, failedStage?, errorCode?, canRerunFrom?, chunkCount?, ...}, total }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents/{docId}` | 查询文档详情（含四阶段进度与生效参数） | — | `{ docId, status, stages[], configSnapshot, stageConfig, liveJobId, currentJobId, ... }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/stage-config` | 保存文档级参数覆盖 | `{ parser?, chunking?, enhance? }` | `{ stageConfig, configSnapshot }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/parse` | 查询解析产物（Markdown + 大纲 + 图片名册） | `?jobId?, signUrls?` | `{ parseId, content, outline[], images[], pageCount, hasPageLayout }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks` | 查询切片列表（搜索 / 上下文展开） | `?keyword?, around?, radius?, jobId?, snippetContext?, signUrls?, page?, pageSize?` | `{ items[]{chunkId, content, images[], source{}, ...}, total }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks/{chunkId}` | 查询切片详情 | `?jobId?, signUrls?` | `{ chunkId, content, images[], source{breadcrumb[], pageRange?}, enhancement?, ... }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks/{chunkId}/update` | 保存切片正文编辑 | `{ content }` | `{ chunkId, jobId, rerunStages[], tokenCount, droppedImageAnchors[]? }` | 005 |
| GET | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/enhance/{enhanceType}` | 查询文档增强产物 | `?jobId?, page?, pageSize?` | `{ enhanceType, items[]{artifactId, sourceChunkId, ...}, total }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/original-url` | 签发原文跳转 URL | `{ ttlSeconds? }` | `{ url, mimeType, fileName, expiresAt, urlReusable: true }` | 005 |
| POST | `/knowledge/knowledge-bases/{kbId}/documents/{docId}/delete` | 删除文档（软删除 + 回收向量） | — | `{ docId, deleted: true, vectorReclaimJobId, kbStatusChangedTo? }` | 005 |

### 6.4 构建

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/knowledge/knowledge-bases/{kbId}/build-jobs` | 批量构建 / 重跑失败文档 | `{ docIds?, runMode?, override?, scope?: "SELECTED"\|"ALL_FAILED" }` | `{ batchJobId, totalDocs, accepted[], rejected[] }` | 005 |
| POST | `/knowledge/documents/{docId}/stages/{stageType}/run` | `[内部]` 执行 / 重跑单个阶段 | `{ stageConfig? }` | `{ jobId, status }` | 005 |
| GET | `/knowledge/jobs/{jobId}` | `[内部]` 查询构建任务状态 | — | `{ jobId, status, stages[]?, progress?, failedDocs[]? }` | 005 |

### 6.5 检索与图片证据

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/knowledge/retrievals` | 多知识库检索（返回召回片段证据：溯源 + 图片 + 位置） | `{ query, knowledgeBaseIds[], topK?, strategy?, filters?, rerank?, options?{hydrate?, signUrls?, expandParent?, imageVariant?, ...} }` | `{ results[]{vectorId, recordType, chunkId, content, chunkContent?, source{docName, breadcrumb[], pageRange?, ...}, images[], chunkImages[], score, rerankScore?} }` | 005 |
| POST | `/knowledge/artifacts/access-urls` | 批量签发 / 刷新解析与增强副产物（图片、表格、图表等）指定表示形式的短期访问 URL | `{ items[]{artifactId, representation}, ttlSeconds? }` | `{ items[]{artifactId, artifactType, representation, mediaType, url?, expiresAt?, status, error?} }` | 005 |

### 6.6 开放接口（PAT）

> PAT 校验委托 mgmt-service `POST /mgmt/vault/inbound/tokens/verify`。
> 凭据：`Authorization: Bearer <PAT>`。路径前缀独立为 `/open/knowledge/**`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/open/knowledge/knowledge-bases/{kbId}` | `[开放]` 查询知识库元数据 | — | `{ kbId, name, description, documentCount, embeddingModel, dimensions, lastBuildAt }` | 005 |
| POST | `/open/knowledge/retrievals` | `[开放]` 检索（不接受 `snapshotMode`） | `{ query, knowledgeBaseIds[], topK?, ... }` | 同 §6.5 检索响应 | 005 |
| POST | `/open/knowledge/knowledge-bases/{kbId}/documents` | `[开放]` 上传文档更新知识库内容（`sourceType` 限 `file`） | `{ sourceType: "file", items[]{fileId, name} }` | `{ accepted[], rejected[] }` | 005 |

### 6.7 健康检查

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/health` | 存活探针（进程存活即 200，不检查依赖） | — | `{ status: "ok", service, version, mode }` | 005 |
| GET | `/readyz` | 就绪探针（逐项检查依赖） | — | `{ status, ready, checks{database, redis, serviceBus, vectorStore, parserEngine, objectStore} }` | 005 |

---

## 7. grc-parser-engine

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/parse` | `[内部]` 提交解析任务 | `{ fileId, blobPath, parser: "docling"\|"mineru", outputFormat: "markdown" }` | `{ taskId, status: "queued" }` | 005 |
| GET | `/parse/{taskId}` | `[内部]` 查询解析结果 | — | `{ taskId, status: "queued"\|"running"\|"done"\|"failed", result?{markdownBlobPath, pageCount, parsedAt}, error? }` | 005 |

---

## 8. grc-mcp-server

MCP Server 使用 MCP JSON-RPC 2.0（`tools/list`、`tools/call`）与 Streamable HTTP，
各端点按副本独立部署、故障隔离。下表路径为能力映射，实际 HTTP 挂载仍为对应的
`/mcp/{category}` 端点，通过 `tools/call` 调用，不提供自定义 REST invoke。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/healthz` | `[内部]` 当前 MCP 副本存活检查 | — | `{ status: "ok", service: "grc-mcp-server", endpoint, version: "0.3.0" }` | 000 |

### 8.1 Confluence MCP

实际端点：`POST /mcp/confluence`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mcp/confluence` | 搜索 Confluence 页面 | `tools/call`：`{ name: "confluence_search", arguments: { query, space_key?, credential? } }`；组 B 必须带 `credential` | `{ results[]{ page_id, title, space_key, url, excerpt } }`，最多 10 条，摘要最多 200 字 | 001/005 |
| POST | `/mcp/confluence` | 读取 Confluence 页面 | `tools/call`：`{ name: "confluence_get_page", arguments: { page_id?\|url?, cursor?, credential? } }` | `{ title, url, content, has_more, next_cursor }`，内容分段约 4000 字符 | 001/005 |
| POST | `/mcp/confluence` | 查询页面一层子节点 | `tools/call`：`{ name: "confluence_list_children", arguments: { page_id?\|space_key?, include_attachments?, credential } }` | `{ parent_page_id, children[], attachments[] }` | 005 |
| POST | `/mcp/confluence` | 查询页面有界子树 | `tools/call`：`{ name: "confluence_get_page_tree", arguments: { start, max_depth?, max_nodes?, include_attachments?, credential } }` | `{ root, truncated, stats }` | 005 |
| POST | `/mcp/confluence` | 导入整页及附件 | `tools/call`：`{ name: "confluence_import_page", arguments: { page_id?\|url?, credential } }` | `{ markdown, attachments[]{ local_ref, media_type, size }, manifest }` | 005 |

### 8.2 SharePoint / OneDrive MCP

实际端点：`POST /mcp/sharepoint`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mcp/sharepoint` | 搜索文件或站点项 | `tools/call`：`{ name: "sharepoint_search", arguments: { query, site_id?, drive_id?, credential? } }` | `{ results[]{ item_id, name, web_url, site_id, drive_id, path, mime_type, size, excerpt } }` | 001/005 |
| POST | `/mcp/sharepoint` | 读取文件正文 | `tools/call`：`{ name: "sharepoint_get_file", arguments: { item_id?\|web_url?, drive_id?, cursor?, credential? } }` | `{ name, web_url, mime_type, content, has_more, next_cursor }` | 001/005 |
| POST | `/mcp/sharepoint` | 查询文件夹或文档库一层子项 | `tools/call`：`{ name: "sharepoint_list_children", arguments: { drive_id, item_id?, site_id?, credential } }` | `{ children[]{ item_id, name, is_folder, has_children, mime_type, size, web_url, path } }` | 005 |
| POST | `/mcp/sharepoint` | 查询有界目录树 | `tools/call`：`{ name: "sharepoint_get_folder_tree", arguments: { drive_id, item_id?, site_id?, max_depth?, max_nodes?, credential } }` | `{ root, truncated, stats }` | 005 |
| POST | `/mcp/sharepoint` | 导入单个文件 | `tools/call`：`{ name: "sharepoint_import_item", arguments: { item_id?\|web_url?, drive_id?, credential } }` | `{ name, text_or_markdown, raw_ref, mime_type, size, manifest }` | 005 |

### 8.3 OSS MCP

实际端点：`POST /mcp/oss`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mcp/oss` | 列举白名单桶或容器 | `tools/call`：`{ name: "oss_list_buckets", arguments: { provider?, limit? } }` | `{ provider, buckets[]{ name, region } }` | 001 |
| POST | `/mcp/oss` | 按前缀列举对象 | `tools/call`：`{ name: "oss_list_objects", arguments: { bucket, prefix?, provider?, delimiter?, cursor?, limit? } }` | `{ bucket, prefix, common_prefixes[], objects[], next_cursor }` | 001/005 |
| POST | `/mcp/oss` | 读取对象正文 | `tools/call`：`{ name: "oss_get_object", arguments: { bucket, key, provider?, cursor?, credential? } }` | `{ bucket, key, content_type, size, content, has_more, next_cursor }` | 001/005 |
| POST | `/mcp/oss` | 查询一层前缀或对象 | `tools/call`：`{ name: "oss_list_children", arguments: { bucket, prefix?, provider?, credential } }` | `{ children[]{ name, is_prefix, prefix, key, size, content_type, has_children } }` | 005 |
| POST | `/mcp/oss` | 查询有界前缀树 | `tools/call`：`{ name: "oss_get_prefix_tree", arguments: { bucket, prefix?, provider?, max_depth?, max_nodes?, credential } }` | `{ root, truncated, stats }` | 005 |
| POST | `/mcp/oss` | 导入单个对象 | `tools/call`：`{ name: "oss_import_object", arguments: { bucket, key, provider?, credential } }` | `{ name, key, text_or_markdown, raw_ref, content_type, size, manifest }` | 005 |

### 8.4 数据平台 MCP

实际端点：`POST /mcp/data-platform`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mcp/data-platform` | 搜索数据集或数据资源 | `tools/call`：`{ name: "data_platform_search", arguments: { query, catalog?, limit? } }` | `{ datasets[]{ dataset, name, description, owner, location } }` | 001 |
| POST | `/mcp/data-platform` | 查询数据集 | `tools/call`：`{ name: "data_platform_query", arguments: { dataset, query, parameters? } }` | `{ rows[], columns[], next_cursor? }` | 001 |
| POST | `/mcp/data-platform` | 读取数据集结构 | `tools/call`：`{ name: "data_platform_get_schema", arguments: { dataset } }` | `{ dataset, columns[]{ name, type, nullable, description? } }` | 001 |

### 8.5 Web MCP

实际端点：`POST /mcp/web`。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mcp/web` | Web 搜索 | `tools/call`：`{ name: "web_search", arguments: { query, limit?, domains?[] } }` | `{ results[]{ title, url, excerpt } }` | 001 |
| POST | `/mcp/web` | 抓取网页内容 | `tools/call`：`{ name: "web_fetch", arguments: { url, cursor? } }` | `{ title, url, content, content_type, has_more, next_cursor }` | 001 |

组 A（Chat）工具参数禁止出现 `credential`，使用平台资源凭据；组 B（知识导入）工具
必须携带操作人个人 `credential`，缺失即失败且禁止回落平台凭据。OSS 组 A 仅允许访问
白名单桶。公共默认值：组 A 超时 10 秒、组 B 超时 60 秒、分段约 4000 字符、OSS
对象下载上限 40 MB；错误以结构化 `body.error` 返回，凭据不缓存、不落库且不得写入日志。

---

## 待评审确认项

- [ ] 网关暴露的 API 路径前缀策略（`/api/v1/chat/...` vs `/api/v1/agent/...`）
- [ ] mgmt-service 内部模块的路径是否需要按模块分段（如 `/admin/...` vs `/mgmt/admin/...`）
- [ ] evaluation-service 是仅事件驱动（Service Bus）还是也需要 REST 触发接口
- [ ] parser-engine 是同步还是异步（回调 / 轮询 / 事件通知）
- [ ] 开放 API（PAT 认证）的路径前缀（`/open/...` vs 与内部 API 同路径）
- [ ] 文件上传的直传 SAS 方案是否需要网关参与
- [ ] 通知推送方式（仅轮询 / SSE / WebSocket）
- [ ] grc-agent-service 中止生成（`POST /chat/sessions/{id}/cancel`）是否需要 `messageId` 区分并发多轮生成
- [x] ~~grc-agent-service 知识库挂载权限校验方式~~：已定案，权限校验与知识库挂载管理整体归
      `grc-mgmt-service`（§3.7），grc-agent-service 不再需要自己调用校验接口
- [ ] grc-agent-service ↔ grc-mgmt-service 内部接口时序：生成过程中途失败/被中止时，
      `POST /mgmt/internal/chat/sessions/{id}/messages` 是否仍要回写部分内容（见 §4 补充说明）
- [ ] `GET /mgmt/internal/chat/sessions/{id}/context` 返回的历史消息是否有长度/条数上限
      （避免超长会话把整个历史都传给 grc-agent-service 撑爆单次请求体）
- [ ] grc-agent-service 完全无状态后，`cancel_registry`（进行中生成的中止标记）只能是本地/Redis 技术态缓存，
      多实例部署下如何保证"中止请求"路由到正确处理该流的实例（网关按 sessionId 做一致性哈希？还是
      grc-agent-service 之间共享 Redis 状态？）待架构确认
