# Retro: AKS GPU 能力启用

**Date**: 2026-09-09

**Spec**: `specs/010-aks-gpu-enablement`

**Implementation commit**: `grc-parser-engine@513d51d`

## 结果

开发 AKS `XAGPMCNINFAKS001` 已在现有 `gpupool` 上启用自管 NVIDIA Device
Plugin。GPU 节点保持原 VM 和节点数，未采用 AKS Preview 托管 GPU，也未引入
GPU Operator。

最终状态：

- `gpupool`：`Standard_NC8as_T4_v3`，Ready。
- 持久 taint：`sku=gpu:NoSchedule`。
- NVIDIA Device Plugin：v0.18.0，单实例 Ready。
- GPU Capacity/Allocatable：`nvidia.com/gpu: 1`。
- GPU smoke test：识别 `Tesla T4`、driver `580.159.04`、显存 `16384 MiB`。
- 所有运行镜像从项目 ACR 按 digest 拉取。
- 四个 AKS 节点保持 Ready，无新增 CrashLoopBackOff 或镜像拉取错误。

## 完成的工件

`grc-parser-engine/deploy/aks/gpu/` 新增：

- `namespace.yaml`
- `nvidia-device-plugin.yaml`
- `gpu-smoke-test.yaml`
- `tests/validate-gpu-manifests.ps1`
- `README.md`

镜像：

- NVIDIA Device Plugin v0.18.0：
  `sha256:16b3c0dde8d6cbcb68809b769720cf0d9572cd717fbff266ec3202b3c8497159`
- NVIDIA CUDA smoke：
  `sha256:e2adc10b81bc6e63d138b1073823dc892222f9d3bbbbb9cc4d98cbef62949440`

## 验证

1. 实施前确认节点未上报 GPU、集群内无 Device Plugin。
2. 先创建静态清单测试；manifest 缺失时测试按预期失败。
3. manifest 创建后静态测试转绿。
4. client/server dry-run 通过。
5. 宿主机驱动预检成功。
6. Device Plugin rollout 成功。
7. GPU smoke test 首次执行成功。
8. 无 toleration 的普通测试 Pod 因 `untolerated taint` 保持 Pending。
9. 完成插件卸载、taint 恢复和集群健康检查。
10. 使用相同工件重装后，第二次 GPU smoke test 成功。
11. 所有临时测试 Pod 已删除。

服务仓库完整 pytest 套件也被执行，但当前基线存在与本次部署工件无关的失败：

- 143 passed
- 82 failed
- 5 errors
- 2 skipped

失败集中于现有 Parser API、MinerU、Docling 测试和测试环境配置。本次没有修改应用代码，
相关失败不在本 spec 中处理。GPU manifest 专项测试和 Kubernetes dry-run 均通过。

## 与 plan 的偏差

1. Server dry-run 无法在尚未存在的 Namespace 中校验 namespace-scoped 资源，因此先实际
   创建空的 `gpu-resources` Namespace，再执行 Device Plugin 和 smoke Pod 的
   server dry-run。
2. 通过 AKS API 清空持久 taint 后，现有节点对象仍短暂保留 taint；回滚步骤补充
   `kubectl taint ...-` 清理当前节点。AKS 模型已为空，因此新节点不会重新带上该 taint。
3. Device Plugin 删除后，kubelet 暂时保留 GPU Capacity=1、Allocatable=0；这仍满足
   “GPU 不可调度”的回滚目的。重装插件后 Allocatable 恢复为 1。

## 新规则与事实

- 当前 AKS GPU 节点镜像已经包含可用 NVIDIA driver 580.159.04。
- 现有节点池采用“AKS 提供驱动、项目自管 Device Plugin”的模式。
- GPU 工作负载必须同时声明 GPU limit、`gpupool` 调度约束和 GPU taint toleration。
- Windows PowerShell 不能可靠地把空字符串传给 Azure CLI 的 `--node-taints`；
  Runbook 使用 Python subprocess 保留空参数。
- NVIDIA 两个镜像未提供可机器读取的许可证 label，生产使用前仍需正式许可证审查。

## 后续事项

- `grc-parser-engine` 业务部署应复用本 spec 的 GPU limit、nodeSelector 和 toleration。
- 生产环境部署 GPU 前需重新验证驱动、插件、镜像 digest 和 taint。
- GPU 指标/DCGM 不在本 spec 范围；如运维要求 GPU 温度、利用率和故障告警，单独立项。
- NVIDIA 镜像许可证需纳入正式依赖许可证审查。
