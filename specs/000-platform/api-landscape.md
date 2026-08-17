# API Landscape — 全局接口概览

> **状态**：Draft — 待团队评审
> **日期**：2026-08-17
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

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/auth/userinfo` | 获取当前用户信息 | Header: `Authorization` | `{ userId, name, email, avatar, roles[] }` | 007 |
| POST | `/auth/verify` | 校验 Access Token 并返回用户上下文 | `{ token }` | `{ valid, userId, roles[], tenantId, exp }` | 001 |
| POST | `/auth/logout` | 登出，吊销 Token | Header: `Authorization` | `{ code, message, data: null }` | 001 |
| POST | `/auth/refresh` | 刷新 Token | `{ refreshToken, clientId }` | `{ accessToken, refreshToken, expiresIn }` | 001 |
| GET | `/auth/oidc/authorize` | 发起 OIDC 授权并生成一次性 state | `?provider, redirectUri?` | `{ url, state, expireIn }` | 003 |
| GET | `/auth/oidc/callback` | OIDC 回调登录，完成身份映射并颁发平台 Token | `?provider, code, state` | `{ accessToken, refreshToken?, userInfo, redirectUrl? }` | 003 |
| GET | `/auth/oauth/authorize` | `[兼容]` 获取 OAuth 授权地址 | — | `{ url, state }` | 001 |
| POST | `/auth/alice/users/sync` | `[内部]` 手动触发 Alice 用户同步 | — | `{ correlationId, triggerType, status, tasks[] }` | 002 |
| GET | `/auth/alice/users/sync-jobs/{correlationId}` | `[内部]` 查询 Alice 用户同步任务 | — | `{ correlationId, triggerType, status, tasks[] }` | 002 |

---

## 3. grc-mgmt-service

> 当前服务接口使用 `/mgt` 作为服务内路由前缀；经网关暴露时仍由网关统一加 `/api/v1`。
> 服务统一返回 `ApiResponse` 包络，具体业务字段以对应 feature contract 为准。

### 3.1 Marketplace 资产（002-marketplace / 005-marketplace-redesign）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgt/marketplace/assets` | 创建资产 | `{ type, name, description?, ... }` | `{ assetId, ... }` | 002/003 |
| GET | `/mgt/marketplace/assets` | 查询资产列表 | `?page, pageSize, keyword?, type?, status?` | `{ records[], total }` | 002 |
| GET | `/mgt/marketplace/assets/{assetId}` | 查询资产详情 | — | `{ assetId, name, type, owner, status, ... }` | 002 |
| PUT | `/mgt/marketplace/assets/{assetId}` | 更新资产 | `{ name?, description?, ... }` | 更新后的资产 | 003 |
| POST | `/mgt/marketplace/assets/{assetId}/precheck` | 执行发布前预检 | — | `{ passed, checks[], ... }` | 005 |
| POST | `/mgt/marketplace/assets/{assetId}/publish` | 发布资产 | — | `{ assetId, status, ... }` | 004/005 |
| POST | `/mgt/marketplace/assets/{assetId}/unpublish` | 下架资产 | — | `{ data: null }` | 004 |
| POST | `/mgt/marketplace/assets/{assetId}/archive` | 归档资产 | — | `{ data: null }` | 004 |
| POST | `/mgt/marketplace/assets/{assetId}/transfer-owner` | 转移资产 Owner | `{ newOwnerId }` | `{ assetId, ownerId, ... }` | 005 |
| POST | `/mgt/marketplace/assets/yaml-preview` | 预览资产 YAML | `{ ...assetConfig }` | `{ yaml, ... }` | 003 |
| DELETE | `/mgt/marketplace/assets/draft/{assetId}` | 删除编辑态缓存 | — | `{ data: null }` | 003 |

