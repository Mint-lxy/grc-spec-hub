# Implementation Plan: 当前环境端到端演示

**Branch**: `014-current-env-demo` | **Date**: 2026-09-11
**Spec**: [spec.md](./spec.md)

## Summary

在 Azure 中国云开发 AKS `XAGPMCNINFAKS001` 中交付最小真实浏览器演示链路：

`Portal → API Gateway → Auth/Mgmt → Knowledge → Parser/Milvus`

主验收场景为：演示人员从批准网络打开 Portal，使用开发演示身份进入知识库，上传固定
PDF/DOCX，经 Blob、Knowledge、Parser、Milvus 完成真实构建，并看到成功终态或可诊断失败。
检索仅在真实 AI SDK Endpoint/Key 到位后纳入验收。Mock、占位 Secret、浅层 readiness、
进程内队列均不计为成功。

## Technical Context

**Target Platform**: Azure China AKS `XAGPMCNINFAKS001`
**Container Registry**: `xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn`
**Languages**: React/TypeScript、Java 17/Spring Boot、Python 3.12/FastAPI
**Build Tools**: Portal 现有 Node 工具链、Maven 3.9/Wrapper、pip
**Runtime Dependencies**: PostgreSQL、Redis、Service Bus、Blob、Milvus、GPU、模型 PVC
**Testing**: 服务单测、清单静态校验、镜像启动 smoke、AKS rollout、浏览器/API E2E
**Environment Boundary**: 仅 XAG 开发环境；不创建或修改 PAG 生产资源

## 涉及服务（Affected Services · 必填）

| 服务 | 作用 | 当前缺口 |
|---|---|---|
| `grc-ai-portal` | 浏览器入口、知识库演示 UI | 本地缺仓库；真实 repo/权限未确认；旧构建启用 Mock |
| `grc-api-gateway` | Portal 唯一 API 入口、鉴权过滤与路由 | 无 Dockerfile/AKS 清单；Gateway 契约为空骨架 |
| `grc-auth-service` | 演示身份、Token 校验 | 无 Dockerfile/AKS 清单；需真实 DB/Redis/JWT/OIDC 配置 |
| `grc-mgmt-service` | Portal BFF、文件上传、知识库门面 | 无 Dockerfile/AKS 清单；存在 `172.16.*` 固定地址 |
| `grc-knowledge-engine` | 知识构建与检索 | deployed 模式仍使用内存队列；readiness 浅；Secret 有占位值 |
| `grc-parser-engine` | GPU 文档解析 | 已生产配置运行；保持单副本、GPU、模型 PVC |
| `grc-java-common` | Java 服务构建期共享依赖 | 必须先构建/安装，不作为独立运行服务 |
| `grc-python-sdk` | Knowledge 构建期 AI SDK 依赖 | 仅在真实 AI Endpoint/Key 到位时启用检索 |

本阶段不部署 `grc-agent-service`、`grc-evaluation-service`、`grc-mcp-server`。

## 契约影响（Contract Impact · 必填）

本计划不直接修改契约，实现只能引用已合并契约。

实施前必须完成两项契约判定：

1. `contracts/openapi/grc-api-gateway.yaml` 当前为空骨架，无法作为 Portal 消费面的正式事实源。
   若现有 Portal 请求无法逐项映射到已合并 Auth/Mgmt 契约，必须先走 `contract-change`。
2. `memory/now/watchlist.md` #71 已登记 Mgmt/Knowledge/Parser 与 spec 005 的对齐缺口。
   若缺口覆盖本次演示使用的字段、状态或错误语义，必须先完成对应契约变更。

若要新增正式 `/readyz` API 或 Portal 专用聚合接口，同样先走 `contract-change`。契约未合并前，
相关代码实现保持阻塞。

## Constitution Check

- **Spec 先行**: 实施仅追溯到已批准的 `specs/014-current-env-demo/spec.md`。
- **契约先行**: Gateway 空契约与知识域差距先判定；需要变更时先合并契约。
- **测试先行**: 每个服务先补失败测试，再实现容器化、配置或运行时修复。
- **服务边界**: Portal 只访问 Gateway；Mgmt 通过契约访问 Knowledge；Knowledge 通过契约
  访问 Parser；禁止跨服务直连他人数据库。
- **记忆义务**: tasks 最后一项固定为 retro 与 Project Memory 更新。
- **人类守门点**: 本 plan 合并前需人审；契约和 memory 变更分别独立人审。

结论：计划本身满足宪法；实现受 Portal Gate 0 和契约判定约束。

## 当前事实与缺口

### Portal

- 项目记忆显示 Portal 为 React/TypeScript，已有知识库 UI。
- 本地没有仓库；service-map 记录的地址与现有 Git 凭据组合后返回
  `Repository not found`。
- EC2 旧脚本记录目标分支 `feature/release260911`、端口 3000，且构建时设置
  `JAVA_BACKEND_ORIGIN=http://localhost:7700`、`NEXT_PUBLIC_USE_MOCK=true`。
- 在真实 repo、分支和权限确认前，禁止构建替代 Portal 或用伪页面验收。

