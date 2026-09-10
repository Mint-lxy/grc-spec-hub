# Implementation Plan: AKS GPU 能力启用

**Branch**: `010-aks-gpu-enablement` | **Date**: 2026-09-09 |
**Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/010-aks-gpu-enablement/spec.md`

## Summary

保留开发 AKS 现有 `gpupool`，采用自管 NVIDIA Kubernetes Device Plugin 的方案：

1. 验证 AKS 节点镜像中的 NVIDIA 驱动可用。
2. 将固定版本的 Device Plugin 和 GPU 测试镜像同步到项目 ACR，记录源/目标 digest。
3. 为 `gpupool` 增加 `sku=gpu:NoSchedule` 隔离。
4. 通过最小权限 DaemonSet 将 GPU 注册为 `nvidia.com/gpu`。
5. 使用请求一个 GPU 的一次性 Pod 执行 `nvidia-smi`。
6. 演练插件卸载和重新部署，确认回滚不影响其他节点池。

不使用 NVIDIA GPU Operator，不启用 AKS Preview 托管 GPU，不重建节点池，不调整容量。

## Technical Context

**Language/Version**: Kubernetes YAML；PowerShell 兼容 Windows PowerShell 5.1；
Azure CLI 2.90.0；kubectl 1.37.0

**Primary Dependencies**: AKS Kubernetes 1.35.7；NVIDIA Kubernetes Device Plugin
v0.18.0；Azure Container Registry；现有 AKS Ubuntu 24.04 GPU 节点镜像

**Storage**: N/A；插件不创建 PVC，不读取业务数据

**Testing**: PowerShell 静态清单断言；`kubectl apply --dry-run`；节点驱动预检；
DaemonSet rollout；Capacity/Allocatable 检查；一次性 `nvidia-smi` Pod；回滚演练

**Target Platform**: Azure 中国云 China North 3；AKS `XAGPMCNINFAKS001`；
`gpupool` / `Standard_NC8as_T4_v3` / Ubuntu 24.04 / `linux/amd64`

**Project Type**: 集群基础设施配置

**Performance Goals**: 插件部署后 5 分钟内注册一个 GPU；GPU 测试 Pod 5 分钟内完成

**Constraints**:

- 测试环境 GPU demand 固定为 1。
- 所有运行镜像必须从项目 ACR 按 digest 拉取。
- 不影响 system、app、Milvus 节点池。
- 不将业务 Secret 或 Azure 凭据注入插件。
- 不依赖公网镜像在 AKS 运行时可达。

**Scale/Scope**: 一个开发 AKS、一个 GPU 节点、一个 Device Plugin DaemonSet、
一个一次性 GPU 测试 Pod

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-parser-engine | 部署基础能力 | 未来 GPU 优化部署依赖 `nvidia.com/gpu`；本 spec 不修改其业务代码或部署业务 Pod |

集群级工件暂存于 `grc-parser-engine/deploy/aks/gpu/`。当前没有独立基础设施仓库，
该路径与 GPU 唯一消费服务共同维护；如果后续建立统一部署仓库，再按独立 spec 迁移。

## 契约影响（Contract Impact · 必填）

无契约影响。本功能只改变 AKS 节点设备注册和调度能力，不新增或修改 REST、事件、
共享模型，也不改变 `grc-parser-engine` 对外接口。

对应契约草案 PR：不适用。

## Constitution Check

### Spec 先行

- 已创建并经人审批准 `specs/010-aks-gpu-enablement/spec.md`。
- plan 经独立人审批准前，不创建 tasks、不修改 AKS。

### 契约先行

- 无跨服务契约影响，无需契约变更。

### 测试先行

- 先保留当前负向基线：节点无 `nvidia.com/gpu`、集群无 Device Plugin。
- 先创建清单静态断言并验证其在实现工件缺失时失败，再创建 manifest 使其转绿。
- 集群实施先做驱动预检，插件部署后执行运行时验收。

### 服务边界

- 不新增服务依赖，不修改 service-map。
- 仅为 `grc-parser-engine` 的既有 GPU 部署边界提供基础能力。

### 记忆义务

- tasks 最后一项固定为更新 Project Memory。
- 实施完成后创建 retro，并更新 parser 服务卡、state 和必要的 watchlist。

### 人类守门点

- spec 已通过用户人审。
- 本 plan 必须通过独立人审后才能进入 tasks 和实施。
- 最终文档和服务仓库变更必须提交 Git，并由人类审核。

**结论**: 无宪法违反。

## Technical Design

### 1. 镜像供应链

Device Plugin 使用 NVIDIA 官方 `v0.18.0`，该版本来自当前 AKS 官方文档示例。
实施时执行以下步骤：

1. 在 AWS EC2 构建/同步节点拉取官方镜像。
2. 记录源镜像 digest 和 `linux/amd64` 架构。
3. 推送到：

```text
xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn/thirdparty/nvidia-k8s-device-plugin:0.18.0
```

4. DaemonSet 使用 ACR digest，不使用 tag 作为最终运行标识。
5. 选择一个最小 NVIDIA CUDA 测试镜像，同样固定并同步到 ACR。
6. 将两个镜像追加到 `docs/temp/部署镜像清单.md`。

### 2. 驱动预检

插件安装前，在 GPU 节点执行一次受控、临时的主机驱动检查：

- 目标节点必须为 `agentpool=gpupool`。
- `nvidia-smi` 必须识别 NVIDIA T4。
- 临时诊断 Pod 必须在检查后删除。
- 若驱动检查失败，停止实施；不得通过安装 GPU Operator 绕过。

### 3. GPU 节点隔离

将现有 `gpupool` 配置为：

```text
sku=gpu:NoSchedule
```

实施前记录当前节点池 taint；回滚时恢复原值。Device Plugin manifest 配置对应
toleration。后续 `grc-parser-engine` 部署必须同时声明：

- `resources.limits["nvidia.com/gpu"]`
- `nodeSelector` 或 node affinity 指向 `gpupool`
- `sku=gpu:NoSchedule` toleration

本 spec 不部署 `grc-parser-engine`。

### 4. Device Plugin DaemonSet

工件采用独立 Namespace `gpu-resources`，DaemonSet 关键约束如下：

- 镜像使用 ACR digest。
- `nodeSelector: accelerator=nvidia`。
- 容忍 `sku=gpu:NoSchedule`。
- `priorityClassName: system-node-critical`。
- `FAIL_ON_INIT_ERROR=true`，驱动或设备异常时明确失败。
- `allowPrivilegeEscalation=false`。
- 删除全部 Linux capabilities。
- 仅挂载 `/var/lib/kubelet/device-plugins` hostPath。
- 不创建 Service、Ingress、PVC、Secret 或业务 RBAC。
- RollingUpdate，期望 `DESIRED=1`、`READY=1`。

### 5. 测试先行与门禁

在 `grc-parser-engine/deploy/aks/gpu/tests/` 提供 PowerShell 检查脚本，先断言 manifest：

- 固定 ACR digest。
- 禁止 `latest` 和公网运行镜像。
- Namespace 为 `gpu-resources`。
- 仅选择 NVIDIA 节点。
- 包含 GPU taint toleration。
- 最小安全上下文和唯一 hostPath。
- 不包含 Secret、PVC、Service 或 Ingress。

执行顺序：

1. manifest 不存在时运行检查脚本，保存预期失败结果。
2. 创建 manifest 后检查转绿。
3. `kubectl apply --dry-run=client`。
4. `kubectl apply --dry-run=server`。
5. 人工确认变更范围后才正式 apply。

### 6. 运行时验收

正式部署后执行：

1. 等待 DaemonSet rollout 成功。
2. 检查 Pod 仅运行在 `gpupool`。
3. 检查节点 `Capacity/Allocatable` 为 `nvidia.com/gpu: 1`。
4. 从 ACR 按 digest运行一次性 GPU 测试 Pod。
5. 测试 Pod 请求一个 GPU并执行 `nvidia-smi`。
6. 检查输出包含 NVIDIA T4，退出码为 0。
7. 删除测试 Pod。
8. 检查所有节点 Ready、集群无新增 CrashLoopBackOff。

### 7. 回滚

回滚顺序：

1. 删除一次性 GPU 测试 Pod。
2. 删除本功能的 Device Plugin DaemonSet 和 Namespace。
3. 确认 `nvidia.com/gpu` 不再由插件上报。
4. 将 `gpupool` taint 恢复为实施前值。
5. 确认四个节点仍为 Ready，系统组件无新增异常。
6. 重新应用 manifest，重复运行时验收，证明可恢复。

回滚不得删除节点池、VM、ACR 镜像、PVC 或其他 Namespace 资源。

## Project Structure

### Documentation (this feature)

```text
grc-spec-hub/
└── specs/010-aks-gpu-enablement/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── retro.md
```

### Source Code

```text
grc-parser-engine/
└── deploy/aks/gpu/
    ├── README.md
    ├── namespace.yaml
    ├── nvidia-device-plugin.yaml
    ├── gpu-smoke-test.yaml
    └── tests/
        └── validate-gpu-manifests.ps1

