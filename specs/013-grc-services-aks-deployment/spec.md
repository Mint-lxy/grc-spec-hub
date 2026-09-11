# Feature Specification: GRC 服务上 AKS（开发环境第一阶段）

**Feature Branch**: `013-grc-services-aks-deployment`

**Created**: 2026-09-10

**Status**: Draft

**Input**: 在 Azure 中国云开发集群 `XAGPMCNINFAKS001` 上推进 GRC 服务部署，先完成
`grc-parser-engine` 与 `grc-knowledge-engine` 两个已发布到 ACR 的服务。

## 背景与目标

当前已完成 GPU、Milvus、Parser 模型 PVC 交付，以及以下镜像发布：

- `xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn/grc/parser-engine:0.1.0-ec2-20260909`
- `xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn/grc/knowledge-engine:0.1.0`

下一步目标是将上述镜像以 Kubernetes 工作负载方式部署到 AKS，并明确运行时配置、模型挂载、
镜像固定策略和部署验证流程，为后续其他 GRC 服务迁移提供模板。

## User Scenarios & Testing

### User Story 1 - Parser 在 AKS 可稳定启动并使用 PVC 模型 (Priority: P1)

运维可在 `gpupool` 启动 parser，并通过只读挂载模型 PVC 使用已交付模型，且服务探针正常。

**Independent Test**: 应用清单后 Deployment 达到 Available，`/health`、`/readyz` 可访问，
Pod 在 `gpupool` 上运行，且模型目录来自 PVC 只读挂载。

**Acceptance Scenarios**:

1. **Given** parser 清单应用成功，**When** 查看 Pod，**Then** Pod调度在 `gpupool` 且声明
   `nvidia.com/gpu: 1`。
2. **Given** parser Pod 运行，**When** 检查 volumeMount，**Then** `/app/.models/parser`
   来自 `parser-models` PVC 且为只读。
3. **Given** parser Deployment 已就绪，**When** 访问 `/health` 与 `/readyz`，
   **Then** 均返回健康响应。

---

### User Story 2 - Knowledge 在 AKS 通过私网依赖运行 (Priority: P1)

运维可在 AKS 启动 knowledge，并通过配置注入连接 PostgreSQL、Redis、Service Bus、Blob、
Milvus 与 parser 内部服务地址。

**Independent Test**: 应用清单后 Deployment 达到 Available，`/health`、`/readyz` 正常，
配置中不包含明文凭据，敏感变量来自 Secret。

**Acceptance Scenarios**:

1. **Given** knowledge 清单应用成功，**When** 查看 Deployment，**Then** 必需运行时环境变量
   已注入（deployed 模式必填项齐全）。
2. **Given** knowledge Pod 运行，**When** 检查环境变量来源，**Then** 密钥类配置来自 Secret。
3. **Given** knowledge Deployment 已就绪，**When** 访问 `/health` 与 `/readyz`，
   **Then** 均返回健康响应。

---

### User Story 3 - 清单可审计且可复用 (Priority: P2)

平台工程师可复用统一规范：镜像固定 digest、禁止 latest、Namespace/Service/探针/资源边界清晰。

**Independent Test**: 运行清单静态校验脚本，确认镜像来源、digest、挂载与关键策略符合约束。

### Edge Cases

- parser 镜像端口与历史脚本端口不一致时，探针或 Service 配置需以镜像运行事实为准。
- 任何 Secret 缺失或键名错误都应导致启动失败，禁止静默降级。
- 未授予 `AcrPull` 或镜像 tag 漂移应通过 digest 固定规避。

## Requirements

### Functional Requirements

- **FR-001**: parser 与 knowledge 清单 MUST 使用项目 ACR 镜像并按 digest 固定。
- **FR-002**: 清单 MUST NOT 使用 `latest`。
- **FR-003**: parser Deployment MUST 调度至 `gpupool`，并容忍 `sku=gpu:NoSchedule`。
- **FR-004**: parser Deployment MUST 声明 `nvidia.com/gpu: 1` requests/limits。
- **FR-005**: parser MUST 将 `parser-models` PVC 以只读方式挂载到 `/app/.models/parser`。
- **FR-006**: knowledge Deployment MUST 提供 deployed 模式必需配置，敏感项来自 Secret。
- **FR-007**: parser 与 knowledge MUST 定义 `ClusterIP` Service 和健康探针。
- **FR-008**: MUST 提供清单静态校验脚本，覆盖镜像、digest、关键调度和安全约束。
- **FR-009**: 实施记录 MUST 更新到 `docs/temp/部署服务相关任务清单.md`。

## 非目标 / 边界

- 不包含 `grc-api-gateway`、`grc-auth-service`、`grc-mgmt-service` 上线（当前仓库尚无 AKS 清单基线）。
- 不改变服务间 API/事件契约。
- 不在本 spec 中创建生产环境资源或执行生产发布。

## Success Criteria

### Measurable Outcomes

- **SC-001**: parser 与 knowledge 清单静态校验通过，且无 `latest`、无公网镜像。
- **SC-002**: 两个 Deployment 在开发 AKS 均达到 Available。
- **SC-003**: 两个 Service 均为 `ClusterIP`，探针可返回健康状态。
- **SC-004**: parser Pod 具备 GPU 可调度条件并只读挂载模型 PVC。
