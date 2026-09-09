# Feature Specification: Milvus 开发环境部署

**Feature Branch**: `011-milvus-dev-deployment`

**Created**: 2026-09-09

**Status**: Draft（待人审）

**Input**: 在 Azure 中国云开发 AKS 上部署 Milvus 2.5.12，为
`grc-knowledge-engine` 提供可持久化、可恢复、仅集群内访问的向量数据库。

## 背景与目标

开发 AKS `XAGPMCNINFAKS001` 已具备正常的跨节点网络、Private DNS、ACR 拉取能力和
独立 `milvuspool`。Milvus 2.5.12、etcd 3.5.18、MinIO 固定版本镜像已同步至项目 ACR，
但集群内尚未部署 Milvus。

本功能使用官方 Milvus Helm Chart 4.2.49 部署开发环境单机拓扑：

- 一个 Milvus Standalone 实例。
- 内置 Rocksmq 作为 Standalone 消息队列。
- 一个 etcd 副本。
- 一个 MinIO 副本。
- 三个独立的 Premium SSD 持久卷，各 64 GiB。

该拓扑用于开发和集成验证，不作为生产高可用方案。

## User Scenarios & Testing

### User Story 1 - 知识引擎可使用 Milvus (Priority: P1)

开发环境中的 `grc-knowledge-engine` 能够通过集群内地址连接 Milvus，创建 collection、
写入向量并执行相似度查询。

**Why this priority**: Milvus 是知识构建和检索链路的主向量数据库；没有可用的 Milvus，
知识引擎无法完成 P0 的向量写入和检索。

**Independent Test**: 使用一次性验收 Pod 连接 Milvus，创建隔离的测试 collection，
写入已知向量，执行查询并断言返回预期记录，最后删除测试 collection 和 Pod。

**Acceptance Scenarios**:

1. **Given** Milvus、etcd 和 MinIO 均已 Ready, **When** 测试客户端连接集群内服务,
   **Then** 能通过认证建立连接。
2. **Given** 空的测试 collection, **When** 写入一组已知向量并建立索引,
   **Then** 查询返回预期的主键和相似度顺序。
3. **Given** 验收完成, **When** 清理测试数据,
   **Then** 不残留测试 collection、Job 或临时 Pod。

---

### User Story 2 - 数据在 Pod 重建后保持 (Priority: P1)

Milvus、etcd 或 MinIO Pod 重建后，已写入的测试数据仍可查询。

**Why this priority**: 开发环境虽然不是高可用，但必须具备基本持久化能力；Pod 重建不能
导致全部向量数据丢失。

**Independent Test**: 写入测试 collection 后，依次重建 Milvus、etcd 和 MinIO Pod；
每次组件恢复 Ready 后重新查询并断言数据仍存在。

**Acceptance Scenarios**:

1. **Given** 已写入测试数据, **When** Milvus Standalone Pod 被删除并重建,
   **Then** Pod 恢复后仍能查询原数据。
2. **Given** 已写入测试数据, **When** etcd Pod 被删除并重建,
   **Then** 元数据恢复且原 collection 可查询。
3. **Given** 已写入测试数据, **When** MinIO Pod 被删除并重建,
   **Then** 对象数据恢复且查询结果不丢失。
4. **Given** Helm release 被回滚或卸载, **When** 检查持久卷,
   **Then** PVC 不因普通回滚操作被自动删除。

---

### User Story 3 - Milvus 与普通业务资源隔离 (Priority: P2)

Milvus、etcd 和 MinIO 只运行于专用 `milvuspool`，普通业务 Pod 不会误占该节点。

**Why this priority**: 测试环境每个节点池只有一个节点，Milvus 持久化和检索负载需要与
apppool、gpupool 隔离，避免相互争抢。

**Independent Test**: 检查节点 taint、三个组件的调度位置和不带 toleration 的普通测试
Pod，确认只有声明 Milvus 调度约束的工作负载能落到 `milvuspool`。

**Acceptance Scenarios**:

1. **Given** `milvuspool` 配置专用 taint, **When** 三个 Milvus 组件调度,
   **Then** 它们均运行于 `milvuspool`。