ai-portal/
└── docs/temp/
    ├── 部署服务相关任务清单.md
    └── 部署镜像清单.md
```

**Structure Decision**: 集群运行工件放在 GPU 消费服务 `grc-parser-engine` 的
`deploy/aks/gpu/`，需求、计划、任务与复盘放在 `grc-spec-hub`，跨项目调研清单继续放在
当前工作区 `docs/temp/`，评审定稿后再迁移。

## Deployment Order

1. plan 人审并提交。
2. 生成并分析 tasks。
3. 固定并同步两个 NVIDIA 镜像到 ACR。
4. 先写并运行静态检查，确认红灯。
5. 创建 manifest 和 Runbook，使静态检查、dry-run 转绿。
6. 验证 GPU 节点驱动。
7. 应用 GPU taint。
8. 部署 Device Plugin。
9. 执行 GPU 运行时验收。
10. 执行回滚和重新部署演练。
11. 更新部署清单、retro 和 Project Memory。
12. 提交各仓库变更，等待人审。

## Risks and Mitigations

| 风险 | 缓解措施 |
|------|----------|
| 节点驱动缺失或不兼容 | 插件安装前执行主机 `nvidia-smi`；失败即停止 |
| 公网 NVIDIA 镜像不可达 | 所有运行镜像先同步到项目 ACR并按 digest引用 |
| 普通 Pod 占用 GPU 节点 | GPU taint + parser 显式 toleration/nodeSelector |
| 插件部署到非 GPU 节点 | `accelerator=nvidia` nodeSelector + 静态断言 |
| 插件异常影响集群 | 独立 Namespace、无业务 RBAC、仅一个 hostPath、先 dry-run |
| GPU 节点重建后能力丢失 | DaemonSet自动重建；保留幂等 Runbook和固定镜像 |
| Preview 方案带来不确定性 | 明确排除 AKS 托管 GPU Preview和 GPU Operator |

## Complexity Tracking

无宪法违反，无需复杂度豁免。