### 3.2 Marketplace 订阅与审批（002-marketplace / 005-marketplace-redesign）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/mgt/marketplace/assets/{assetId}/subscribe/page-init` | 初始化订阅提交页 | — | `{ asset, terms, approvalConfig, ... }` | 002 |
| POST | `/mgt/marketplace/assets/{assetId}/subscribe` | 提交订阅申请 | `{ ...subscriptionRequest }` | `{ subscriptionId, status, ... }` | 002/005 |
| GET | `/mgt/marketplace/subscriber-center/summary` | 查询订阅者中心统计 | — | `{ ...summary }` | 002 |
| GET | `/mgt/marketplace/subscriptions` | 查询我的订阅 | `?page, pageSize, status?` | `{ records[], total }` | 002 |
| GET | `/mgt/marketplace/subscriptions/{subscriptionId}` | 查询订阅详情 | — | `{ subscriptionId, status, approvalProgress[], ... }` | 002 |
| POST | `/mgt/marketplace/subscriptions/{subscriptionId}/resubmit` | 驳回后重新提交订阅 | `{ ...subscriptionRequest }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgt/marketplace/subscriptions/{subscriptionId}/cancel` | 取消订阅申请 | — | `{ data: null }` | 002 |
| GET | `/mgt/marketplace/approval-flows/{flowId}` | 查询审批流详情 | — | `{ flowId, steps[], status, ... }` | 005 |
| GET | `/mgt/marketplace/approval-flows/my-pending` | 查询我的待审批事项 | `?page, pageSize` | `{ records[], total }` | 005 |
| POST | `/mgt/marketplace/approval-flows/{flowId}/steps/{stepId}/approve` | 审批通过当前步骤 | `{ comment? }` | `{ flowId, stepId, status, ... }` | 005 |
| POST | `/mgt/marketplace/approval-flows/{flowId}/steps/{stepId}/reject` | 驳回当前审批步骤 | `{ reason }` | `{ flowId, stepId, status, ... }` | 005 |
| GET | `/mgt/marketplace/creator-center/summary` | 查询创作者中心统计 | — | `{ ...summary }` | 005 |
| GET | `/mgt/marketplace/creator-center/assets` | 查询创作者资产 | `?page, pageSize, status?` | `{ records[], total }` | 005 |
| GET | `/mgt/marketplace/creator-center/pending-subscriptions` | 查询待处理订阅 | `?page, pageSize` | `{ records[], total }` | 005 |
| GET | `/mgt/marketplace/creator-center/pending-publish-assets` | 查询待发布资产 | `?page, pageSize` | `{ records[], total }` | 005 |
| GET | `/mgt/marketplace/creator-center/assets/{assetId}/console` | 查询创作者资产控制台 | — | `{ asset, subscriptions, publishState, ... }` | 005 |
| PUT | `/mgt/marketplace/creator-center/assets/{assetId}/subscription-settings` | 保存订阅设置 | `{ ...subscriptionSettings }` | 更新后的订阅设置 | 005 |
| POST | `/mgt/marketplace/creator-center/subscriptions/{subscriptionId}/decision` | 处理订阅审批决定 | `{ decision, reason? }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgt/marketplace/creator-center/subscriptions/{subscriptionId}/revoke` | 撤回订阅处理结果 | `{ reason? }` | `{ subscriptionId, status, ... }` | 005 |
| POST | `/mgt/marketplace/assets/{assetId}/publish-evaluations` | 创建发布测评 | `{ ...evaluationRequest }` | `{ evaluationId, status, ... }` | 005 |
| GET | `/mgt/marketplace/assets/{assetId}/publish-evaluations/{evaluationId}` | 查询发布测评 | — | `{ evaluationId, status, checks[], ... }` | 005 |
| GET | `/mgt/marketplace/tags` | 查询全部资产标签 | — | `{ items[] }` | 002 |

### 3.3 知识库门面（005-knowledge）

