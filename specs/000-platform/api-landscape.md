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
| POST | `/auth/login` | Alice SSO 登录回调，颁发平台 Token | `{ ssoCode, redirectUri }` | `{ accessToken, refreshToken, expiresIn, user }` | 007 |
| POST | `/auth/logout` | 登出，吊销 Token | Header: `Authorization` | `204 No Content` | 007 |
| POST | `/auth/refresh` | 刷新 Token | `{ refreshToken }` | `{ accessToken, refreshToken, expiresIn }` | 007 |
| GET | `/auth/userinfo` | 获取当前用户信息 | Header: `Authorization` | `{ userId, name, email, avatar, roles[] }` | 007 |
| POST | `/auth/validate` | `[内部]` 校验 Token / PAT | `{ token, type: "bearer"\|"pat" }` | `{ valid, userId, permissions[], scopes[]? }` | 007 |

---

## 3. grc-mgmt-service

### 3.1 资产目录 & Marketplace（002-marketplace）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/assets` | 资产列表 | `?page, size, keyword?, type?, channel?(recommended\|hot\|all)` | `{ items[]{id, name, type, icon, description, subscriberCount, status}, total }` | 002 |
| GET | `/assets/{id}` | 资产详情 | — | `{ id, name, type, description, icon, owner, version, capabilities[], subscriptionConfig, guardrailTemplate, status, createdAt }` | 002 |
| GET | `/assets/{id}/versions` | 版本历史 | `?page, size` | `{ items[]{versionId, version, releaseNotes, isBreaking, publishedAt}, total }` | 004 |
| GET | `/assets/{id}/versions/{versionId}` | 指定版本详情 | — | `{ versionId, version, releaseNotes, isBreaking, migrationGuide?, diff?, publishedAt }` | 004 |

### 3.2 资产创建 & 配置（003-asset-creation）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/assets` | 创建资产（草稿） | `{ type: "Agent"\|"MCP", name, description, icon? }` | `{ id, status: "draft", createdAt }` | 003 |
| PUT | `/assets/{id}` | 更新基本信息 | `{ name?, description?, icon?, tags[]? }` | 更新后的资产对象 | 003 |
| PUT | `/assets/{id}/connection` | 配置连接信息 | Agent: `{ endpoint, healthCheckUrl }` / MCP: `{ transportType, url }` | `{ connectionStatus, lastCheckedAt }` | 003 |
| PUT | `/assets/{id}/auth` | 配置认证方式 | `{ authMode: "service"\|"per-user"\|"none", credentialType? }` | 确认后的认证配置 | 003 |
| PUT | `/assets/{id}/capabilities` | 配置能力声明 | Agent: `{ card, toolList[] }` / MCP: `{ tools[], resources[]? }` | 确认后的能力列表 | 003 |
| PUT | `/assets/{id}/subscription-config` | 配置订阅策略 | `{ approvalChain[]{level, approvers[]}, termsOfUse, termsVersion }` | 确认后的订阅配置 | 003 |
| PUT | `/assets/{id}/guardrail` | 绑定护栏模板 | `{ guardrailTemplateId }` | `{ guardrailTemplateId, templateName, status }` | 003 |
| POST | `/assets/{id}/quality-check` | 触发质量门禁 | — | `{ passed, checks[]{name, result, message?} }` | 003 |

### 3.3 发布管线（004-publish）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/assets/{id}/publish` | 提交发布 | `{ version, releaseNotes, isBreaking, migrationGuide? }` | `{ publishFlowId, status: "pending", evaluationId? }` | 004 |
| POST | `/assets/{id}/publish/light` | 轻量发布（仅更新条款） | `{ termsOfUse, termsVersion }` | `{ version, publishedAt }` | 004 |
| POST | `/assets/{id}/delist` | 下架 | `{ reason }` | `{ status: "delisted", delistedAt }` | 004 |
| POST | `/assets/{id}/relist` | 重新上架 | — | `{ publishFlowId, status: "pending" }` | 004 |
| DELETE | `/assets/{id}` | 软删除 | — | `204 No Content` | 004 |

