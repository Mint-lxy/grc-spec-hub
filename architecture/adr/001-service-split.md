# ADR-001: 服务拆分——以 C4 容器为基线的八服务架构

> 状态：Proposed
> 日期：2026-08-13 · 决策者：@todo-owner · 关联 spec：`specs/000-platform`

## 背景

PRD v1.0 的建议模块划分（§10.1）列出了 10 个逻辑模块（对话/资产目录/订阅/创建/发布/知识/测评/护栏/密钥库/管理后台）。
团队在 C4 容器架构设计中将其收敛为 8 个可独立部署的服务（含前端），理由是：

1. **逻辑模块 ≠ 部署单元**——订阅、创建、发布、密钥库、护栏模板管理、通知等逻辑模块
   共享同一份资产数据模型与状态机，强制拆为独立进程会引入大量跨服务事务与数据同步。
2. **Python/Java 双栈分界**——对话编排与知识管线依赖 Python 生态（LangChain/向量库 SDK/解析器），
   管理侧（资产 CRUD/订阅审批/权限映射）适合 Java/Spring 生态，两栈各聚一个服务。
3. **GPU 资源隔离**——文档解析需要 GPU，独立为 grc-parser-engine 可按需扩缩。

---

## 决策

### D1 — 服务清单与职责

采用以下八服务 + 前端的架构（对应 C4 容器图）：

| 服务 | 语言 | 职责（对应 spec） | 说明 |
|------|------|-------------------|------|
| grc-ai-portal | TypeScript/React | 全部用户界面 | SPA |
| grc-api-gateway | Java | 路由/限流/鉴权转发/护栏代理/凭据解析/审计/流式缓冲与回放 | 网关层 |
| grc-auth-service | Java | Alice SSO 对接、Token 颁发与校验、PAT 签发与吊销 | 认证 |
| grc-mgmt-service | Java | 资产目录/订阅引擎/创建向导/发布链路/护栏模板管理/密钥库（PAT+个人凭据）/管理后台/通知 | "大后端" |
| grc-agent-service | Python | 对话编排（Chat agent-runtime + 资产透传）、MCP Tool 调用、LLM 推理调度 | 对话 |
| grc-evaluation-service | Python | 发布准入测评任务执行（三类检测）、结果计算与回写 | 异步任务 |
| grc-knowledge-engine | Python | 目录树/知识库 CRUD+状态机/四通道导入/四阶段构建/向量检索/开放接口 | 知识 |
| grc-parser-engine | Python (GPU) | Docling/MinerU 文档解析执行 | GPU 隔离 |
| grc-mcp-server | Python/TS | 平台原生工具（M365/Confluence/数据平台/Web） | monorepo |

### D2 — grc-mgmt-service 内部模块化

保持一个部署单元，内部按 **domain package** 隔离：

| 内部模块 | 对应 spec | 核心数据实体 |
|----------|-----------|-------------|
| asset-catalog | 002-marketplace | Asset, AssetVersion, AssetConfig |
| subscription | 002-marketplace | SubscriptionRequest, ApprovalChain, Subscription |
| creation | 003-asset-creation | CreationWizardState, QualityGate |
| publish | 004-publish | PublishFlow, DraftRevision, EvaluationResult |
| guardrail-template | 006-guardrail | GuardrailTemplate, GuardrailRule |
| credential | 007-credential | PAT, PersonalCredential, AssetServiceCredential |
| admin | 008-admin | PlatformResource, RoleMapping, ModelConfig, RecommendSlot |
| notification | 009-notification | Notification, NotificationEvent |
| file | 横切（各 spec 共用） | SysFile（元数据 + Blob 路径映射） |

模块间通过进程内事件（Spring ApplicationEvent）通信，不做跨数据库写入。
若后续需拆分，通知模块最先独立（事件驱动，天然解耦）。

### D3 — 护栏运行时架构

```
前端 → grc-api-gateway ─gRPC→ 护栏检测服务（云原生或自建）
                        │
                        └→ 缓冲全文 → 检测通过 → 按段回放给前端
                           检测命中 → 返回「已拦截」
```