2. **Given** 普通 Pod 没有 Milvus toleration, **When** 它显式选择 `milvuspool`,
   **Then** Pod 因未容忍 taint 而保持 Pending。
3. **Given** Milvus 工作负载运行, **When** 检查节点资源,
   **Then** 资源 requests 不超过节点可分配容量，系统 Pod 保持健康。

---

### User Story 4 - 失败可诊断、部署可回滚 (Priority: P2)

运维人员能够从 Helm、Pod、PVC、事件、日志和健康端点定位失败，并在保留数据的前提下
回滚或重新部署。

**Why this priority**: 单节点开发环境没有副本冗余，必须通过明确的 Runbook 降低误删
持久化数据和错误升级的风险。

**Independent Test**: 使用固定 Chart/values 执行安装、升级 dry-run、回滚和重新验收；
确认回滚不删除 PVC，集群其他 Namespace 不受影响。

**Acceptance Scenarios**:

1. **Given** 镜像、调度或存储失败, **When** 查看 Helm 状态、Pod 事件和日志,
   **Then** 能得到明确错误，不使用成功形态兜底。
2. **Given** 新 release 修订不可用, **When** 执行 Helm rollback,
   **Then** 回到上一成功 revision，PVC 和数据保持。
3. **Given** 需要卸载应用层资源, **When** 按 Runbook 操作,
   **Then** 不删除 PVC、Secret 或 Azure Disk；数据清理必须使用独立、显式且经批准的步骤。

### Edge Cases

- 任一 ACR 镜像拉取失败时，部署必须停止，不得临时改用公网镜像或 `latest`。
- 任一 PVC Pending 时，Milvus 不得被判定为部署成功。
- 单节点维护或故障期间服务可以暂时不可用，但恢复后数据必须可查询。
- 三个 64 GiB PVC 任一达到 80% 使用率时，必须产生可见告警或运维提示。
- etcd、MinIO 与 Milvus 不得同时执行破坏性重启测试。
- 默认或示例凭据不得用于应用接入。
- Helm rollback 不等同于数据回滚；数据恢复必须另行设计和演练。
- Chart 渲染出的任何运行镜像若不在项目 ACR，门禁必须失败。

## Requirements

### Functional Requirements

- **FR-001**: 系统 MUST 使用官方 Milvus Helm Chart 4.2.49 部署 Milvus 2.5.12。
- **FR-002**: 开发环境 MUST 使用 Standalone 模式，副本数为 1，并使用 Rocksmq；
  MUST NOT 启用 Pulsar、Kafka、Woodpecker 或 Milvus Cluster 模式。
- **FR-003**: 系统 MUST 部署单副本 etcd 3.5.18 和单副本 MinIO
  `RELEASE.2025-09-07T16-13-09Z`。
- **FR-004**: Milvus、etcd、MinIO 运行镜像 MUST 来自项目 ACR，并在渲染清单中使用
  固定 digest；MUST NOT 使用 `latest` 或未批准的公网仓库。
- **FR-005**: 系统 MUST 为 Milvus、etcd、MinIO 分别创建 64 GiB、
  `ReadWriteOnce` 的 `managed-csi-premium` PVC。
- **FR-006**: 三个 PVC MUST 配置 Helm 保留策略；普通 upgrade、rollback 或
  uninstall MUST NOT 自动删除 PVC。
- **FR-007**: 系统 MUST 将 Milvus、etcd、MinIO 调度到 `milvuspool`，并为该节点池
  配置 `sku=milvus:NoSchedule`。
- **FR-008**: 三个组件 MUST 设置明确的 CPU/内存 requests 和 limits；总 requests
  MUST 小于 `milvuspool` 的可分配 3860m CPU 和 32098164Ki 内存。
- **FR-009**: Milvus 服务 MUST 使用 ClusterIP，仅在集群内暴露 19530 和健康/指标端口；
  MUST NOT 创建公网 LoadBalancer 或 Ingress。
- **FR-010**: Milvus MUST 启用认证；默认 root 密码 MUST 在业务接入前轮换，并通过
  Kubernetes Secret 或经批准的 Secret 管理机制注入，MUST NOT 写入 Git 或 Helm values。
- **FR-011**: MinIO 凭据 MUST 使用预创建 Secret，MUST NOT 使用 chart 示例
  `minioadmin/minioadmin`，MUST NOT明文写入 Git。