### 3.4 订阅引擎（002-marketplace）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/subscriptions` | 申请订阅 | `{ assetId, agreedTermsVersion }` | `{ id, status: "pending", approvalChain[] }` | 002 |
| GET | `/subscriptions` | 我的订阅列表 | `?page, size, status?` | `{ items[]{id, assetId, assetName, status, subscribedAt}, total }` | 002 |
| GET | `/subscriptions/{id}` | 订阅详情 | — | `{ id, assetId, status, approvalProgress[]{level, approver, result, at}, subscribedAt }` | 002 |
| POST | `/subscriptions/{id}/cancel` | 取消申请 | — | `{ status: "cancelled" }` | 002 |
| POST | `/subscriptions/{id}/unsubscribe` | 退订 | — | `{ status: "unsubscribed" }` | 002 |
| GET | `/assets/{id}/subscriptions` | 资产订阅列表（Owner） | `?page, size, status?` | `{ items[]{subscriptionId, userId, userName, status, subscribedAt}, total }` | 002 |
| POST | `/subscriptions/{id}/approve` | 审批通过 | `{ comment? }` | `{ status, currentLevel }` | 002 |
| POST | `/subscriptions/{id}/reject` | 审批拒绝 | `{ reason }` | `{ status: "rejected" }` | 002 |

### 3.5 凭据管理（007-credential）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/pats` | 签发 PAT | `{ name, scopes[], expiresAt? }` | `{ id, name, token(仅返回一次), scopes[], expiresAt }` | 007 |
| GET | `/pats` | 我的 PAT 列表 | — | `{ items[]{id, name, scopes[], lastUsedAt, expiresAt, createdAt} }` | 007 |
| DELETE | `/pats/{id}` | 吊销 PAT | — | `204 No Content` | 007 |
| PUT | `/assets/{id}/service-credentials` | 配置资产级服务凭据 | `{ credentialType, credentials{} }` 密钥值加密存入 Key Vault | `{ credentialType, maskedValue, updatedAt }` | 007 |
| GET | `/credentials/personal` | 个人出站凭据列表 | — | `{ items[]{targetType, targetId?, maskedValue, updatedAt} }` | 007 |
| PUT | `/credentials/personal/{type}` | 设置个人出站凭据 | `{ credentials{} }` type: nexus\|外部服务标识 | `{ type, maskedValue, updatedAt }` | 007 |
| DELETE | `/credentials/personal/{type}` | 删除个人出站凭据 | — | `204 No Content` | 007 |
| GET | `/credentials/personal/nexus` | 个人 Nexus PAT 列表（有序） | — | `{ items[]{id, name, maskedValue, enabled, availableModels[], updatedAt} }` | 007 |
| PUT | `/credentials/personal/nexus` | 设置个人 Nexus PAT（有序列表） | `{ pats[]{name, token, enabled} }` | `{ items[]{id, name, maskedValue, enabled, availableModels[]} }` 保存后自动检测可用模型 AC-11 | 007 |
| POST | `/credentials/personal/nexus/refresh` | 手动刷新 Nexus 模型可用性快照 | — | `{ items[]{id, name, enabled, availableModels[]} }` | 007 |
| POST | `/credentials/resolve-asset` | `[内部]` 资产凭据解析（gateway 调用） | `{ assetId, userId }` | `{ resolved, credential{type, token}, source: "asset_service"\|"personal", targetEndpoint }` | 007 |
| POST | `/credentials/resolve-model` | `[内部]` 模型凭据解析（AI SDK 调用） | `{ userId }` | `{ resolved, credential{type, token}, source: "personal"\|"platform_default", availableModels[] }` | 007 |

### 3.6 护栏模板管理（006-guardrail）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/guardrail-templates` | 模板列表 | `?page, size, enabled?` | `{ items[]{id, name, sensitivity, side, enabled, boundAssetCount}, total }` | 006 |
| GET | `/guardrail-templates/{id}` | 模板详情 | — | `{ id, name, description, sensitivity, side: "input"\|"output"\|"both", rules[], enabled, boundAssets[] }` | 006 |
| POST | `/guardrail-templates` | 创建模板（Admin） | `{ name, description?, sensitivity: 0-100, side, rules[] }` | `{ id, ...创建后的模板 }` | 006 |
| PUT | `/guardrail-templates/{id}` | 更新模板（Admin） | `{ name?, description?, sensitivity?, side?, rules[]? }` | 更新后的模板对象 | 006 |
| POST | `/guardrail-templates/{id}/enable` | 启用模板 | — | `{ id, enabled: true }` | 006 |
| POST | `/guardrail-templates/{id}/disable` | 禁用模板 | — | `{ id, enabled: false }` | 006 |

