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

## 决策

采用以下八服务 + 前端的架构（对应 C4 容器图）：

| 服务 | 语言 | 职责（对应 spec） | 说明 |
|------|------|-------------------|------|
| grc-ai-portal | TypeScript/React | 全部用户界面 | SPA |
| grc-api-gateway | Java | 路由/限流/鉴权转发/护栏代理/审计/流式缓冲 | 网关层 |
| grc-auth-service | Java | SSO 对接/Token/PAT | 006-guardrail 运行时由网关调用 |
| grc-mgmt-service | Java | 002~004/006~009 全部管理面逻辑 | "大后端"：资产/订阅/发布/护栏模板/密钥库/管理后台/通知 |
| grc-agent-service | Python | 001-conversation | 对话编排 + MCP 调用 + LLM 调度 |
| grc-evaluation-service | Python | 004-publish（测评执行） | 异步任务，订阅 Service Bus topic |
| grc-knowledge-engine | Python | 005-knowledge | 知识管线 + 向量检索 + 开放接口 |
| grc-parser-engine | Python (GPU) | 005-knowledge（解析阶段） | Docling/MinerU，受知识引擎调度 |
| grc-mcp-server | Python/TypeScript | 平台原生工具（M365/Confluence/数据平台/Web） | 多子模块 monorepo |

### spec ↔ 服务的映射

| Spec | 主服务 | 辅助服务 |
|------|--------|----------|
| 001-conversation | grc-agent-service | grc-api-gateway（护栏/流式）、grc-knowledge-engine（检索） |
| 002-marketplace | grc-mgmt-service | grc-api-gateway（详情分层） |
| 003-asset-creation | grc-mgmt-service | — |
| 004-publish | grc-mgmt-service | grc-evaluation-service（测评执行） |
| 005-knowledge | grc-knowledge-engine | grc-parser-engine、grc-mcp-server（外部导入） |
| 006-guardrail | grc-mgmt-service（模板管理） | grc-api-gateway（运行时执行） |
| 007-credential | grc-mgmt-service（PAT/个人凭据） | grc-auth-service（Token 校验） |
| 008-admin | grc-mgmt-service | — |
| 009-notification | grc-mgmt-service | — |

### 与 PRD §10.1 逻辑模块的差异

| PRD 逻辑模块 | 归入的部署服务 | 理由 |
|---|---|---|
| 资产目录 + 订阅引擎 + 创建向导 + 发布链路 + 密钥库 + 管理后台 + 通知 | grc-mgmt-service | 共享资产数据模型，避免分布式事务 |
| 护栏引擎（模板管理） | grc-mgmt-service | CRUD 逻辑 |
| 护栏引擎（运行时执行） | grc-api-gateway | 网关是唯一执行点 |
| 测评引擎 | grc-evaluation-service | 异步长任务，独立扩缩 |
| 对话引擎 | grc-agent-service | Python 栈 + 流式 |
| 知识管线 | grc-knowledge-engine + grc-parser-engine | Python 栈 + GPU 隔离 |

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 按 PRD 逻辑模块 1:1 拆为 12 个微服务 | 职责清晰 | 跨服务事务爆炸（资产状态机涉及订阅/发布/通知联动）；运维成本高 | P0 团队规模不支撑 12 服务并行开发 |
| 单体后端 + 前端 | 开发速度快 | Python/Java 双栈无法合体；GPU 解析无法独立扩缩 | 技术栈冲突不可调和 |
| 网关不做护栏执行，由独立 guardrail-service 承担 | 网关更轻 | 多一跳延迟；护栏需要全文缓冲，与流式输出控制耦合 | 延迟不可接受（PRD §9.5 要求网关缓冲→检测→回放） |

## 待确认

- [ ] grc-mgmt-service 是否过大——第 3–4 周用真实 feature spec 验证是否需要进一步拆分（候选：订阅引擎独立、通知独立）
- [ ] 护栏运行时是网关内嵌还是网关调用独立 sidecar——取决于护栏检测的 P95 延迟（需性能测试）
- [ ] grc-mcp-server 各子模块是否需要独立部署（当前为 monorepo 多进程）

## 影响

- 受影响服务：全部（首次定义）
- 契约影响：需为每个服务创建 OpenAPI/AsyncAPI 契约骨架
- 迁移/回滚：N/A（greenfield）

## 后果

- grc-mgmt-service 承载了大部分业务逻辑，需要内部模块化（按 domain package 隔离），避免变成 big ball of mud。
- 护栏运行时嵌入网关意味着网关的变更频率会高于传统 API gateway，需在 CI 中增加护栏相关的集成测试。
- 后续若 grc-mgmt-service 需要拆分，优先拆出通知服务（事件驱动，天然解耦）。