知识库接口由 mgmt-service 对 knowledge-engine 提供前端门面；Stage 运行与任务查询中标 `[内部]` 的接口仅供平台服务调用。

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/mgt/knowledge/directories/tree` | 查询知识目录树 | `?includeKbCount?, keyword?` | `{ nodes[] }` | 005 |
| POST | `/mgt/knowledge/directories` | 创建知识目录 | `{ name, parentId?, ... }` | `{ directoryId, ... }` | 005 |
| PATCH | `/mgt/knowledge/directories/{directoryId}/rename` | 重命名目录 | `{ name }` | `{ directoryId, name, ... }` | 005 |
| PATCH | `/mgt/knowledge/directories/{directoryId}` | 更新目录 | `{ ...directoryConfig }` | 更新后的目录 | 005 |
| DELETE | `/mgt/knowledge/directories/{directoryId}` | 删除目录 | — | `{ directoryId, deleted: true }` | 005 |
| POST | `/mgt/knowledge/knowledge-bases` | 创建知识库 | `{ name, directoryId, pipelineConfig{parser, chunking, enhance, embedding, vectorStore} }` | `{ kbId, status, ... }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases` | 查询知识库列表 | `?directoryId?, keyword?, status?, retrievalReady?, page?, pageSize?` | `{ records[], total }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}` | 查询知识库详情 | — | `{ kbId, pipelineConfig, status, ... }` | 005 |
| PATCH | `/mgt/knowledge/knowledge-bases/{kbId}/config` | 更新知识库默认配置 | `{ pipelineConfig }` | `{ pipelineConfig, effectScope: "future-builds-only" }` | 005 |
| POST | `/mgt/knowledge/knowledge-bases/{kbId}/documents` | 创建知识库文档 | `{ fileId, ...documentConfig }` | `{ docId, status, ... }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents` | 查询文档列表 | `?keyword?, sourceType?, status?, retrievalReady?, page?, pageSize?` | `{ records[], total }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/stats` | 查询知识库统计 | — | `{ ...statistics }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}` | 查询文档详情 | — | `{ docId, status, ... }` | 005 |
| PATCH | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}/stage-config` | 更新文档 Stage 配置 | `{ stageConfig }` | `{ stageConfig, ... }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks` | 查询文档切片 | `?jobId?, page?, pageSize?, snippetContext?` | `{ records[], total }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}/chunks/{chunkId}` | 查询切片详情 | `?jobId?, snippetContext?` | `{ chunkId, content, sourceSnippet, ... }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}/parse` | 查询文档解析产物 | `?jobId?` | `{ ...parseArtifact }` | 005 |
| GET | `/mgt/knowledge/knowledge-bases/{kbId}/documents/{docId}/enhance/{enhanceType}` | 查询文档增强产物 | `?jobId?, page?, pageSize?` | `{ records[], total }` | 005 |
| POST | `/mgt/knowledge/knowledge-bases/{kbId}/build-jobs` | 创建批量构建任务 | `{ documentIds?, runMode? }` | `{ jobId, status, ... }` | 005 |
| GET | `/mgt/knowledge/jobs/{jobId}` | `[内部]` 查询构建任务 | — | `{ jobId, status, stages[], ... }` | 005 |
| POST | `/mgt/knowledge/documents/{docId}/stages/{stageType}/run` | `[内部]` 运行文档 Stage | `{ ...stageConfig }` | `{ jobId, status, ... }` | 005 |
| POST | `/mgt/knowledge/retrievals` | 执行知识检索 | `{ knowledgeBaseIds[], query, retrievalConfig?, topK? }` | `{ results[] }` | 005 |
| POST | `/mgt/knowledge/knowledge-bases/{kbId}/publish` | 发布知识库 | — | `{ kbId, status: "available", ... }` | 005 |
| POST | `/mgt/knowledge/knowledge-bases/{kbId}/offline` | 下线知识库 | — | `{ kbId, status, ... }` | 005 |