| 决策点 | 结论 |
|--------|------|
| 模板 CRUD | grc-mgmt-service 的 PostgreSQL |
| 运行时检测 | grc-api-gateway 经 **gRPC** 调用外部护栏检测服务 |
| 护栏检测服务 | `[待确认]` 两种候选：① 云原生 Guard 服务（Azure AI Content Safety 等）② 自建 guardrail-service |
| 全文缓冲与回放 | 在 grc-api-gateway 内完成（PRD §9.5 要求网关缓冲→检测→回放，逻辑不可分离） |
| 模板热加载 | grc-api-gateway 从 mgmt-service 拉取模板缓存（Redis），模板变更时 mgmt 发 invalidation 事件 |

### D4 — 凭据解析

| 决策点 | 结论 |
|--------|------|
| 运行时凭据解析 | **grc-api-gateway** 内执行——路由时已知目标资产，就地从 Key Vault 取凭据并注入出站请求 |
| 资产级服务凭据存储 | 资产属性，mgmt-service 管理其元数据，密钥值加密存入 Key Vault |
| 个人出站凭据存储 | mgmt-service 管理，密钥值加密存入 Key Vault |
| 凭据缓存 | Redis（TTL 5min），Key Vault 不可达时降级使用缓存 |

### D5 — 知识检索调用链

```
用户发问 → grc-api-gateway → grc-agent-service
                                 │ ①查询挂载的知识库 ID
                                 │ ②同步 REST 调用 grc-knowledge-engine /search API
                                 │ ③拿到切片结果注入 prompt
                                 │ ④调用 Nexus LLM
                                 └→ 回答（含引用证据）
```

- agent-service **不直接访问 Milvus**，一切向量操作由 knowledge-engine 封装。
- knowledge-engine 对外暴露 `/v1/search`（内部用）和 `/v1/open/search`（PAT 鉴权外部用），两者共享检索逻辑。

### D6 — grc-mcp-server 部署

- **Monorepo**（一个仓库），各子模块**独立容器**部署。
- 子模块：mcp-m365-server / mcp-conf-server / mcp-dp-server / mcp-web-server。
- 网关反向代理按路径路由到不同容器（`/mcp/m365/*` → mcp-m365-server）。
- 各子模块需要获取凭据时调用 grc-auth-service 内部 API。

### D7 — 事件总线 Topic 划分

Azure Service Bus，按业务域划分 topic：

| Topic | 生产者 | 消费者 | 事件举例 |
|-------|--------|--------|----------|
| `asset-lifecycle` | grc-mgmt-service | grc-evaluation-service, grc-agent-service | 资产发布/下架/删除、出站停用 |
| `subscription` | grc-mgmt-service | (内部消费) | 订阅通过/取消/下架清除 |
| `knowledge-build` | grc-knowledge-engine | (自身 worker 消费) | 文档构建任务调度 |
| `eval-task` | grc-mgmt-service | grc-evaluation-service | 测评任务触发 |
| `notification` | grc-mgmt-service | (内部消费或未来独立通知服务) | 十三类通知事件 |

### D8 — 测评触发与结果回写

```
mgmt-service ──publish eval-task topic──→ eval-service
                                              │ 执行测评
                                              │ 完成
eval-service ──REST callback──→ mgmt-service /internal/eval/result
                                              │ 写结果 + 更新资产发布状态
```

- 触发：mgmt-service 发布 `eval-task` 消息到 Service Bus。
- 执行：eval-service 订阅并执行（调用 Nexus LLM 做裁判模型）。
- 回写：eval-service 完成后 REST 回调 mgmt-service 内部接口写入结果。

### D9 — 通知投递

- P0 轻量版：mgmt-service 内**同步写入通知表**（PostgreSQL）。
- 前端通过**轮询或 SSE** 拉取未读通知。
- 不做 WebSocket 实时推送，不做外部渠道（邮件/企业微信）。
- 通知表按 user_id + created_at 索引，90 天过期清理。

### D10 — 可观测性接入

| 服务 | 方式 |
|------|------|
| grc-agent-service | 内嵌 Langfuse SDK（trace 对话链路、token 消耗） |
| grc-evaluation-service | 内嵌 Langfuse SDK（trace 测评链路） |
| grc-knowledge-engine | 内嵌 Langfuse SDK（trace 构建与检索链路） |
| grc-api-gateway | OpenTelemetry → Langfuse（HTTP span、护栏检测耗时） |
| grc-mgmt-service | OpenTelemetry（标准 Java agent，不接 Langfuse） |