### Gateway/Auth/Mgmt

- 三者已有 Maven 工程与业务实现，但没有 Dockerfile 和 AKS runtime 清单。
- Gateway 已有 `/api/auth/**`、`/api/mgmt/**`、`/api/open/**` 路由及鉴权过滤。
- Auth 已有密码登录、Token verify/refresh/logout 和 OIDC 流程。
- Mgmt 已有上传会话与 Knowledge 门面，但当前配置仍包含固定
  `http://172.16.16.212:8000` 等单机地址，必须改为 AKS Service FQDN。

### Knowledge

- 当前 Pod Ready 不代表业务依赖可用：`/readyz` 仅返回 configured 摘要。
- deployed 模式仍绑定 `InMemoryJobQueue`；`AzureServiceBusQueue` 已存在但未接线。
- Secret 中数据库、Redis、Service Bus、Blob、AI SDK 多项仍为占位值。
- 配置目录声明 Redis/Blob 为 deployed 必需项，但 Settings/运行时消费需逐项核对。
- README 与 Deployment 的镜像 digest 不一致，发布时必须统一到实际验收 digest。

### Parser/基础设施

- Parser 已使用真实 PostgreSQL 运行，`/health`、`/readyz` 为 200，Docling/MinerU
  warmup 成功。
- Milvus、GPU、模型 PVC 已验收；Parser 仍按单副本运行，不扩为多副本。
- PostgreSQL、Redis、Blob、Key Vault 已具备 AKS 私网 DNS/端口连通；Service Bus 当前为
  公网 Standard SKU，安全边界沿用开发环境既有裁定。

## 目标拓扑

```text
Windows Browser
  → approved private entry
  → grc-ai-portal
  → grc-api-gateway
      → grc-auth-service
      → grc-mgmt-service
          → Azure Blob
          → grc-knowledge-engine
              → PostgreSQL / Redis / Service Bus
              → grc-parser-engine → GPU + parser-models PVC
              → Milvus
```

所有业务服务在集群内使用 `ClusterIP`。浏览器入口优先采用现有私网 Ingress/Application
Gateway；若当前集群无可用入口，则使用经平台批准的内部代理方案。默认不创建公网
LoadBalancer。

## 阶段化实施方案

### Phase 0: Gate 0 与范围冻结

1. 获取 Portal 的准确仓库 URL、访问权限、目标分支和提交 SHA。
2. 确认演示 P1 为登录、进入知识库、上传、解析、构建；检索为条件性 P2。
3. 确认开发演示身份采用真实 OIDC/Alice，还是仅限 XAG 的隔离账号。
4. 确认浏览器内部入口方案。

### Phase 1: 契约与测试基线

1. 逐条比对 Portal 请求、Gateway 路由、Auth/Mgmt/Knowledge/Parser 已合并契约。
2. 对 Gateway 空契约和 watchlist #71 做阻塞判定；需要时先完成 `contract-change`。
3. 先定义服务级失败测试和跨服务 smoke/E2E 场景。

### Phase 2: 可复现镜像构建

1. 先构建/install `grc-java-common`，再构建 Auth、Mgmt、Gateway。
2. 为 Java 服务新增测试覆盖的多阶段 Dockerfile 与 `.dockerignore`。
3. 从确认后的 Portal 仓库构建，显式关闭 Mock，配置真实 Gateway origin。
4. 运行各仓库现有门禁，推送 ACR，记录 tag、commit 与远端 digest。
5. 所有 AKS 清单仅引用 digest。

### Phase 3: 真实运行时接线

1. Auth/Mgmt/Gateway 清除 `localhost`、`172.16.*`、默认 token 和占位值。
2. Mgmt 使用 Blob 与 Knowledge AKS FQDN。
3. Knowledge 接入真实 PostgreSQL、Redis、Service Bus、Blob、Milvus、Parser。
4. Knowledge deployed 模式改用持久队列并启动 worker。
5. Knowledge readiness 改为真实依赖检查；可选 AI 能力单独标识。
6. Parser 保持已验收 production、GPU、PVC、allowlist 配置。

### Phase 4: AKS 部署与入口

1. 部署 Auth。
2. 复核 Parser。
3. 部署 Knowledge，真实依赖门禁通过后再继续。
4. 部署 Mgmt。
5. 部署 Gateway。
6. 部署 Portal 和批准的内部入口。
7. 每一步保存 digest、Secret 来源、rollout 和 smoke 证据。

### Phase 5: 演示验收与收尾

1. 执行浏览器/API E2E。
2. 冻结最近一次通过的 manifest + digest 集合。
3. 演练入口逆序回滚。
4. 完成 Runbook、retro 与 Project Memory。

## 测试先行策略

| 范围 | 先写的失败测试 |
|---|---|
| Portal | Mock 必须关闭、真实 API origin、后端失败态可见 |
| Gateway | Auth/Mgmt 路由、无 Token 拒绝、后端不可达传播 |
| Auth | 演示身份登录、verify/refresh、无效身份拒绝 |
| Mgmt | 上传会话→完成上传→创建文档→调用 Knowledge |
| Knowledge | 占位 Secret 拒绝、deployed 持久队列、真实 readiness 503/200 |
| Parser | production 配置、Blob allowlist、GPU/PVC、readyz |
| E2E | 浏览器入口、身份、上传、构建终态、条件性检索、回滚 |