### 3.4 RBAC 与权限（001-create-mgt-service-modules / 003-rbac-permission-mgmt）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
|------|------|------|---------|---------|------|
| POST | `/mgt/users` | 创建用户 | `{ ...user }` | `{ userId, ... }` | 001/003 |
| GET | `/mgt/users/{userId}` | 查询用户详情 | — | `{ userId, ... }` | 001/003 |
| PUT | `/mgt/users/{userId}` | 更新用户 | `{ ...user }` | 更新后的用户 | 003 |
| DELETE | `/mgt/users/{userId}` | 删除用户 | — | `{ data: null }` | 003 |
| GET | `/mgt/users` | 查询用户列表 | `?keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 001/003 |
| POST | `/mgt/users/{userId}/enable` | 启用用户 | — | `{ data: null }` | 003 |
| POST | `/mgt/users/{userId}/disable` | 禁用用户 | — | `{ data: null }` | 003 |
| POST | `/mgt/users/{userId}/lock` | 锁定用户 | — | `{ data: null }` | 003 |
| PUT | `/mgt/users/{userId}/roles` | 替换用户角色 | `{ roleIds[] }` | `{ userId, roleIds[] }` | 003 |
| POST | `/mgt/users/{userId}/roles/{roleId}` | 为用户授予角色 | — | `{ data: null }` | 003 |
| DELETE | `/mgt/users/{userId}/roles/{roleId}` | 移除用户角色 | — | `{ data: null }` | 003 |
| POST | `/mgt/rbac/roles` | 创建角色 | `{ ...role }` | `{ roleId, ... }` | 003 |
| GET | `/mgt/rbac/roles/{roleId}` | 查询角色详情 | — | `{ roleId, ... }` | 003 |
| PUT | `/mgt/rbac/roles/{roleId}` | 更新角色 | `{ ...role }` | 更新后的角色 | 003 |
| DELETE | `/mgt/rbac/roles/{roleId}` | 删除角色 | — | `{ data: null }` | 003 |
| GET | `/mgt/rbac/roles` | 查询角色列表 | `?keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 003 |
| POST | `/mgt/rbac/roles/{roleId}/enable` | 启用角色 | — | `{ data: null }` | 003 |
| POST | `/mgt/rbac/roles/{roleId}/disable` | 禁用角色 | — | `{ data: null }` | 003 |
| PUT | `/mgt/roles/{roleId}/permissions` | 替换角色权限 | `{ permissionIds[] }` | `{ roleId, permissionIds[] }` | 003 |
| POST | `/mgt/roles/{roleId}/permissions/{permissionId}` | 为角色授予权限 | — | `{ data: null }` | 003 |
| DELETE | `/mgt/roles/{roleId}/permissions/{permissionId}` | 移除角色权限 | — | `{ data: null }` | 003 |
| POST | `/mgt/permissions` | 创建权限 | `{ ...permission }` | `{ permissionId, ... }` | 003 |
| GET | `/mgt/permissions/{permissionId}` | 查询权限详情 | — | `{ permissionId, ... }` | 003 |
| PUT | `/mgt/permissions/{permissionId}` | 更新权限 | `{ ...permission }` | 更新后的权限 | 003 |
| DELETE | `/mgt/permissions/{permissionId}` | 删除权限 | — | `{ data: null }` | 003 |
| GET | `/mgt/permissions` | 查询权限列表 | `?resourceType?, keyword?, status?, pageNum?, pageSize?` | `{ records[], total }` | 003 |
| POST | `/mgt/permissions/{permissionId}/enable` | 启用权限 | — | `{ data: null }` | 003 |
| POST | `/mgt/permissions/{permissionId}/disable` | 禁用权限 | — | `{ data: null }` | 003 |
| GET | `/mgt/permissions/effective/self` | 查询当前用户有效权限 | — | `{ permissions[], roles[] }` | 003 |
| GET | `/mgt/permissions/effective` | 查询指定用户有效权限 | `?userId` | `{ permissions[], roles[] }` | 003 |
| POST | `/mgt/check` | 检查当前用户权限 | `{ resource, action, ... }` | `{ allowed, reason? }` | 003 |
| POST | `/mgt/internal/check` | `[内部]` 检查服务间调用权限 | `{ userId?, resource, action, ... }` | `{ allowed, reason? }` | 003 |