### D11 — 文件存储与 sys_file 元数据

**统一文件管理层**：平台所有文件上传（知识库文档、ZIP 包、测评报告等）经由 `sys_file` 表统一登记元数据，内部以 `file_id` 流转。

#### 存储基础设施

- 所有服务共用**同一个 Azure Blob Storage 账户**。
- 按**容器（container）隔离**：`documents`（知识库原始文档/永久）、`attachments`（临时文件 P1/有 TTL）、`exports`（测评报告 P1/有 TTL）。
- 访问经 Managed Identity，不在代码中硬编码 connection string。

#### sys_file 表设计

归属：**grc-mgmt-service** 内部 file module，共享 PostgreSQL。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 文件唯一标识，平台内部流转用 |
| blob_container | varchar | Blob 容器名（documents / attachments / exports） |
| blob_path | varchar | Blob 内完整路径（含租户/日期/原始文件名哈希） |
| original_name | varchar | 用户上传时的原始文件名 |
| content_type | varchar | MIME 类型 |
| size_bytes | bigint | 文件大小 |
| ttl | timestamp | 过期时间（null = 永久保留） |
| upload_user_id | varchar | 上传者 |
| created_at | timestamp | 上传时间 |
| deleted_at | timestamp | 软删除时间（null = 有效） |

- 业务关联由各业务表（知识库文档表、资产附件表等）自行引用 `file_id`，sys_file 不存业务语义字段。

#### 上传链路

```
前端 ──① 请求 SAS Token──→ mgmt-service（file module）
        生成 SAS Token（限容器/路径/时效/大小）
前端 ──② 直传 Blob──→ Azure Blob Storage
前端 ──③ 上传完成回调──→ mgmt-service（file module）
        校验 Blob 存在 → 写 sys_file 记录 → 返回 file_id
```

- 大文件（知识库单文件 ≤40MB、ZIP ≤500MB）走前端直传，不经后端中转。
- SAS Token 限制：单文件大小上限、指定容器与路径前缀、5 分钟有效。

#### 消费链路

```
knowledge-engine / parser-engine / eval-service
    ──① 拿 file_id 调 mgmt-service /internal/file/{id}/sas──→
    ←── 返回带时效的只读 SAS URL（默认 30min）──
    ──② 用 SAS URL 直接读 Blob──→ Azure Blob Storage
```

- 内部服务**不直接拼 Blob 路径**，统一经 mgmt-service 的内部接口获取 SAS URL。
- SAS URL 时效内可重复使用，减少对 mgmt-service 的调用频率。

#### 生命周期与清理

| 容器 | TTL 策略 | 清理方式 |
|------|----------|----------|
| documents | 永久（ttl = null） | 跟随知识库软删除或文档删除时标记 deleted_at |
| attachments | 会话结束后 24h（P1） | mgmt-service 定时任务扫描过期记录，删 Blob + 标记 deleted_at |
| exports | 7 天 | 同上 |

- 清理任务每小时执行一次，batch 处理。
- 已删除的 sys_file 记录保留 30 天后物理清除（便于排查）。

### D12 — spec ↔ 服务功能点映射（详细）