测试不得只断言 200；必须验证真实依赖、业务状态和失败路径。

## Secret、身份与网络策略

- Secret 仅通过 Kubernetes Secret 或批准的 Key Vault/CSI 注入，不进 Git、镜像层、日志。
- Portal 显式 `NEXT_PUBLIC_USE_MOCK=false`，后端 origin 不得为 localhost。
- Gateway 注入 Auth/Mgmt Service 地址与 Redis 配置。
- Auth 注入 PostgreSQL、Redis、JWT、OIDC/Alice 参数。
- Mgmt 注入 PostgreSQL、Redis、Blob、Knowledge Service 地址及内部 token。
- Knowledge 注入 PostgreSQL、Redis、Service Bus、Blob、Milvus token；AI SDK 仅在检索纳入时
  注入真实值。
- Parser 沿用已验证 PostgreSQL、service bearer、cursor key 与模型 PVC。
- 身份优先真实 OIDC/Alice；不具备时仅启用 XAG 隔离演示账号，禁止匿名绕过。
- 入口只允许批准网络，默认不暴露公网。

## 镜像构建与 ACR Digest

- 镜像命名：`<acr>/grc/<service>:<release-or-git-sha>`。
- 发布后读取 ACR 远端 digest，再回填 Deployment。
- 禁止 `latest`、本地临时镜像和只凭 tag 验收。
- Knowledge 先统一 README/Deployment digest 真相源。
- Java 构建必须显式处理 `grc-java-common`，不得依赖 EC2 主机未记录的 Maven 本地缓存。
- Portal 在 Gate 0 完成后，按确认的 commit 构建；构建产物必须证明 Mock 已关闭。

## AKS 部署顺序

1. 人审通过本 plan。
2. 完成 Gate 0；若需要，先合并契约变更。
3. 复核 PostgreSQL、Redis、Service Bus、Blob、Milvus、GPU、PVC、ACR。
4. 构建并推送 Auth、Mgmt、Gateway、Knowledge 修复镜像、Portal 镜像。
5. Auth → Parser 复核 → Knowledge → Mgmt → Gateway → Portal/入口。
6. 执行 smoke/E2E，冻结通过版本。

## 端到端演示验收

1. 普通 Windows 浏览器通过批准网络打开 Portal，无需 Azure CLI/kubectl。
2. Portal 核心请求经 Gateway 命中真实 Auth/Mgmt，不命中 Mock。
3. 演示身份可访问知识库，无身份请求被拒绝。
4. 固定 PDF/DOCX 经上传会话、Blob、Mgmt、Knowledge、Parser、Milvus 完成真实构建。
5. UI/API 显示真实终态；失败在 2 分钟内可诊断。
6. AI SDK 真凭据可用时执行检索；否则明确显示能力不可用。
7. 运行工作负载均可追溯到 ACR digest，Runbook 可复现部署。

## 回滚

- 回滚锚点为最近一次通过 smoke/E2E 的 manifest + digest 集合。
- 应用回滚按 Portal → Gateway → Mgmt → Knowledge → Parser 逆序执行。
- PostgreSQL、Blob、Milvus/PVC 默认不随应用回滚删除。
- Secret 轮换与应用版本回滚分离；不得恢复已废弃或泄露凭据。
- 演示数据重置另设步骤，禁止用删库作为常规回滚。

## 明确阻塞与决策

| 项目 | 状态 | 进入实现前要求 |
|---|---|---|
| Portal repo/权限/分支 | 阻塞 | 获取准确 URL、权限、`feature/release260911` SHA |
| Gateway 契约为空 | 阻塞判定 | 明确是否需 `contract-change` |
| watchlist #71 | 阻塞判定 | 核对是否覆盖演示字段/状态 |
| Knowledge 持久队列 | 阻塞 | deployed 模式接入 Service Bus + worker |
| Knowledge readiness | 阻塞 | 增加真实依赖门禁 |
| Knowledge/Java Secret | 阻塞 | 清除占位值并确认 Secret 来源 |
| 检索能力 | 条件性 | 真实 AI SDK Endpoint/Key 到位后启用 |
| 演示身份 | 待裁定 | OIDC/Alice 优先，否则 XAG 隔离账号 |
| 浏览器入口 | 待裁定 | 私网入口或批准代理，禁止默认公网 LB |

## Complexity Tracking

| 复杂项 | 为什么需要 | 更简单方案为何不采用 |
|---|---|---|
| 部署六个运行时服务 | Portal 真实知识库演示需要完整 UI/BFF/领域链路 | 直接 port-forward API 不能满足浏览器项目演示 |
| Knowledge 持久队列修复 | deployed 模式不能依赖进程内状态 | 保留内存队列会造成重启丢任务和虚假验收 |
| 条件性检索 | AI SDK 资源当前不可确认 | 使用占位 URL 或假结果违反 spec |