### 3.5 凭据库与 PAT（004-vault / 007-credential）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgt/vault/inbound/tokens` | 签发 PAT | `{ name, scopes[], expiresAt? }` | `{ id, token(仅返回一次), scopes[], ... }` | 007 |
| GET | `/mgt/vault/inbound/tokens` | 查询 PAT 列表 | `?page?, pageSize?, status?` | `{ records[], total }` | 007 |
| GET | `/mgt/vault/inbound/tokens/{id}` | 查询 PAT 详情 | — | `{ id, maskedToken, status, ... }` | 007 |
| POST | `/mgt/vault/inbound/tokens/{id}/regenerate` | 重新生成 PAT | `{ ...regenerateRequest }` | `{ id, token(仅返回一次), ... }` | 007 |
| PUT | `/mgt/vault/inbound/tokens/{id}/status` | 更新 PAT 状态 | `{ status }` | `{ data: null }` | 007 |
| DELETE | `/mgt/vault/inbound/tokens/{id}` | 逻辑删除 PAT | — | `{ data: null }` | 007 |
| GET | `/mgt/vault/inbound/tokens/stats` | 查询 PAT 统计 | — | `{ ...stats }` | 007 |
| POST | `/mgt/vault/outbound/credentials` | 创建出站凭据 | `{ targetType, targetId, credentialType, credentials{} }` | `{ id, maskedValue, ... }` | 007 |
| GET | `/mgt/vault/outbound/credentials` | 查询出站凭据列表 | `?page?, pageSize?, targetType?, status?` | `{ records[], total }` | 007 |
| GET | `/mgt/vault/outbound/credentials/{id}` | 查询出站凭据详情 | — | `{ id, maskedValue, ... }` | 007 |
| PUT | `/mgt/vault/outbound/credentials/{id}` | 更新出站凭据 | `{ credentialType?, credentials?{} }` | `{ id, maskedValue, ... }` | 007 |
| PUT | `/mgt/vault/outbound/credentials/{id}/status` | 更新出站凭据状态 | `{ status }` | `{ data: null }` | 007 |
| DELETE | `/mgt/vault/outbound/credentials/{id}` | 删除出站凭据 | — | `{ data: null }` | 007 |
| GET | `/mgt/vault/outbound/credentials/presets` | 查询认证参数预设 | — | `{ targetType: [...presets] }` | 007 |
| GET | `/mgt/vault/outbound/credentials/presets/{targetType}/{targetId}` | 查询目标资源认证预设 | — | `{ ...preset }` | 007 |
| GET | `/mgt/vault/outbound/credentials/stats` | 查询出站凭据统计 | — | `{ ...stats }` | 007 |
| POST | `/mgt/vault/inbound/tokens/verify` | `[内部]` 验证 PAT | `{ token }` | `{ valid, userId?, scopes[], ... }` | 007 |
| GET | `/mgt/vault/outbound/credentials/{id}/resolve` | `[内部]` 解析出站凭据 | — | `{ credentialType, resolvedCredentials, ... }` | 007 |

### 3.6 文件服务（横切）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/mgt/files/upload-sessions` | 创建上传会话 | `{ fileName, contentType, size, bizType, bizRefId? }` | `{ sessionId, uploadUrl, ... }` | 000/002 |
| POST | `/mgt/files/upload-sessions/batch` | 批量创建上传会话 | `{ items[] }` | `{ items[] }` | 000 |
| POST | `/mgt/files/upload-sessions/{sessionId}/complete` | 完成上传会话 | `{ parts?, checksum? }` | `{ fileId, status, ... }` | 000 |
| POST | `/mgt/files/upload` | 直接上传文件 | `{ fileName, contentType, fileContent, bizType, bizRefId }` | `{ fileId, status, ... }` | 000 |
| POST | `/mgt/files/upload/multipart` | Multipart 上传文件 | Form: `bizType, bizRefId, file` | `{ fileId, status, ... }` | 000 |
| POST | `/mgt/files/upload/multipart/batch` | 批量 Multipart 上传 | Form: `bizType, bizRefId?, files[]` | `{ items[] }` | 000 |
| GET | `/mgt/files/{fileId}` | 查询文件详情 | — | `{ fileId, fileName, size, status, ... }` | 000 |
| POST | `/mgt/files/{fileId}/download-url` | 获取文件下载 URL | `{ ttlSeconds?, usage? }` | `{ downloadUrl, expiresAt, ... }` | 000 |
| DELETE | `/mgt/files/{fileId}` | 删除文件 | — | `{ deleted: true }` | 000 |
| POST | `/mgt/files/results` | 注册处理结果文件 | `{ fileName, blobPath, ... }` | `{ fileId, ... }` | 000 |
| POST | `/mgt/internal/files/{fileId}/download-url` | `[内部]` 获取文件下载 URL | `{ usage, ttlSeconds?, requestId? }` | `{ sasUrl, expiresAt, contentType, size }` | 000/005 |
| POST | `/mgt/internal/files/results` | `[内部]` 注册解析结果文件 | `{ ...resultFile }` | `{ fileId, ... }` | 005 |

