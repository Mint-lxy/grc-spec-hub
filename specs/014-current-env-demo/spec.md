# Feature Specification: 当前环境端到端演示

**Feature Branch**: `014-current-env-demo`

**Created**: 2026-09-11

**Status**: Reviewed

**Input**: 在 Azure 中国云开发环境 `XAGPMCNINFAKS001` 中形成可从浏览器演示的 GRC
项目最小闭环；演示必须使用真实后端链路，不以 Portal Mock 数据替代成功结果。

## 背景与目标

当前开发 AKS 已具备 Milvus、GPU、Parser 模型 PVC，以及可运行的 parser/knowledge
工作负载。parser 已接入 PostgreSQL 并通过 `/health`、`/readyz` 与 Docling/MinerU
warmup；knowledge 虽已启动，但部分 Secret 仍为占位值、deployed 模式未完整接入持久队列，
其 `/readyz` 也未验证外部依赖。

本阶段以“能够向项目干系人在当前开发环境演示”为目标，打通最小用户可见链路：

`Portal → API Gateway/Auth/Mgmt → Knowledge → Parser/Milvus`

演示主场景为知识库：进入 Portal、使用开发演示身份、创建或选择知识库、上传一份受支持文档、
触发真实解析与构建，并查看最终状态或检索结果。

## User Scenarios & Testing

### User Story 1 - 从浏览器进入开发环境 (Priority: P1)

演示人员可通过公司批准的网络路径打开 Portal，并进入知识库页面；Portal 请求真实 API，
而不是使用 Mock 数据。

**Why this priority**: 浏览器入口是项目演示的最低门槛，也是验证 Portal、Gateway 和服务路由
已真正集成的前提。

**Independent Test**: 在一台具备批准网络访问能力的 Windows 电脑上打开演示地址，确认页面
加载成功，浏览器网络请求发往当前环境 API，且核心请求不命中 Mock handler。

**Acceptance Scenarios**:

1. **Given** 演示人员处于批准网络中，**When** 打开演示地址，**Then** Portal 页面可加载，
   且无需在浏览器所在电脑安装 Azure CLI 或 kubectl。
2. **Given** Portal 已加载，**When** 进入知识库页面，**Then** 页面通过 Gateway 调用真实后端，
   不使用 `NEXT_PUBLIC_USE_MOCK=true` 作为成功路径。
3. **Given** 后端不可用，**When** 页面请求失败，**Then** UI 显示可识别的失败状态，而不是
   返回伪造成功数据。

---

### User Story 2 - 使用开发演示身份访问知识库 (Priority: P1)

演示人员可使用批准的开发演示身份进入知识库功能。若企业 SSO 尚未具备接入条件，可使用
明确标识、仅限当前开发环境的临时认证方案，但不得绕过后端权限边界或复用生产身份凭据。

**Why this priority**: 真实 UI/API 链路需要稳定身份上下文；SSO 未完成不应阻塞开发环境演示，
也不能因此把匿名访问误当成最终方案。

**Independent Test**: 使用演示身份完成一次登录或开发环境身份注入，随后访问一个需要身份的
知识库 API，并确认无身份请求被拒绝。

**Acceptance Scenarios**:

1. **Given** 有效开发演示身份，**When** 访问知识库功能，**Then** Gateway、Auth 和 Mgmt
   能识别同一身份上下文。
2. **Given** 无有效身份，**When** 调用受保护接口，**Then** 请求被拒绝并返回已登记错误格式。
3. **Given** 使用临时开发认证，**When** 查看部署配置，**Then** 该能力仅在 XAG 开发环境启用，
   且有明确撤销步骤。

---

### User Story 3 - 上传文档并完成真实构建 (Priority: P1)

演示人员可创建或选择知识库，上传一份受支持的 PDF 或 DOCX，触发真实 Parser 解析与 Knowledge
构建，并观察任务从提交到成功或可诊断失败的状态变化。

