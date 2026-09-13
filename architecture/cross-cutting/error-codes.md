# 横切规范：响应格式、错误码与幂等

> 状态：成功响应包络（§1）Accepted（ADR-006）；错误响应与错误码规范 Proposed（ADR-002）。所有服务共同遵守。
> 关联 ADR：001-service-split, 006-api-response-envelope

## 1. 成功响应格式（ApiResponse 包络）

所有 REST 接口的成功响应**必须**使用以下统一 `ApiResponse` 包络（SSE 流式端点除外）：

```json
{
  "code": "0",
  "message": "success",
  "data": { ... },
  "traceId": "abc123-def456",
  "timestamp": "2026-08-21T10:00:00Z"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | ✅ | 成功固定为 `"0"`；错误时为 `{SERVICE}-{NNNN}` 格式，类型统一为字符串 |
| message | string | ✅ | 成功固定为 `"success"`；可附带业务提示文案 |
| data | object / array / null | ✅ | 业务数据载荷；无返回值时为 `null` |
| traceId | string | ✅ | OpenTelemetry trace ID，与错误响应一致 |
| timestamp | string | ✅ | 响应时间（ISO 8601 UTC），与错误响应一致 |

分页场景 `data` 内嵌标准分页结构：

```json
{
  "code": "0",
  "message": "success",
  "data": {
    "records": [ ... ],
    "total": 128,
    "page": 1,
    "pageSize": 20
  },
  "traceId": "...",
  "timestamp": "..."
}
```

| 分页字段 | 类型 | 说明 |
|----------|------|------|
| records | array | 当前页数据列表 |
| total | integer | 总记录数 |
| page | integer | 当前页码（1-based） |
| pageSize | integer | 每页条数 |

## 2. 错误响应格式（RFC 9457 Problem Details）

所有 REST 接口的错误响应**必须**使用以下 JSON 结构（基于 RFC 9457）：

```json
{
  "code": "ASSET-4003",
  "message": "该资产已被下架",
  "detail": "资产 agent-xyz 于 2026-08-10 被 Owner 下架，下架原因：安全漏洞修复中",
  "traceId": "abc123-def456",
  "timestamp": "2026-08-13T10:30:00Z",
  "path": "/v1/assets/agent-xyz/invoke"
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| code | ✅ | 错误码，格式 `{SERVICE}-{NNNN}`，见下方编码规则 |
| message | ✅ | 面向用户的简短错误描述（中文，可直接展示在前端） |
| detail | ❌ | 面向开发者的详细信息（可含上下文变量） |
| traceId | ✅ | OpenTelemetry trace ID，用于链路追踪 |
| timestamp | ✅ | 错误发生时间（ISO 8601 UTC） |
| path | ❌ | 触发错误的请求路径 |

HTTP 状态码与 code 的映射：code 的第一位数字对应 HTTP 状态码类别（4xxx→4xx, 5xxx→5xx）。

## 3. 错误码编码规则

### 格式

```
{SERVICE_PREFIX}-{CATEGORY}{SEQUENCE}
```

- **SERVICE_PREFIX**：服务缩写，大写，3–6 字母
- **CATEGORY**：一位数字表示错误类别
- **SEQUENCE**：三位数字表示具体错误

### 服务前缀注册表

| 前缀 | 服务 | 说明 |
|------|------|------|
| GW | grc-api-gateway | 网关层错误（限流/路由/护栏/流式） |
| AUTH | grc-auth-service | 认证错误（SSO/Token/PAT） |
| ASSET | grc-mgmt-service (asset-catalog) | 资产目录 |
| SUB | grc-mgmt-service (subscription) | 订阅引擎 |
| PUB | grc-mgmt-service (publish) | 发布链路 |
| GUARD | grc-mgmt-service (guardrail-template) | 护栏模板管理 |
| CRED | grc-mgmt-service (credential) | 密钥库/凭据 |
| ADMIN | grc-mgmt-service (admin) | 管理后台 |
| NOTIFY | grc-mgmt-service (notification) | 通知 |
| FILE | grc-mgmt-service (file) | 文件管理 |
| CHAT | grc-agent-service | 对话引擎 |
| EVAL | grc-evaluation-service | 测评 |
| KB | grc-knowledge-engine | 知识引擎 |
| PARSE | grc-parser-engine | 文档解析 |
| MCP | grc-mcp-server | 平台原生工具 |

### 错误类别

| 类别码 | 含义 | HTTP 状态码范围 |
|--------|------|-----------------|
| 1 | 参数校验/格式错误 | 400 |
| 2 | 认证/鉴权失败 | 401 / 403 |
| 3 | 资源不存在 / 状态冲突 | 404 / 409 |
| 4 | 业务规则阻断 | 422 |
| 5 | 限流/配额 | 429 |
| 9 | 内部错误/依赖不可达 | 500 / 502 / 503 |

### 示例

| 错误码 | HTTP | 含义 |
|--------|------|------|
| GW-2001 | 401 | Token 过期或无效 |
| GW-2002 | 403 | PAT 权限范围不包含该资源 |
| GW-4001 | 422 | 输入侧护栏命中，拒绝请求 |
| GW-4002 | 422 | 输出侧护栏命中，回答已拦截 |
| GW-5001 | 429 | 请求被限流 |
| GW-9001 | 502 | 护栏检测服务不可达 |
| ASSET-3001 | 404 | 资产不存在 |
| ASSET-3002 | 409 | 该资产已被下架 |
| ASSET-3003 | 409 | 该资产正在发布中，请先中止发布 |
| ASSET-4001 | 422 | 质量门控未通过（附未通过项列表） |
| ASSET-4002 | 422 | 负责人冗余不满足 |
| SUB-3001 | 404 | 订阅申请不存在 |
| SUB-4001 | 422 | 该资产负责人暂不可用，暂不接受订阅 |
| SUB-4002 | 422 | 使用条款未勾选同意 |
| PUB-3001 | 409 | 该资产已下架，不可直接发布 |
| PUB-4001 | 422 | 准入测评未通过且阻断开关已开启 |
| PUB-4002 | 422 | 所绑护栏模板当前未启用 |
| CRED-3001 | 404 | 凭据不存在 |
| CRED-4001 | 422 | 按人鉴权资产未配置个人凭据 |
| CRED-4002 | 422 | 凭据探测失败（附目标服务返回信息） |
| CRED-9001 | 503 | Key Vault 不可达 |
| ADMIN-1002 | 400 | 公共目录创建时审批人不能为空 |
| ADMIN-2002 | 403 | 无目录管理权限 |
| ADMIN-3002 | 404 | 目录不存在 |
| ADMIN-4002 | 409 | 同级目录重名 |
| ADMIN-4003 | 422 | 目录下存在子目录，禁止删除 |
| ADMIN-4004 | 422 | 目录下存在知识库，禁止删除 |
| ADMIN-4005 | 422 | 已存在知识库，不能新建子目录 |
| CHAT-3001 | 409 | 该资产已被下架，无法发送消息 |
| CHAT-3002 | 409 | 该资产的出站调用已被平台停用 |
| CHAT-4001 | 422 | 该资产服务暂时不可用（重试后仍失败） |
| CHAT-9001 | 502 | Nexus LLM 调用失败 |
| KB-1001 | 400 | 文件格式不在白名单 |
| KB-1002 | 400 | 文件超过 40MB 上限 |
| KB-1003 | 400 | 请求参数不符合要求 |
| KB-3001 | 404 | 知识库不存在 |
| KB-3002 | 409 | 知识库状态为草稿，不可挂载 |
| KB-3003 | 409 | 同一目录下知识库名称已存在 |
| KB-3004 | 404 | Pipeline 构建任务不存在 |
| KB-3005 | 409 | 文档已有活动构建任务 |
| KB-4001 | 422 | 同一知识库已有构建任务进行中（构建互斥） |
| KB-4002 | 422 | 「可用」状态的知识库须先停用方可删除 |
| KB-4003 | 422 | 知识库管线配置无效 |
| KB-4004 | 403 | 无权限在目标目录创建知识库 |
| KB-4005 | 422 | 已存在子目录，不能新建知识库（知识库仅允许建在叶子目录） |
| KB-9001 | 500 | 知识引擎内部错误 |
| PARSE-1001 | 400 | 解析请求、幂等键、cursor、Range、来源完整性或快照标识无效 |
| PARSE-1002 | 400 | 文件媒体类型不受所选解析器支持 |
| PARSE-3001 | 404 | 解析任务或解析资产不存在 |
| PARSE-3002 | 409 | 解析结果未就绪、任务不可取消或确认结果冲突 |
| PARSE-3003 | 410 | 解析结果已确认或已按 TTL 清理 |
| PARSE-3004 | 409 | 幂等键已用于不同请求或幂等记录冲突 |
| PARSE-4001 | 422 | 请求的解析器能力当前未部署 |
| PARSE-4002 | 422 | 必需的本地图片描述能力不可用或执行失败 |
| PARSE-4003 | 422 | 解析结果超过页数、元素、资产或 Markdown 契约上限 |
| PARSE-9001 | 503 | 来源访问授权失效或来源不可读 |
| PARSE-9002 | 503 | 解析执行超时 |
| PARSE-9004 | 500 | 解析器未分类内部错误或不安全清理被拒绝 |
| EVAL-9001 | 503 | 测评执行失败（基础设施原因） |
| FILE-1001 | 400 | 文件大小超过允许上限 |
| FILE-3001 | 404 | file_id 不存在 |
| AUTH-2001 | 401 | SSO Token 无效 |
| AUTH-2002 | 401 | PAT 已过期 |
| AUTH-2003 | 403 | 账号已被 Alice 停用 |

## 4. 网关层错误包装规则

- 网关代理后端时，若后端返回标准错误格式，**原样透传**给前端（保留 code/message/detail）。
- 若后端返回非标准格式（裸 500/无 body），网关包装为 `GW-9002`（上游服务异常）并附 traceId。
- 护栏拦截产生的错误由网关自己生成（`GW-4001`/`GW-4002`），不透传后端。

## 5. 前端错误展示规则

| code 类别 | 前端行为 |
|-----------|----------|
| *-1xxx | 表单字段级校验提示 |
| *-2xxx | 跳转登录 / 提示无权限 |
| *-3xxx | 提示资源状态变更，引导刷新或跳转 |
| *-4xxx | 展示 message 字段（业务规则提示） |
| *-5xxx | 展示限流提示，建议稍后重试 |
| *-9xxx | 展示"系统繁忙"通用提示 + traceId（便于报障） |

## 6. 幂等约定

- 写操作的幂等键放 **HTTP Header**：`X-Idempotency-Key: {UUID}`。
- 服务端以 `(user_id, idempotency_key, endpoint)` 为唯一约束，24 小时内重复提交返回首次结果。
- 事件消费者必须幂等（Azure Service Bus 至少一次投递假设）——以 `message_id` 做去重。

## 7. 重试与超时

| 场景 | 默认超时 | 默认重试 | 说明 |
|------|----------|----------|------|
| 网关 → 后端服务 | 30s | 0 次 | 后端超时由后端自己控制 |
| 网关 → 护栏检测服务 | 10s | 1 次 | 护栏不可达时默认拒绝（GW-9001） |
| 网关 → 外部资产 Agent/MCP | 配置值（默认 30s，Owner 可配 5–120s） | 配置值（默认 1 次，0–3 次） | 见 PRD §9.10 |
| agent-service → knowledge-engine | 15s | 1 次 | 检索不可达时回答不含知识库证据 |
| knowledge-engine → parser-engine | 10min/单文档 | 1 次 | 见 PRD §9.10 构建单阶段超时 |
| mgmt-service → Key Vault | 5s | 2 次 | Key Vault 不可达降级使用 Redis 缓存 |
| mgmt-service → Alice | 10s | 1 次 | Alice 不可达时角色创建失败返回 ADMIN-9001 |