### 3.7 当前未在 grc-mgmt-service 中落地的总览接口

以下能力仍在平台 API 草案或上位设计中，但当前服务源码未发现对应控制器，暂不作为本节已实现端点：Agent 配置 `/mgt/agents/**`、菜单 `/mgt/menus/**`、通知 `/notifications/**`、护栏模板 `/guardrail-templates/**`、管理后台 `/admin/**` 及旧版个人出站凭据 `/credentials/personal/**`。待对应 feature 实现并形成契约后再补入本节。

---

## 4. grc-agent-service

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/chat/sessions` | 创建会话 | `{ assetId?(平台Chat为空), modelId?, title? }` | `{ id, assetId, title, createdAt }` | 001 |
| GET | `/chat/sessions` | 会话列表 | `?page, size, keyword?, assetId?` | `{ items[]{id, assetId?, assetName?, title, lastMessageAt}, total }` | 001 |
| GET | `/chat/sessions/{id}` | 会话详情（含历史消息） | — | `{ id, assetId, title, modelId, messages[]{id, role, content, citations[]?, toolCalls[]?, thinkingProcess?, createdAt}, knowledgeMounts[] }` | 001 |
| PATCH | `/chat/sessions/{id}` | 重命名会话 | `{ title }` | 更新后的会话摘要 | 001 |
| DELETE | `/chat/sessions/{id}` | 删除会话（软删除，消息记录保留审计留痕） | — | `204 No Content` | 001 |
| POST | `/chat/sessions/{id}/messages` | 发送消息（SSE 流式） | `{ content, deepAnalysis?: bool }` | SSE stream: `event: delta\|citation\|tool_call\|thinking\|done` `data: { ... }` | 001 |
| POST | `/chat/sessions/{id}/messages/{msgId}/regenerate` | 重新生成回复 | — | SSE stream（同上） | 001 |
| POST | `/chat/sessions/{id}/cancel` | 中止正在进行的流式生成 | — | `{ id, cancelled: bool }` | 001 |
| PUT | `/chat/sessions/{id}/knowledge-mounts` | 挂载/卸载知识库（挂载前校验用户对目标知识库的访问权限） | `{ knowledgeBaseIds[] }` | `{ mounts[]{knowledgeBaseId, name, snapshotAt} }` | 001 |
| GET | `/chat/sessions/{id}/knowledge-mounts` | 已挂载知识库列表 | — | `{ mounts[]{knowledgeBaseId, name, directoryPath} }` | 001 |

**补充说明（来自 grc-agent-service 技术方案验证，供本节评审参考）**：

- `PATCH /chat/sessions/{id}`、`POST /chat/sessions/{id}/cancel` 为本次新增：原清单只有创建/列表/详情/删除，
  缺重命名与中止生成两个端点——中止生成是 SSE 流式场景下的硬需求（客户端断开连接不代表服务端已停止生成，
  需要显式信号），已用真实 LLM 网关验证过中止时序（并发触发 cancel 与流式读取的竞态需要客户端边读流边中止，
  单纯断连不保证及时停止）。
- `messages[].toolCalls[]`：会话消息触发平台原生工具（`grc-mcp-server`：Confluence / SharePoint-OneDrive /
  数据平台 / Web）时的调用记录，`{ toolName, arguments, resultSummary }`；流式场景对应 SSE `tool_call` 事件，
  工具执行完成后一次性推送（不分片）。
- `PUT /chat/sessions/{id}/knowledge-mounts`：建议内部实现挂载前调用 `grc-mgt-service`
  `POST /mgt/internal/check`（`resource=knowledge_base`）逐个校验用户权限，无权限的 `knowledgeBaseId`
  建议静默剔除并返回实际生效的 `mounts[]`（而非整体报错），避免因为单个知识库权限问题中断整个挂载操作；
  用户身份（`userId`）的真实性仍依赖网关鉴权，本服务只做"给定 userId 有没有权限"的判定，不做身份鉴权本身。
- `deepAnalysis` 字段的具体行为（更长的工具调用轮数上限？还是切换到支持推理链路输出的模型？）待产品/架构明确。
- 中止生成端点未列出请求体是因为语义上不需要额外参数，仅路径 `{id}` 标识要中止的会话；如果同一会话允许并发多轮
  生成，可能需要额外的 `messageId` 参数区分中止哪一轮，待评审确认是否存在这种并发场景。

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
> 直接调用方：mgmt-service（门面透传）、agent-service（检索）。HTTP 方法只用 `GET` / `POST`。
> 详细设计见 `KB-coding/docs/lasted/03-接口文档.md`（v2.0）。

### 6.1 目录树

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/knowledge/directories/tree` | 查询知识目录树（两棵完整树，含权限与操作按钮状态） | `?rootType?, keyword?` | `{ roots[]{dirId, name, level, isLeaf, kbCount, accessible, permissions{}, children[]} }` | 005 |
| POST | `/knowledge/directories` | 创建子目录（含知识库下沉迁移） | `{ parentId, name, description? }` | `{ dirId, name, level, isLeaf, migratedKbCount }` | 005 |
| POST | `/knowledge/directories/{dirId}/rename` | 重命名目录 | `{ name, description? }` | `{ dirId, name }` | 005 |
| POST | `/knowledge/directories/{dirId}/delete` | 删除空目录 | — | `{ dirId, deleted: true, deletedSubDirCount? }` | 005 |
| GET | `/knowledge/directories/{dirId}/permission` | 查询目录权限与 Alice 申请入口 | — | `{ roles[], applyUrl, myRoles[] }` | 005 |
| POST | `/knowledge/directories/{dirId}/role-grants` | 授予 / 回收目录角色 | `{ action: "GRANT"\|"REVOKE", roleType, userIds[] }` | `{ results[]{userId, status, message?} }` | 005 |

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
| POST | `/knowledge/image-urls` | 签发 / 刷新召回图片访问 URL | `{ items[]{chunkId, imageIds[]}, ttlSeconds? }` | `{ items[]{chunkId, imageId, url?, thumbUrl?, expiresAt?, error?} }` | 005 |

