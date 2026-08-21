# ADR-006: 统一成功响应包络（ApiResponse）规范

> 状态：Proposed
> 日期：2026-08-21 · 决策者：@nzhang · 关联 spec：`specs/000-platform`

## 背景

ADR-002 与 `cross-cutting/error-codes.md` 已规范了错误响应格式（RFC 9457 Problem Details），
但成功响应目前仅在 `api-landscape.md` 提了一句"服务统一返回 `ApiResponse` 包络，核心业务字段位于 `data`"，
无正式 schema 与字段定义。实际示例中已出现不一致：部分端点返回裸对象，部分使用 `{ data: null }`，
字段命名与错误格式也不对称。需统一成功响应格式以避免前端适配碎片化。

## 决策

所有 REST 接口的成功响应采用统一 `ApiResponse` 包络：

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

SSE 流式端点不套 `ApiResponse`，仅限 JSON 响应使用。

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 裸资源体（RESTful 纯粹派） | 语义更 REST、HTTP 状态码自解释 | 前端需按 HTTP 状态码区分成功/失败，分页元数据无统一位置 | 已有多个端点使用包络模式，且前端团队倾向统一解析器 |
| 共用错误格式字段（code 为字符串错误码 / "0"） | 成功与错误结构完全对称 | 错误码已固定为 `{SERVICE}-{NNNN}` 字符串格式，成功场景强行复用会导致前端解析逻辑复杂化 | 成功 code 固定为 `"0"` 已足够区分，无需强制业务前缀 |

## 影响

- 受影响服务：全部（统一包络为横切规范）
- 契约影响：`contracts/openapi/*.yaml` 的成功响应 schema 需引用共享 `ApiResponse` 定义
- 迁移/回滚：已有端点裸返回的需在 P0 期间统一包装，改动仅限响应序列化层

## 后果

### 正面
- 前端可用单一解析器处理所有成功响应
- traceId/timestamp 在成功与错误响应中均可追踪
- 分页结构标准化，减少各服务自行发明

### 负面
- 每个响应增加 ~50 字节开销（code/message/traceId/timestamp）
- 与 RESTful 纯粹派设计理念有偏离

### 风险
- 若未来需要流式响应（SSE），包络格式不适用 → SSE 端点不套 ApiResponse，仅限 JSON 响应使用
