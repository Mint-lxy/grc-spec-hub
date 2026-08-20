# Implementation Plan: 对话工作台（平台 Chat）

**Branch**: `001-conversation` | **Date**: 2026-08-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-conversation/spec.md`

## Summary

P0 范围聚焦 spec.md 中"平台 Chat"部分（AC-1~AC-14、AC-18~AC-26 的核心路径）：用户与平台自有的
Chat 对话，可挂载知识库检索（带引用证据）、平台原生工具会在对话中被模型自主调用，回答流式返回并
支持中止/重新生成。资产 Agent 透传会话（AC-15~17）沿用平台网关代理透传能力，不在本阶段
grc-agent-service 侧新增开发。

**技术方案**（关键决策，详见"涉及服务"与下方说明）：

- grc-agent-service 是**无状态推理执行引擎**，不建业务表；会话（session）、知识库挂载关系、
  消息历史三类业务数据的权威归 **grc-mgmt-service**。
- grc-agent-service 收到一次"发消息"请求后，先同步调用 grc-mgmt-service 的内部接口取
  会话上下文（挂载的知识库 ID、历史消息），再调用 grc-knowledge-engine 做检索、
  调用 grc-mcp-server 做平台原生工具、调用 LLM 网关做推理，生成完成后经内部接口把这一轮
  问答回写给 grc-mgmt-service 持久化。
- 该技术方案已在本地 PoC 骨架验证阶段验证过可行性（function-calling 循环、SSE 流式输出、
  中止生成、知识库检索集成，均用真实 LLM 网关联调过），仅数据持久化归属这一点在本 plan 里
  做了调整（PoC 阶段是 grc-agent-service 自建 Postgres 表，现改为无状态、数据权威收敛到
  grc-mgmt-service），编排引擎本身的技术选型不变。

## Technical Context

**Language/Version**: Python 3.11+

**Primary Dependencies**: FastAPI、httpx（服务间调用）、redis.asyncio（技术态缓存，非业务数据）、
sse-starlette（SSE 流式响应）、structlog（结构化日志）

**Storage**: 无业务数据库（Postgres/MySQL 等）。Redis 仅用于技术态缓存
（进行中生成的中止标记 `cancel_registry`，可选的短期 prompt 拼装缓存），丢失不影响正确性。

**Testing**: pytest + pytest-asyncio；外部依赖（LLM 网关、grc-mgmt-service、grc-knowledge-engine、
grc-mcp-server）在测试中用内存 fake / `httpx.MockTransport` 隔离，不依赖真实网络。

**Target Platform**: Linux 容器（Kubernetes / 云原生部署），本地开发用 uvicorn 直跑。

**Project Type**: web-service（单体 FastAPI 服务，无前端）。

**Performance Goals**: `[待确认]`（P0 尚无正式 SLA，参考同类 LLM 网关代理服务，首字节延迟
< 2s、SSE 流式增量间隔 < 500ms 作为工作假设，待压测确认）。

**Constraints**: 中止生成（cancel）需要在 SSE 连接读取协程内检测，客户端断开连接不保证服务端
已停止生成（PoC 阶段已验证，见 spec 001 AC-24 relate）；grc-agent-service 无状态意味着多实例
部署时"中止某条正在生成的流"必须路由到处理该流的具体实例，方案见"待评审确认项"。

**Scale/Scope**: `[待确认]`（P0 用户规模与并发量尚未给出，暂按"单请求单流、多实例水平扩展"设计，
不假设具体并发数）。

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-agent-service | 新增服务 + 新增端点 | 新增 `POST /chat/sessions/{id}/messages`（SSE）、`.../regenerate`、`POST /chat/sessions/{id}/cancel` 三个端点；无状态，不建业务表 |
| grc-mgmt-service | 新增端点（chat 会话子域） | 新增会话 CRUD（`/mgmt/chat/sessions*`）、知识库挂载管理（`.../knowledge-mounts`）、两个供 grc-agent-service 调用的内部接口（`GET .../context`、`POST .../messages`）；知识库挂载时复用其已有的 RBAC 校验（`/mgmt/internal/check`，`CATALOG` 类型） |
| grc-knowledge-engine | 消费方（新增调用方） | grc-agent-service 直接调用 `POST /knowledge/retrievals` 做多知识库检索（见 service-map：grc-agent-service 依赖 grc-knowledge-engine） |
| grc-mcp-server | 消费方（新增调用方） | grc-agent-service 调用平台原生工具（Confluence / SharePoint-OneDrive / 数据平台 / Web），协议遵循 MCP（JSON-RPC），非本 plan 新增 REST 契约范围 |
| grc-api-gateway | 路由透传 | 新增路由把 `/api/v1/chat/**` 转发到 grc-agent-service；网关侧的护栏检测、凭据注入、审计沿用其既有能力，本 plan 不改网关契约 |

> 服务清单与依赖方向以 `architecture/service-map.md` 为准；上述依赖方向（agent → mgt-service /
> knowledge-engine / mcp-server）与 service-map 现状一致，未新增依赖，无需改地图。

## 契约影响（Contract Impact · 必填）

| 契约 | 类型 | 新增/变更/废弃 | 是否破坏性 | 消费方 |
|------|------|----------------|-----------|--------|
| `contracts/openapi/grc-agent-service.yaml` | openapi | 新增（首个版本） | 否 | grc-api-gateway |
| `contracts/openapi/grc-mgmt-service.yaml` | openapi | 新增（首个版本，本次只落地 chat 会话子域路径，见文件内说明；该服务其余模块——marketplace/RBAC/vault/文件——由对应 feature 后续补齐） | 否 | grc-api-gateway、grc-agent-service（仅消费本次新增的两个内部接口） |

对应契约草案 PR：`[待创建]`（本地已起草，等待人审后提 PR）。

两份契约均为**首次落地**，不存在旧版本，不涉及破坏性判定；`grc-mgmt-service.yaml` 后续会被其他
feature（002~008）持续追加路径，属于正常的非破坏性扩展。

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 自查结果 |
|------|---------|
| 一、Spec 先行 | ✅ 本 plan 追溯到 `specs/001-conversation/spec.md`（已有 WHAT/WHY 与验收标准） |
| 二、契约先行 | ✅ 本 plan 同批产出 `contracts/openapi/grc-agent-service.yaml` 与 `grc-mgmt-service.yaml`（chat 子域）草案，代码实现将只引用合并后的版本 |
| 三、测试先行 | ⚠️ 核心编排逻辑（function-calling 循环、流式输出、中止生成、知识库检索集成）已在本地骨架验证阶段用真实 LLM 网关联调过，但当时是"先实现后补测试"，未严格遵循红-绿；转正实现阶段将按新契约重新走测试先行（先写失败测试，覆盖新的"无状态+内部接口回写"模型），不直接照搬 PoC 测试 |
| 四、服务边界 | ✅ grc-agent-service 与 grc-mgmt-service 之间只通过本次新增的契约接口交互，不直连数据库；grc-agent-service 不再自建业务表，从架构上消除了"服务边界"违规的可能性 |
| 五、记忆义务 | ⏳ 待本 spec 的 tasks.md 最后一项"更新 Project Memory"完成（本次 plan 阶段尚未产出 tasks.md） |
| 六、人类守门点 | ⏳ 本 plan.md 与两份契约草案均待人审合并，未视为已完成 |

## Project Structure

### Documentation (this feature)

```text
specs/001-conversation/
├── spec.md              # 已有
├── plan.md              # 本文件
└── tasks.md             # 待 /speckit.tasks 产出（下一步）
```

### Source Code (repository root: grc-agent-service)

```text
app/
├── main.py                    # FastAPI app 入口
├── config.py                  # 配置（LLM 网关、grc-mgmt-service/grc-knowledge-engine/grc-mcp-server 地址）
├── api/
│   └── chat.py                # POST .../messages、.../regenerate、.../cancel 三个端点
├── orchestrator.py            # function-calling 循环、流式生成、中止信号检查
├── services/
│   ├── llm_client.py          # LLM 网关调用（经 grc-ai-sdk，若已确定归属）
│   ├── mgt_client.py          # 调用 grc-mgmt-service 的 context/messages 内部接口
│   ├── knowledge_client.py    # 调用 grc-knowledge-engine 检索
│   ├── mcp_client.py          # 调用 grc-mcp-server 平台原生工具
│   └── cancel_registry.py     # 技术态缓存：进行中生成的中止标记（Redis 或进程内，见待评审确认项）
└── guardrails/
    └── hooks.py                # 输出侧全文缓冲检测钩子（AC-18/19，对接网关或自行实现待确认）

tests/
├── test_chat_api.py
├── test_orchestrator.py
├── test_mgt_client.py
├── test_knowledge_client.py
└── test_mcp_client.py
```

**Structure Decision**: 沿用本地骨架验证阶段已验证过的目录结构（FastAPI 单体服务 + 分层
`api/`/`services`/`orchestrator`），去掉 `db.py`/`session_repo.py`/`sessions.py`（会话管理已挪至
grc-mgmt-service），新增 `mgt_client.py` 承担"取上下文 + 回写结果"的内部接口调用。

## Complexity Tracking

无违反 Constitution Check 的项，本节不适用。

## 待评审确认项（承接 `specs/000-platform/api-landscape.md`）

- [ ] 生成中途失败/被中止时，`POST /mgmt/internal/chat/sessions/{id}/messages` 是否仍要回写部分内容
- [ ] `GET /mgmt/internal/chat/sessions/{id}/context` 返回的历史消息是否需要长度/条数上限
- [ ] grc-agent-service 完全无状态、多实例部署下，`cancel` 请求如何路由到正确处理该 SSE 流的实例
      （网关按 sessionId 一致性哈希 / grc-agent-service 间共享 Redis 广播中止信号，两个方向待架构确认）
- [ ] AI 模型调用是否统一经 `grc-ai-sdk`（ADR-003 提到但状态为 Proposed）；若是，`services/llm_client.py`
      需要基于 `grc-ai-sdk` 实现，而不是本地 PoC 里直连 OpenAI 兼容网关的方式
- [ ] 输出侧护栏"全文缓冲检测后按段回放"（AC-18/19）具体由 grc-agent-service 自己实现，还是网关统一处理
      （spec.md 背景提到"经平台网关的护栏检测"，倾向网关侧，但 grc-agent-service 是否需要感知护栏结果
      以决定是否回写"已拦截"占位文本，待确认）