**Why this priority**: 这是当前已交付 GPU、模型、Parser、Milvus 和 Knowledge 能力的核心业务
证明，能够验证基础设施不是“Pod 绿色但业务不可用”。

**Independent Test**: 上传固定演示文档，记录任务 ID，轮询或刷新状态直至完成，并确认解析输出
及向量数据来自真实服务。

**Acceptance Scenarios**:

1. **Given** 知识库可用且演示文档合法，**When** 用户上传并发起构建，**Then** 请求通过
   Gateway 到达 Knowledge，并由 Parser 使用挂载模型处理。
2. **Given** 构建成功，**When** 用户查看状态，**Then** UI 展示成功状态及可验证的文档信息，
   Milvus 中存在对应向量数据。
3. **Given** Parser、数据库、消息队列或对象存储不可用，**When** 构建失败，**Then** UI/API
   返回可诊断失败信息，不得长期停留在伪成功或无界等待状态。

---

### User Story 4 - 查询已构建知识 (Priority: P2)

演示人员可对已成功构建的知识库发起一次查询或检索，并获得与演示文档相关的结果。

**Why this priority**: 查询结果证明“上传—解析—切片—向量化—检索”数据链闭环，而不只是任务
状态变化。

**Independent Test**: 对固定演示文档提出预定义问题，响应至少返回一个可追溯到该文档的结果。

**Acceptance Scenarios**:

1. **Given** 演示文档已构建成功，**When** 用户执行预定义查询，**Then** 返回至少一个与文档
   内容相关的结果。
2. **Given** Embedding/Rerank 服务未配置，**When** 执行依赖该能力的操作，**Then** 系统明确
   报告能力不可用，不得以占位 URL 或假结果通过验收。

---

### User Story 5 - 可重复演示与快速恢复 (Priority: P2)

运维人员可以按 Runbook 重置演示数据、重新部署服务，并在失败后恢复到最近一次通过验收的版本。

**Why this priority**: 演示环境需要可重复，不应依赖某个临时终端会话或人工记忆。

**Independent Test**: 按 Runbook 从已发布镜像和清单重新部署，执行 smoke test，并演练一次回滚。

**Acceptance Scenarios**:

1. **Given** 已发布的 digest 和部署清单，**When** 重新部署，**Then** 演示链路可恢复且不依赖
   未记录的手工步骤。
2. **Given** 新版本演示失败，**When** 执行回滚，**Then** 服务恢复到最近一次验收通过的版本。

### Edge Cases

- Portal 仓库不可访问或发布分支不可拉取时，必须明确阻塞，不得用临时伪页面替代项目 Portal。
- 企业 SSO 尚未就绪时，开发演示身份必须环境隔离、可撤销，且不得进入生产配置。
- AI SDK Endpoint/API Key 尚未提供时，上传与解析可独立验收；依赖 Embedding/Rerank 的构建或
  检索必须明确标记阻塞，不得由占位值通过 readiness。
- 单节点 GPU、Milvus 或应用节点重启时，任务必须失败可诊断或在恢复后可重试。
- Secret 缺失、仍为 `replace_me` 或指向 `.invalid` 域名时，部署门禁必须失败。
- 浏览器无法直达私网入口时，应提供批准的内部入口方案；不得直接创建公网 LoadBalancer
  作为默认解法。

## Requirements

### Functional Requirements

- **FR-001**: 演示 MUST 使用 XAG 开发环境，不创建或修改 PAG 生产环境资源。
- **FR-002**: 演示 MUST 提供浏览器可访问的 Portal 入口，且浏览器端无需安装集群管理工具。
- **FR-003**: Portal 核心演示请求 MUST 调用真实 Gateway/API，MUST NOT 使用 Mock 数据伪造成功。
- **FR-004**: 系统 MUST 提供仅限开发环境的演示身份路径，并保留未认证拒绝行为。
- **FR-005**: Gateway、Auth、Mgmt、Knowledge、Parser 之间 MUST 复用已合并契约；若发现契约
  不足，必须先走 contract-change。
