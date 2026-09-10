# Feature Specification: AKS GPU 能力启用

**Feature Branch**: `010-aks-gpu-enablement`

**Created**: 2026-09-09

**Status**: Reviewed（2026-09-09 用户批准；实现、回滚与重装验收完成）

**Input**: 在现有开发 AKS 的 `gpupool` 上采用自管 NVIDIA Device Plugin 的方案，
使 `grc-parser-engine` 等 GPU 工作负载可以声明、调度并使用 GPU；不重建节点池。

## 背景与目标

开发集群 `XAGPMCNINFAKS001` 已有一台 `Standard_NC8as_T4_v3` GPU 节点，
节点标签包含 `accelerator=nvidia`，但 Kubernetes `Capacity/Allocatable` 尚未出现
`nvidia.com/gpu`，集群内也没有 NVIDIA Device Plugin。因此 GPU 工作负载无法通过
标准 Kubernetes 资源请求获得 GPU。

架构 ADR-001 已确定 `grc-parser-engine` 使用 GPU 隔离部署。本功能在不替换现有
GPU 节点池的前提下，启用 Kubernetes GPU 资源发现和调度能力，并提供可重复执行的
健康检查与回滚方式。

## User Scenarios & Testing

### User Story 1 - GPU 工作负载可被调度 (Priority: P1)

平台运维人员能够在现有 `gpupool` 上启用 GPU 资源，使声明一个 GPU 资源请求的
测试工作负载被调度到 GPU 节点，并能访问 NVIDIA GPU。

**Why this priority**: `grc-parser-engine` 的文档解析依赖 GPU。没有可调度的 GPU
资源，解析服务无法按既定架构部署。

**Independent Test**: 部署最小 GPU 测试 Pod，请求一个 `nvidia.com/gpu`，
运行 `nvidia-smi` 并确认退出码为 0，随后删除测试 Pod。

**Acceptance Scenarios**:

1. **Given** `gpupool` 节点处于 Ready 且 GPU 驱动可用, **When** GPU 能力组件部署完成,
   **Then** 该节点的 `Capacity` 和 `Allocatable` 均显示至少一个 `nvidia.com/gpu`。
2. **Given** GPU 资源已被节点上报, **When** 创建请求一个 GPU 的测试 Pod,
   **Then** Pod 被调度到 `gpupool`，`nvidia-smi` 成功识别 NVIDIA T4 GPU。
3. **Given** GPU 测试完成, **When** 清理测试资源, **Then** 集群中不残留测试 Pod，
   GPU 资源重新处于可分配状态。

---

### User Story 2 - GPU 资源保持隔离 (Priority: P2)

普通业务工作负载不会无意占用高成本 GPU 节点，GPU 能力组件也不会部署到非 GPU 节点。

**Why this priority**: GPU 节点成本高且测试环境只有一台，需要避免普通服务与解析任务
争抢节点资源。

**Independent Test**: 检查 GPU 节点隔离配置和 GPU 能力组件的实际落点，确认组件只在
`gpupool` 运行，普通工作负载未被新增配置调度到 GPU 节点。

**Acceptance Scenarios**:

1. **Given** 集群包含 system、app、GPU 和 Milvus 节点池, **When** GPU 能力组件运行,
   **Then** 其 Pod 只在带有 GPU 标识的 `gpupool` 节点上运行。
2. **Given** 普通业务 Pod 未声明 GPU 资源和对应容忍配置, **When** 调度发生,
   **Then** 该 Pod 不因本次变更被调度到 GPU 节点。
3. **Given** `grc-parser-engine` 声明 GPU 资源及 GPU 节点约束, **When** 调度发生,
   **Then** 该服务只能落在 `gpupool`。

---

### User Story 3 - 失败可诊断、变更可回滚 (Priority: P2)

平台运维人员可以识别 GPU 驱动、插件镜像或设备注册失败，并能撤销 GPU 能力组件，
且不影响其他节点池和现有业务。

**Why this priority**: GPU 能力属于集群级基础设施；失败不能扩大为全局调度或网络故障。

**Independent Test**: 验证组件状态、事件和日志可读取；执行回滚演练后确认组件资源被移除、
非 GPU 节点池保持 Ready，随后可按同一清单重新部署。

**Acceptance Scenarios**:

1. **Given** GPU 驱动或设备注册失败, **When** 运维人员查看 Pod 状态、事件和日志,
   **Then** 能看到明确失败原因，组件不会伪装为 Ready。
2. **Given** GPU 能力组件需要回滚, **When** 执行批准的卸载步骤,
   **Then** 仅移除本功能创建的资源，不修改 system、app、Milvus 节点池。
3. **Given** 回滚已完成, **When** 检查集群,
   **Then** 现有业务和 AKS 系统组件仍保持 Ready。

### Edge Cases

