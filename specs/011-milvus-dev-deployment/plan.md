# Implementation Plan: Milvus 开发环境部署

**Branch**: `011-milvus-dev-deployment` | **Date**: 2026-09-09 |
**Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/011-milvus-dev-deployment/spec.md`

## Summary

在开发 AKS 的专用 `milvuspool` 上部署 Milvus Standalone 2.5.12：

1. 固定并 vendoring 官方 Helm Chart 4.2.49。
2. 使用 Rocksmq、单副本 etcd、单副本 MinIO。
3. 将 Chart 实际使用的全部镜像同步到项目 ACR并按 digest引用。
4. 为 Milvus、etcd、MinIO 分别创建 64 GiB Premium SSD PVC。
5. 为 `milvuspool` 增加 `sku=milvus:NoSchedule`，三个组件均显式调度到该节点池。
6. 使用预创建 Kubernetes Secret 提供 MinIO 和 Milvus 凭据，不把敏感值写入 Git。
7. 使用自动化客户端 Job 完成密码初始化、写入/查询、逐组件重建恢复与清理。
8. 完成 Helm rollback 和重装演练，保留 PVC。

## Technical Context

**Language/Version**: Helm Chart/YAML；PowerShell 兼容 Windows PowerShell 5.1；
Python 3.12 smoke client；Azure CLI 2.90.0；kubectl 1.37.0；Helm 4.2.4

**Primary Dependencies**:

- Milvus Helm Chart 4.2.49 / appVersion 2.5.12
- Milvus 2.5.12
- etcd 3.5.18-r1（Chart 兼容镜像）
- MinIO `RELEASE.2025-09-07T16-13-09Z`
- pymilvus 2.5.x smoke client
- Azure Disk CSI `managed-csi-premium`

**Storage**: 三个独立 64 GiB、RWO、Premium SSD PVC；Helm resource-policy `keep`

**Testing**: PowerShell 静态断言；Chart checksum；`helm lint/template`；
Kubernetes server dry-run；Pod/PVC readiness；pymilvus CRUD/search smoke；
Milvus/etcd/MinIO 逐个重建恢复；Helm rollback/reinstall

**Target Platform**: Azure 中国云 China North 3；AKS `XAGPMCNINFAKS001`；
`milvuspool` / `Standard_E4s_v5` / 3860m CPU / 32098164Ki memory

**Project Type**: 集群基础设施和服务依赖部署

**Performance Goals**: 初次部署 15 分钟内 Ready；smoke test 5 分钟内完成；
单组件 Pod 重建后 10 分钟内恢复查询

**Constraints**:

- 测试环境 `milvuspool` demand 固定为 1，无自动扩缩容。
- 单节点维护期间允许短暂不可用，但不得丢失 PVC 数据。
- AKS 运行时不得访问未批准的公网镜像。
- 不提交 Secret、密码、Token 或明文连接串。
- 不使用 LoadBalancer、Ingress 或 NodePort 暴露 Milvus。

**Scale/Scope**: 一个 Namespace、一个 Helm release、三个业务 Pod、三个 PVC、
一个短生命周期凭据初始化 Job、一个短生命周期 smoke Job

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-knowledge-engine | 部署依赖 | Milvus 是知识引擎主向量数据库；本 spec 只交付 Milvus 基础设施和验收客户端，不修改知识引擎业务代码 |

部署工件放在 `grc-knowledge-engine/deploy/aks/milvus/`。Milvus 由知识引擎消费，
且当前没有独立基础设施仓库；后续若建立统一部署仓库，再通过独立 spec 迁移。

## 契约影响（Contract Impact · 必填）

无契约影响。Milvus 是 `grc-knowledge-engine` 的内部基础设施依赖，不向其他服务暴露
平台业务契约，不新增或修改 REST、事件或共享模型。

对应契约草案 PR：不适用。

## Constitution Check

### Spec 先行

- `specs/011-milvus-dev-deployment/spec.md` 已经人审批准。
- 本 plan 经独立人审批准前，不生成 tasks、不修改 AKS。

### 契约先行

- 无跨服务契约影响。

### 测试先行

- 先创建 Chart/values/rendered manifest 静态测试，确认工件缺失时失败。
- 再创建 values、Secret 模板、smoke client 和 Kubernetes Job。
- 集群实施前必须通过 chart lint、template、镜像、PVC、调度和外部暴露检查。

### 服务边界

- Milvus 作为 `grc-knowledge-engine` 私有基础设施，只暴露 ClusterIP。
- 不新增 service-map 依赖。

### 记忆义务

- tasks 最后一项固定为更新 Project Memory。
- 实施后创建 retro，并更新 knowledge-engine 服务卡、state 和 watchlist。

### 人类守门点

- spec 已通过用户人审。
- plan 必须独立人审后才能进入 tasks 和实施。
- 最终服务仓库 PR 和 Memory PR 必须由人类批准。

**结论**: 无宪法违反。

## Technical Design

### 1. Chart 固定与供应链

官方 Chart：

```text
milvus/milvus 4.2.49
appVersion 2.5.12
SHA256 7DEC3D23171B0B096F15587535F60A3EABD5856C576CFC799F7C4766AA7F2596
```

将原始 `milvus-4.2.49.tgz` vendoring 到：

```text
grc-knowledge-engine/deploy/aks/milvus/charts/milvus-4.2.49.tgz
```

静态测试必须校验 Chart 文件 SHA256。部署和渲染只使用仓库内 Chart，不在执行期间从
公网 Helm repo 下载。

### 2. 镜像固定

已具备：

| 组件 | ACR digest |
|------|------------|
| Milvus 2.5.12 | `thirdparty/milvus@sha256:7ababcafb7ba066ff40a2d694e6493774ecd301e23e225102f0e3375c9bdd5b7` |
| MinIO | `thirdparty/minio@sha256:52dfd5c0bbd38d3219f2058c7af216d9f9a27a994b7b5baad09bbd38866015ff` |

实施时补齐：

- Chart 兼容的 `milvusdb/etcd:3.5.18-r1` 镜像。
- 基于 Python 3.12 + pymilvus 2.5.x 的最小验收镜像。

Helm Chart 使用 `repository:tag` 拼接镜像。values 将 tag 设置为
`<fixed-tag>@sha256:<digest>`，渲染得到合法的 `repository:tag@digest`。

`helm template` 后枚举全部 `image:`，必须全部满足：

```text
xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn/...@sha256:<64 hex>
```

### 3. 开发拓扑

```text
grc-knowledge-engine (后续部署)
          |
          v