- **FR-006**: Knowledge deployed 模式 MUST 使用真实 PostgreSQL、Redis、Service Bus、Blob、
  Milvus 和 Parser 配置；必需 Secret 不得包含占位值。
- **FR-007**: Knowledge MUST 将异步任务发送至持久队列并由 worker 消费；不得在 deployed
  模式继续以进程内队列作为演示成功路径。
- **FR-008**: Knowledge readiness MUST 验证演示主链路依赖，至少覆盖数据库、队列、Blob、
  Milvus 和 Parser；可选 AI 能力必须在响应中明确标识 available/unavailable。
- **FR-009**: 系统 MUST 支持 PDF 或 DOCX 中至少一种固定演示文档完成真实解析和知识构建。
- **FR-010**: 若演示范围包含检索，Embedding 服务 MUST 使用有效 Endpoint/Key，且不得通过
  占位地址启动为“configured”。
- **FR-011**: 所有部署镜像 MUST 位于项目 ACR、按 digest 固定且不得使用 `latest`。
- **FR-012**: Secret MUST 通过 Kubernetes Secret 或批准的 Key Vault/CSI 机制注入，不得提交
  到 Git、镜像层、日志或文档。
- **FR-013**: 必须提供自动化 smoke test，验证入口、身份、服务健康、文档构建及可选检索链路。
- **FR-014**: 必须提供不含凭据的部署、验证、重置和回滚 Runbook。
- **FR-015**: Portal 源仓库和目标发布分支在构建前 MUST 可追溯；仓库访问失败必须作为显式阻塞。

## 非目标 / 边界

- 本阶段不创建生产 AKS、生产数据库或生产公网入口。
- 本阶段不要求平台九个业务服务全部上线；Agent Chat、Evaluation、MCP 完整能力不属于最小
  知识库演示链路。
- 本阶段不以完成企业 SSO、生产 HA、灾备、容量压测或正式域名证书为验收前提。
- 本阶段不新增或修改跨服务业务契约；发现缺口时暂停对应实现并进入 contract-change。
- 本阶段不把 Portal Mock、占位 Secret、仅返回 200 的浅层 readiness 计为业务验收通过。

## Success Criteria

### Measurable Outcomes

- **SC-001**: 演示人员能从批准网络的普通浏览器打开 Portal，并在 2 分钟内进入知识库页面。
- **SC-002**: 自动化检查确认核心演示请求未启用 Mock，且所有运行镜像均为 ACR digest。
- **SC-003**: 固定 PDF/DOCX 从上传到构建终态在 10 分钟内完成，或在依赖失败时于 2 分钟内
  返回可诊断失败状态。
- **SC-004**: Parser、Knowledge 及演示所需 Java/Portal 服务均达到 Ready，且真实依赖检查通过。
- **SC-005**: 若 AI SDK 凭据可用，预定义查询至少返回一个可追溯到演示文档的结果；若不可用，
  演示范围和 UI/API 状态明确降级，不报告虚假成功。
- **SC-006**: 从任一新部署版本回滚到最近一次通过版本可在 10 分钟内完成。
- **SC-007**: 演示 Runbook 可由未参与本次实施的人员按步骤执行，不需要未记录的 Secret 或命令。

## Assumptions

- 当前目标是开发环境演示，而不是生产发布。
- `feature/release260831` 是后端当前发布基线；Portal 当前目标分支为
  `feature/release260911`，但仓库地址/权限需在实施前确认。
- 临时开发身份可被接受，但必须与生产身份和 Secret 隔离。
- Parser、Milvus、GPU 和模型 PVC 以当前已验收版本为基础，不在本阶段重新设计。
- AI SDK 资源未出现在当前 Azure 资源组中；在取得有效 Endpoint/Key 前，检索场景按阻塞或
  明确降级处理。