- **FR-012**: Milvus MUST 配置 liveness、readiness 和 startup probe；只有三个组件
  及 PVC 全部健康时，release 才能判定成功。
- **FR-013**: 部署 MUST 提供日志、Pod 事件、PVC 容量、19530 连通性和 Milvus
  health/metrics 的检查命令。
- **FR-014**: 系统 MUST 提供创建 collection、写入、查询、删除的自动化 smoke test，
  测试资源使用唯一名称并在成功后清理。
- **FR-015**: 系统 MUST 依次完成 Milvus、etcd、MinIO Pod 重建测试，每一步恢复 Ready
  且数据查询成功后才能继续下一步。
- **FR-016**: 系统 MUST 提供幂等安装、升级、回滚、卸载和数据清理 Runbook；数据清理
  与普通卸载必须分离。
- **FR-017**: Helm Chart 包、values 和渲染结果 MUST 进入静态门禁，检查 Chart 版本、
  镜像 digest、禁止公网镜像、禁止 `latest`、PVC、调度、资源限制和外部暴露。
- **FR-018**: 实施完成后 MUST 更新部署镜像清单、retro 和 Project Memory。

## 非目标 / 边界

- 不部署生产 Milvus Cluster。
- 不提供多副本高可用、跨可用区容灾或自动扩缩容。
- 不部署 Pulsar、Kafka、Woodpecker、Attu 或外部 Ingress。
- 不将对象存储替换为 Azure Blob；开发环境先使用单副本 MinIO。
- 不在本 spec 中部署或修改 `grc-knowledge-engine` 应用。
- 不在本 spec 中定义生产备份、RPO/RTO 或灾难恢复方案。
- 不创建新的 AKS 节点、Azure VM、数据库或存储账号。
- 不修改任何服务间 REST、事件或共享模型契约。

## Key Entities

- **Milvus Helm Release**: 开发环境单机向量数据库 release，固定 Chart 4.2.49。
- **Milvus Standalone**: 单副本向量数据库进程，包含 Rocksmq 数据目录。
- **etcd**: 单副本元数据存储。
- **MinIO**: 单副本对象存储。
- **PVC**: 三个独立 64 GiB Premium SSD 持久卷。
- **验收 Collection**: 自动化 smoke test 创建的临时 collection，测试后删除。

## Success Criteria

### Measurable Outcomes

- **SC-001**: Milvus、etcd、MinIO 各一个 Pod Ready，且均运行在 `milvuspool`。
- **SC-002**: 三个 64 GiB PVC 均为 Bound，StorageClass 为
  `managed-csi-premium`。
- **SC-003**: Helm 渲染结果中 100% 运行镜像来自项目 ACR并使用 digest。
- **SC-004**: collection 创建、向量写入、查询和删除 smoke test 在 5 分钟内完成。
- **SC-005**: Milvus、etcd、MinIO 分别重建后，测试数据查询成功率为 100%。
- **SC-006**: 不带 toleration 的普通测试 Pod 无法调度到 `milvuspool`。
- **SC-007**: 部署后四个 AKS 节点保持 Ready，集群无新增 CrashLoopBackOff 或
  ImagePullBackOff。
- **SC-008**: Helm rollback 回到上一成功 revision，三个 PVC 和测试数据保持。

## Assumptions

- 开发环境已批准使用三块 64 GiB Premium SSD；该容量与群聊中的三块 P6 资源一致。
- `milvuspool` 当前为单节点 `Standard_E4s_v5`，可分配 3860m CPU、约 30.6 GiB 内存。
- 测试环境各节点池 demand 为 1，不启用 autoscale。
- AKS 跨节点网络、Private DNS、ACR `AcrPull` 已验证通过。
- Milvus、etcd、MinIO 三个基础镜像已同步 ACR并完成基本运行验证。
- `grc-knowledge-engine` 已支持 `MILVUS_URI`、`MILVUS_TOKEN` 和
  `MILVUS_DB_NAME`，但本 spec 不部署该服务。
- 本功能无契约影响。

## 未决问题

无。生产高可用、备份、监控增强和容量扩展在后续独立 spec 中处理。