Milvus Standalone 2.5.12
  |-- Rocksmq（Milvus PVC）
  |-- etcd ×1（etcd PVC）
  `-- MinIO ×1（MinIO PVC）
```

明确关闭：

- `cluster.enabled`
- Pulsar
- Kafka
- Woodpecker
- Streaming Node
- Attu
- Ingress

### 4. Namespace、Release 与服务

| 项目 | 值 |
|------|----|
| Namespace | `milvus` |
| Helm release | `milvus` |
| Service | `milvus`（Chart 实际 fullname 由模板测试锁定） |
| 类型 | ClusterIP |
| gRPC | 19530 |
| health/metrics | 9091 |

不创建公网 IP、Ingress、NodePort 或 LoadBalancer。

### 5. 调度隔离

为 `milvuspool` 持久配置：

```text
sku=milvus:NoSchedule
```

Milvus、etcd、MinIO 和验收 Job 均配置：

```yaml
nodeSelector:
  agentpool: milvuspool
tolerations:
  - key: sku
    operator: Equal
    value: milvus
    effect: NoSchedule
```

变更前记录 taint；回滚时先清除 AKS 节点池模型，再清除现有节点对象残留 taint。

### 6. 资源预算

| 组件 | CPU request | CPU limit | Memory request | Memory limit |
|------|------------:|----------:|---------------:|-------------:|
| Milvus | 1500m | 2500m | 8 GiB | 16 GiB |
| etcd | 250m | 500m | 512 MiB | 1 GiB |
| MinIO | 250m | 500m | 1 GiB | 2 GiB |
| 合计 | 2000m | 3500m | 9.5 GiB | 19 GiB |

