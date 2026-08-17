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
| GET | `/chat/sessions` | 会话列表 | `?page, size, keyword?` | `{ items[]{id, assetId?, assetName?, title, lastMessageAt}, total }` | 001 |
| GET | `/chat/sessions/{id}` | 会话详情（含历史消息） | — | `{ id, assetId, title, modelId, messages[]{id, role, content, citations[]?, thinkingProcess?, createdAt}, knowledgeMounts[] }` | 001 |
| DELETE | `/chat/sessions/{id}` | 删除会话 | — | `204 No Content` | 001 |
| POST | `/chat/sessions/{id}/messages` | 发送消息（SSE 流式） | `{ content, deepAnalysis?: bool }` | SSE stream: `event: delta\|citation\|thinking\|tool_call\|done` `data: { ... }` | 001 |
| POST | `/chat/sessions/{id}/messages/{msgId}/regenerate` | 重新生成回复 | — | SSE stream（同上） | 001 |
| PUT | `/chat/sessions/{id}/knowledge-mounts` | 挂载/卸载知识库 | `{ knowledgeBaseIds[] }` | `{ mounts[]{knowledgeBaseId, name, snapshotAt} }` | 001 |
| GET | `/chat/sessions/{id}/knowledge-mounts` | 已挂载知识库列表 | — | `{ mounts[]{knowledgeBaseId, name, directoryPath} }` | 001 |

---

## 5. grc-evaluation-service

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/evaluations` | `[内部]` 触发测评任务 | `{ assetId, versionId, endpoint, checks[]: "prompt_injection"\|"intent_drift"\|"content_safety" }` | `{ id, status: "running", startedAt }` | 004 |
| GET | `/evaluations/{id}` | `[内部]` 查询测评结果 | — | `{ id, assetId, status: "running"\|"passed"\|"failed", score?, threshold, checks[]{type, passed, score}, completedAt? }` | 004 |
| GET | `/evaluations/{id}/report` | `[内部]` 测评详细报告 | — | `{ id, checks[]{type, testCases[]{input, output, score, flagged}}, summary }` | 004 |

---

## 6. grc-knowledge-engine

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/knowledge/directories` | 知识目录树 | `?parentId?(根节点为空)` | `{ items[]{id, name, parentId, type: "public"\|"personal", children[]?} }` | 005 |
| POST | `/knowledge/directories` | 创建目录节点 | `{ name, parentId?, type }` | `{ id, name, parentId, type }` | 005 |
| PUT | `/knowledge/directories/{id}` | 更新目录节点 | `{ name? }` | 更新后的目录对象 | 005 |
| DELETE | `/knowledge/directories/{id}` | 删除目录节点 | — | `204 No Content` | 005 |
| POST | `/knowledge/bases` | 创建知识库 | `{ name, description?, directoryId, pipelineConfig{parser, chunkStrategy, enhancement, embeddingModel, vectorDbInstanceId, reranker?} }` | `{ id, name, status: "draft", createdAt }` | 005 |
| GET | `/knowledge/bases` | 知识库列表 | `?page, size, directoryId?, status?, keyword?` | `{ items[]{id, name, directoryId, status, documentCount, lastBuildAt}, total }` | 005 |
| GET | `/knowledge/bases/{id}` | 知识库详情 | — | `{ id, name, description, directoryId, status, pipelineConfig{}, documentCount, vectorCount, lastBuildAt, createdAt }` | 005 |
| PUT | `/knowledge/bases/{id}` | 更新知识库配置 | `{ name?, description?, pipelineConfig?{} }` | 更新后的知识库对象 | 005 |
| DELETE | `/knowledge/bases/{id}` | 删除知识库 | — | `204 No Content` | 005 |
| POST | `/knowledge/bases/{id}/enable` | 启用知识库 | — | `{ status: "available" }` | 005 |
| POST | `/knowledge/bases/{id}/disable` | 禁用知识库 | — | `{ status: "disabled" }` | 005 |
| POST | `/knowledge/bases/{id}/documents` | 上传/导入文档 | `{ channel: "upload"\|"confluence"\|"sharepoint"\|"blob", files[]?\|sourceConfig?{} }` | `{ documentIds[], importStatus }` | 005 |
| GET | `/knowledge/bases/{id}/documents` | 文档列表 | `?page, size` | `{ items[]{docId, fileName, channel, status, size, parsedAt?}, total }` | 005 |
| DELETE | `/knowledge/bases/{id}/documents/{docId}` | 删除文档 | — | `204 No Content` | 005 |
| POST | `/knowledge/bases/{id}/build` | 触发构建 | `{ fullRebuild?: bool }` | `{ buildId, status: "running", stages: ["parse","chunk","enhance","vectorize"] }` | 005 |
| GET | `/knowledge/bases/{id}/build-status` | 构建状态 | — | `{ buildId, status, currentStage, progress, startedAt, errors[]? }` | 005 |
| POST | `/knowledge/bases/{id}/search` | 向量检索 | `{ query, topK?: 5, filters?{} }` | `{ results[]{docId, chunk, score, metadata{}} }` | 005 |
| GET | `/knowledge/bases/{id}/metadata` | `[开放]` 元数据 | Header: `X-PAT-Token` | `{ id, name, description, documentCount, lastBuildAt }` | 005 |
| POST | `/knowledge/bases/{id}/open-search` | `[开放]` 检索 | Header: `X-PAT-Token`, `{ query, topK? }` | `{ results[]{chunk, score, metadata{}} }` | 005 |
| PUT | `/knowledge/bases/{id}/open-content` | `[开放]` 更新内容 | Header: `X-PAT-Token`, `{ documents[]{action: "add"\|"delete", fileId?\|docId?} }` | `{ accepted, buildTriggered }` | 005 |

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