- GPU 驱动未安装或与节点内核不兼容时，设备插件必须报告失败，GPU 测试不得通过。
- ACR 无法拉取 GPU 组件镜像时，必须显示明确的镜像拉取错误，不得改用公网临时镜像绕过。
- GPU 节点被重建后，GPU 能力组件必须自动重新部署并重新注册设备。
- GPU 已被其他工作负载占用时，新的 GPU Pod 应保持 Pending，不得超卖设备。
- 组件升级失败时，应能回退到上一个已验证的固定版本和 digest。
- 非 GPU 节点不得因插件初始化失败产生 CrashLoop 或不可用状态。

## Requirements

### Functional Requirements

- **FR-001**: 系统 MUST 保留现有 `gpupool` 和 GPU VM，不得为本功能重建节点池。
- **FR-002**: 系统 MUST 使用经批准、固定版本的 NVIDIA Kubernetes Device Plugin，
  将物理 GPU 注册为标准扩展资源 `nvidia.com/gpu`。
- **FR-003**: GPU 能力组件镜像 MUST 先同步至项目 ACR，并使用固定 tag 和 digest；
  环境部署 MUST NOT 使用 `latest` 或运行时从未批准的公网仓库拉取。
- **FR-004**: GPU 能力组件 MUST 仅运行于 `gpupool`，不得在 system、app 或 Milvus
  节点池运行。
- **FR-005**: GPU 节点 MUST 配置可验证的工作负载隔离规则；未声明 GPU 资源和相应
  调度约束的普通业务 Pod MUST NOT 因本功能被调度到 GPU 节点。
- **FR-006**: GPU 测试工作负载 MUST 显式请求一个 `nvidia.com/gpu`，并成功执行
  `nvidia-smi`。
- **FR-007**: GPU 能力组件 MUST 使用最小权限配置，不得挂载业务 Secret，不得获得
  与设备注册无关的集群权限。
- **FR-008**: 系统 MUST 提供组件健康、节点 GPU Capacity/Allocatable、Pod 调度事件
  和插件日志的检查方式。
- **FR-009**: 系统 MUST 提供幂等的部署和回滚步骤；回滚不得删除节点池、业务 PVC
  或其他 Namespace 的资源。
- **FR-010**: 本功能 MUST NOT 引入 NVIDIA GPU Operator、AKS Preview 托管 GPU
  节点池或新的 GPU VM。
- **FR-011**: 开发环境验证通过前，本功能 MUST NOT 应用于生产环境。
- **FR-012**: 实现完成后 MUST 更新部署清单、retro 和 Project Memory。

## 非目标 / 边界

- 不创建、删除或更换 GPU 节点池。
- 不启用 AKS Preview 托管 GPU 体验。
- 不安装 NVIDIA GPU Operator。
- 不改变节点池 demand、节点数量或自动扩缩容。
- 不在本 spec 中部署 `grc-parser-engine` 业务镜像。
- 不在本 spec 中引入 DCGM/Prometheus GPU 指标栈；如后续需要，单独立项。
- 不处理生产环境 GPU 能力，生产环境复用方案前必须单独验收。
- 不修改任何服务间 REST、事件或共享模型契约。

## Key Entities

- **GPU 节点池**: 现有 `gpupool`，包含一台 `Standard_NC8as_T4_v3` Linux 节点。
- **GPU 能力组件**: 负责发现 NVIDIA 设备并向 kubelet 注册 `nvidia.com/gpu` 的
  集群组件。
- **GPU 测试工作负载**: 一次性 Pod，用于验证 GPU 调度和 `nvidia-smi`，验证后删除。
- **GPU 业务工作负载**: 后续部署的 `grc-parser-engine`，不属于本 spec 的实现范围。

## Success Criteria

### Measurable Outcomes

- **SC-001**: `gpupool` 节点的 `Capacity` 和 `Allocatable` 均显示
  `nvidia.com/gpu: 1`。
- **SC-002**: 请求一个 GPU 的测试 Pod 在 5 分钟内进入运行或完成状态。
- **SC-003**: 测试 Pod 内 `nvidia-smi` 返回退出码 0，并识别 NVIDIA T4 GPU。
- **SC-004**: GPU 能力组件只在一个 `gpupool` 节点运行，其他节点池实例数为 0。
- **SC-005**: 部署后 `kubectl get pods -A` 无新增 CrashLoopBackOff，
  四个 AKS 节点均保持 Ready。
- **SC-006**: 回滚演练仅删除本功能资源，现有业务和系统组件无中断。

## Assumptions

- 当前开发 AKS、ACR、跨节点网络和 DNS 已通过验证。
- AKS kubelet identity 已具备目标 ACR 的 `AcrPull` 权限。
- AKS 节点镜像已包含可用 NVIDIA 驱动；实现阶段仍须在安装插件前验证。
- 当前 GPU 节点 demand 为 1，本功能不改变容量策略。
- 组件镜像将通过现有 AWS EC2 构建/同步节点推送至 Azure 中国区 ACR。
- 本功能无契约影响。

## 未决问题

无。实现细节在 plan 阶段确定，但不得突破本 spec 的边界。