总 requests 低于节点可分配的 3860m CPU / 约 30.6 GiB 内存，为系统 DaemonSet 和
短生命周期验收 Job保留余量。验收 Job request 不超过 100m CPU / 256 MiB。

### 7. 持久化

| PVC | 用途 | StorageClass | AccessMode | 容量 |
|-----|------|--------------|------------|-----:|
| Milvus | Rocksmq 和本地数据目录 | `managed-csi-premium` | RWO | 64 GiB |
| etcd | 元数据 | `managed-csi-premium` | RWO | 64 GiB |
| MinIO | 对象数据 | `managed-csi-premium` | RWO | 64 GiB |

三个 PVC 均添加：

```yaml
helm.sh/resource-policy: keep
```

普通 upgrade、rollback 和 uninstall 不执行 PVC 删除。数据销毁必须通过独立命令并要求
显式确认 PVC 名称。

### 8. Secret 与认证

仓库只提供 Secret 创建脚本和键名约定，不提供实际值。

Secret `milvus-credentials` 包含：

- `accesskey`
- `secretkey`
- `root-password`

创建脚本使用密码学安全随机值，并通过 stdin/临时内存变量调用 `kubectl create secret`；
不得写入 `.env`、values、日志或 Git。

MinIO 使用 `existingSecret: milvus-credentials`。Milvus 通过
`standalone.extraEnv[].valueFrom.secretKeyRef` 读取同一 MinIO access/secret key，
避免 Chart 默认 ConfigMap 中出现真实凭据。

Milvus 配置启用 authorization。凭据初始化 Job采取幂等逻辑：

1. 先使用 Secret 中的新 root 密码连接。
2. 如果已可连接则成功退出。
3. 否则使用 Milvus 初始 root 凭据连接并立即轮换为 Secret 值。
4. 轮换成功后使用新密码复连。

业务接入前必须确认默认 root 凭据已失效。

### 9. 验收客户端

在 `deploy/aks/milvus/smoke/` 提供：

- 最小 Python 3.12 Dockerfile。
- 固定版本 pymilvus 2.5.x。
- `bootstrap_auth.py`。
- `smoke_test.py`。
- 对应 Kubernetes Job manifests。

smoke test：

1. 生成唯一 collection 名。
2. 创建固定维度 schema。
3. 插入已知向量。
4. flush/load/index。
5. 查询并断言第一条主键。
6. 删除 collection。
7. 任何异常以非零退出码结束。

### 10. 测试先行和静态门禁

先创建 `tests/validate-milvus-deployment.ps1`，在工件缺失时确认失败，再实现：

- Chart SHA256。
- Chart 版本和 appVersion。
- Standalone/Rocksmq、etcd=1、MinIO standalone。
- 禁止 Pulsar/Kafka/Woodpecker/Attu/Ingress。
- 全镜像 ACR digest。
- 三个 64 GiB Premium PVC 及 keep annotation。
- nodeSelector/toleration。
- requests/limits 和总 request 预算。
- ClusterIP、无外部暴露。
- values 中无 Secret 明文。
- smoke Job 唯一 collection 和清理行为。

门禁顺序：

1. PowerShell 静态测试。
2. `helm lint`。
3. `helm template`。
4. 渲染 YAML secret scan。
5. `kubectl apply --dry-run=server`。
6. `helm upgrade --install --dry-run=server`。

### 11. 部署与验收

1. 驱动外无需新增平台资源。
2. 创建 Namespace 和 Secret。
3. 添加 `milvuspool` taint。
4. `helm upgrade --install --atomic --wait --timeout 15m`。
5. 验证三个 Pod Ready、三个 PVC Bound、所有 Pod 位于 `milvuspool`。
6. 执行认证初始化 Job。
7. 执行 CRUD/search smoke Job。
8. 依次删除 Milvus、etcd、MinIO Pod；每次等待恢复并重新查询保留的测试数据。
9. 删除验收 collection 和临时 Job。
10. 检查四个 AKS 节点及其他 Namespace 无新增异常。