| Spec | 功能点 | 主服务 | 辅助服务 | 调用方式 |
|------|--------|--------|----------|----------|
| 001 | Chat agent-runtime（对话/知识检索/原生工具） | agent-service | knowledge-engine, mcp-server | REST 同步 |
| 001 | 资产 Agent 透传 | agent-service | api-gateway（护栏+凭据） | 网关代理 |
| 001 | 流式输出与护栏 | api-gateway | 护栏检测服务 | gRPC |
| 001 | 历史会话持久化 | agent-service | — | `[待确认]` 存储位置 |
| 002 | Marketplace 列表/搜索/详情 | mgmt-service | — | REST |
| 002 | 订阅申请与审批 | mgmt-service | — | 内部事件 |
| 002 | 创作者中心/资产控制台 | mgmt-service | — | REST |
| 003 | 创建向导/质量门控 | mgmt-service | — | REST |
| 003 | Agent Card 拉取 | mgmt-service | ext_agent | HTTP |
| 004 | 发布/版本替换/下架/重新上架 | mgmt-service | — | 内部事件 |
| 004 | 准入测评触发 | mgmt-service | eval-service | Service Bus |
| 004 | 准入测评执行 | eval-service | Nexus（裁判模型） | HTTPS |
| 005 | 目录树/建库/状态机 | knowledge-engine | auth-service（Alice） | REST |
| 005 | 四通道导入 | knowledge-engine | mcp-server（外部通道） | REST/MCP |
| 005 | 四阶段构建 | knowledge-engine | parser-engine | REST 同步 |
| 005 | 向量检索 | knowledge-engine | — | 内部 Milvus/PGVector |
| 006 | 模板 CRUD | mgmt-service | — | REST |
| 006 | 运行时检测 | api-gateway | 护栏检测服务 | gRPC |
| 007 | PAT 管理 | mgmt-service | auth-service（签发） | REST |
| 007 | 个人凭据管理 | mgmt-service | Key Vault | HTTPS |
| 007 | 凭据解析（运行时） | api-gateway | Key Vault | HTTPS + Redis 缓存 |
| 008 | 治理中心/推荐位/角色映射/模型设置 | mgmt-service | — | REST |
| 008 | 平台资源注册表 | mgmt-service | — | REST |
| 008 | 出站调用停用 | mgmt-service | api-gateway（运行时感知） | 内部事件 → Redis |
| 009 | 十三类通知 | mgmt-service | — | 同步写表 + SSE |
| 009 | Health Check 探测 | `[待确认]` | — | `[待确认]` P0 是否实现 |

---

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 按 PRD 逻辑模块 1:1 拆为 12 个微服务 | 职责清晰 | 跨服务事务爆炸（资产状态机涉及订阅/发布/通知联动）；运维成本高 | P0 团队规模不支撑 12 服务并行开发 |
| 单体后端 + 前端 | 开发速度快 | Python/Java 双栈无法合体；GPU 解析无法独立扩缩 | 技术栈冲突不可调和 |
| 网关不做护栏代理，由独立 guardrail-service 全权负责 | 网关更轻 | 全文缓冲与流式回放必须在网关完成，分离则需两次转发 | 延迟不可接受 |
| agent-service 直连 Milvus | 少一跳 | 向量操作逻辑分散到两个服务，构建与检索不一致 | 单一职责原则 |
| eval-service 同步 HTTP 触发 | 简单 | 测评耗时长（分钟级），同步阻塞网关/mgmt | 异步是刚需 |

---

## 待确认

- [ ] **护栏检测服务实现**：云原生（Azure AI Content Safety）还是自建 guardrail-service——需 PoC 比较延迟与准确率
- [ ] **BFF 层**：① mgmt-service 同时承担 BFF ② 前端直走网关 ③ 独立 BFF 服务——待前端团队确认页面聚合需求
- [ ] **会话数据持久化**：agent-service 用独立 schema / 独立 PG 实例 / 经 mgmt-service API 间接写入——待确认数据归属边界
- [ ] **Health Check 探测**：P0 是否实现周期性探测；若实现，由 mgmt-service 定时任务还是独立 CronJob——待 P0 范围确认
- [ ] **grc-mgmt-service 拆分时机**：第 3–4 周用真实 feature 验证，若订阅审批链或通知投递出现性能瓶颈则拆出

---

## 影响

- 受影响服务：全部（首次定义）
- 契约影响：需为每个服务创建 OpenAPI/AsyncAPI 契约骨架（5 个 REST + 5 个 AsyncAPI topic）
- 迁移/回滚：N/A（greenfield）

## 后果

- grc-mgmt-service 内部必须严格模块化（domain package + 内部事件），否则会退化为 big ball of mud。
- 护栏 gRPC 调用引入外部依赖，需在网关层实现熔断与降级（护栏不可达时是放行还是拒绝——PRD 未定义，建议默认拒绝）。
- 凭据解析在网关层意味着网关需要访问 Key Vault 和 Redis，安全面增大，需限制网关的 Managed Identity 权限为只读。
- MCP Server 各子模块独立容器部署会增加 K8s 资源声明数量，需统一 Helm chart 管理。