### 6.6 开放接口（PAT）

> PAT 校验委托 mgmt-service `POST /mgt/vault/inbound/tokens/verify`。
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

MCP Server 端点遵循 MCP 协议（JSON-RPC over stdio/SSE），不是标准 REST。

| 端点 | 工具能力 | 典型调用参数 | 典型返回 | Spec |
|------|---------|-------------|---------|------|
| `/mcp/confluence` | Confluence 页面搜索/读取 | `{ space, query?, pageId? }` | `{ pages[]{title, content, url} }` | 001 |
| `/mcp/sharepoint` | SharePoint/OneDrive 文件搜索/读取 | `{ site?, path?, query? }` | `{ files[]{name, content, url} }` | 001 |
| `/mcp/data-platform` | 数据平台查询 | `{ dataset, query }` | `{ rows[], columns[] }` | 001 |
| `/mcp/web` | Web 搜索/抓取 | `{ url?\|query? }` | `{ content, title, url }` | 001 |

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
- [ ] grc-agent-service 知识库挂载权限校验方式：调用 `grc-mgt-service` 的具体接口/参数形态待与该服务对齐
      （landscape 里 `/mgt/internal/check` 当前入参是 `{ userId?, resource, action, ... }`，`resource=knowledge_base`
      时具体怎么传知识库 ID 待统一）