持久化测试使用专用 collection，并在三次重建全部完成后统一删除。

### 12. 回滚

1. 记录当前 Helm revision、Pod 和 PVC 状态。
2. 使用一次无害 values annotation 变更产生新 revision。
3. 执行 `helm rollback --wait --atomic` 回到上一 revision。
4. 重跑查询，确认数据保持。
5. 卸载演练仅在最终批准后执行；如执行，先记录 PVC，再 `helm uninstall`，确认三个 PVC
   保留，随后使用相同 values 重装并复测。
6. 清除数据必须使用独立脚本，要求输入 Namespace 和 PVC 全名二次确认。

回滚不自动删除 Secret、PVC、PV 或 Azure Disk。

## Project Structure

### Documentation (this feature)

```text
grc-spec-hub/
└── specs/011-milvus-dev-deployment/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── retro.md
```

### Source Code

```text
grc-knowledge-engine/
└── deploy/aks/milvus/
    ├── README.md
    ├── values-dev.yaml
    ├── charts/
    │   └── milvus-4.2.49.tgz
    ├── scripts/
    │   └── New-MilvusSecrets.ps1
    ├── smoke/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── bootstrap_auth.py
    │   ├── smoke_test.py
    │   ├── bootstrap-auth-job.yaml
    │   └── smoke-test-job.yaml
    └── tests/
        └── validate-milvus-deployment.ps1

ai-portal/
└── docs/temp/
    ├── 部署服务相关任务清单.md
    └── 部署镜像清单.md
```

**Structure Decision**: Milvus 是 knowledge-engine 的私有基础设施依赖，运行工件归
`grc-knowledge-engine/deploy/aks/milvus/`；spec 生命周期工件归 hub。

## Deployment Order

1. plan 人审并提交。
2. 生成 tasks并执行一致性检查。
3. 同步 knowledge-engine 仓库到最新远端基线。
4. 先写静态测试并确认红灯。
5. vendoring Chart，补齐并推送 Chart 兼容 etcd 和 smoke 客户端镜像。
6. 创建 values、Secret 脚本、smoke 客户端和 Job。
7. 完成 lint/template/dry-run 门禁。
8. 创建 Secret并添加 `milvuspool` taint。
9. Helm 原子部署。
10. 认证初始化、CRUD/search、逐组件重建恢复测试。
11. Helm rollback/重装演练。
12. 更新文档、retro 和 Project Memory。
13. 提交 Git并创建 PR。

## Risks and Mitigations

| 风险 | 缓解措施 |
|------|----------|
| 单节点故障导致暂时不可用 | 明确开发环境非 HA；通过 PVC 和重建恢复验证保证数据不丢 |
| Chart 子镜像未进入 ACR | 渲染后枚举全部 image，非 ACR digest 即门禁失败 |
| etcd 镜像与 Bitnami 子 Chart 不兼容 | 使用 Chart 默认兼容的 `milvusdb/etcd:3.5.18-r1`，不复用 coreos 镜像 |
| 示例凭据进入 ConfigMap/Git | 使用预创建 Secret + env secretKeyRef；渲染 YAML 执行敏感值扫描 |
| PVC 被 Helm uninstall 删除 | 三个 PVC 均加 resource-policy keep；数据删除独立且二次确认 |
| 资源挤压系统 Pod | 总 requests 仅 2000m/9.5GiB；部署前后检查节点和系统 Pod |
| 新 MinIO 与旧 Chart 兼容性 | 先完成 chart render、启动探针和 Milvus CRUD/persistence 验收 |
| root 默认密码未轮换 | 幂等初始化 Job复连验证；未完成前不允许业务接入 |
| Helm 4 与旧 Chart 差异 | 同时执行 lint、template、server dry-run；失败时使用固定 Helm 3 兼容版本 |

## Complexity Tracking

无宪法违反，无需复杂度豁免。