### 3.7 通知（009-notification）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/notifications` | 通知列表 | `?page, size, read?` | `{ items[]{id, type, title, body, read, relatedAssetId?, createdAt}, total }` | 009 |
| GET | `/notifications/unread-count` | 未读数 | — | `{ count }` | 009 |
| POST | `/notifications/read` | 批量标记已读 | `{ ids[] }` | `{ updatedCount }` | 009 |
| POST | `/notifications` | `[内部]` 发送通知 | `{ type, recipientIds[], title, body, relatedAssetId?, metadata? }` | `{ notificationIds[] }` | 009 |

### 3.8 管理后台（008-admin）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| GET | `/admin/assets` | 治理中心：资产概览 | `?page, size, status?, keyword?` | `{ items[]{id, name, type, owner, status, outboundEnabled, subscriberCount}, total }` | 008 |
| POST | `/admin/assets/{id}/disable-outbound` | 禁用出站调用 | `{ reason }` | `{ outboundEnabled: false, disabledAt }` | 008 |
| POST | `/admin/assets/{id}/enable-outbound` | 恢复出站调用 | — | `{ outboundEnabled: true }` | 008 |
| PUT | `/admin/assets/{id}/reassign-owner` | 孤儿资产重新指派 | `{ newOwnerId }` | `{ ownerId, ownerName }` | 008 |
| GET | `/admin/native-tools` | 原生工具配置列表 | — | `{ items[]{id, name, type, endpoint, authConfigured} }` | 008 |
| PUT | `/admin/native-tools/{id}` | 更新原生工具配置 | `{ endpoint?, authConfig?{} }` | 更新后的工具对象 | 008 |
| GET | `/admin/platform-resources` | 平台资源列表 | `?type?` | `{ items[]{id, type: "milvus"\|"pgvector"\|..., name, endpoint, scope, available} }` | 008 |
| POST | `/admin/platform-resources` | 注册平台资源 | `{ type, name, endpoint, credentials{}, scope? }` | `{ id, probeResult }` | 008 |
| PUT | `/admin/platform-resources/{id}` | 更新平台资源 | `{ name?, endpoint?, credentials?{}, scope? }` | 更新后的资源对象 | 008 |
| DELETE | `/admin/platform-resources/{id}` | 注销平台资源 | — | `204 No Content` | 008 |
| GET | `/admin/evaluation-config` | 测评开关状态 | — | `{ blockingEnabled }` | 008 |
| PUT | `/admin/evaluation-config` | 切换测评开关 | `{ blockingEnabled }` | `{ blockingEnabled }` | 008 |
| GET | `/admin/recommended-slots` | 推荐位列表 | — | `{ slots[]{position, assetId?, assetName?} }` | 008 |
| PUT | `/admin/recommended-slots` | 更新推荐位 | `{ slots[]{position, assetId} }` | 更新后的推荐位列表 | 008 |
| GET | `/admin/users` | 用户列表 | `?page, size, keyword?` | `{ items[]{userId, name, email, roles[], lastLoginAt}, total }` | 008 |
| GET | `/admin/roles` | 角色-功能映射 | — | `{ roles[]{name, features[]} }` | 008 |
| GET | `/admin/model-settings` | 模型设置 | — | `{ settings[]{type: "chat"\|"multimodal"\|"reranker"\|"embedding", modelId, provider, hasDefaultCredential} }` | 008 |
| PUT | `/admin/model-settings/{type}` | 更新模型设置 | `{ modelId, provider, defaultCredential?{} }` | 更新后的模型设置 | 008 |

### 3.9 文件服务（横切）

| 方法 | 路径 | 描述 | 请求要点 | 响应要点 | Spec |
|------|------|------|---------|---------|------|
| POST | `/files/upload-url` | 获取直传 SAS URL | `{ fileName, contentType, size }` | `{ uploadUrl, fileId, expiresAt }` | 000 |
| POST | `/files` | 注册文件元数据 | `{ fileId, blobPath, size, contentType, md5? }` | `{ id, fileName, size, createdAt }` | 000 |
| GET | `/files/{id}/download-url` | 获取下载 SAS URL | — | `{ downloadUrl, expiresAt }` | 000 |

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
