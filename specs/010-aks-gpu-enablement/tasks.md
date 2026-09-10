# Tasks: AKS GPU 能力启用

**Input**: `specs/010-aks-gpu-enablement/spec.md`、`plan.md`

**Prerequisites**: spec 与 plan 已分别完成人审并提交；无契约变更。

**Tests**: 本功能必须遵循测试先行。先建立当前负向基线和静态清单测试，确认红灯后再创建
manifest；集群实施必须完成驱动预检、运行时验收和回滚演练。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行，修改不同文件且无前置依赖。
- **[US1/US2/US3]**: 对应 spec 中的用户故事。

## Phase 1: Setup

- [x] T001 [US1] 在开发 AKS 记录实施前基线：`gpupool` Ready、无
  `nvidia.com/gpu`、无 NVIDIA Device Plugin，并将结果写入
  `grc-parser-engine/deploy/aks/gpu/README.md`
- [x] T002 [P] [US1] 在 AWS EC2 上锁定 NVIDIA Device Plugin `v0.18.0` 和最小
  CUDA 测试镜像的源 digest/架构，目标命名写入 `docs/temp/部署镜像清单.md`
- [x] T003 [P] [US3] 记录 `gpupool` 当前 taint、节点和集群健康基线，写入
  `grc-parser-engine/deploy/aks/gpu/README.md`

---

## Phase 2: Foundational - Tests First

**⚠️ CRITICAL**: 本阶段测试必须在 manifest 创建前运行并失败。

- [x] T004 [US1] 先创建
  `grc-parser-engine/deploy/aks/gpu/tests/validate-gpu-manifests.ps1`，断言固定 ACR
  digest、禁止 `latest`/公网运行镜像、Namespace、nodeSelector、toleration、
  securityContext 和 hostPath
- [x] T005 [US1] 在 manifest 尚不存在时执行 `validate-gpu-manifests.ps1`，确认并记录
  预期失败（红灯）
- [x] T006 [P] [US3] 在验证脚本中增加禁止 Secret、PVC、Service、Ingress 和非预期
  hostPath 的负向断言

**Checkpoint**: 静态测试已建立且红灯，才能创建 manifest。

---

## Phase 3: User Story 1 - GPU 工作负载可被调度 (Priority: P1)

**Goal**: 在现有 `gpupool` 上注册一个可调度 GPU，并通过 `nvidia-smi`。

**Independent Test**: 请求一个 `nvidia.com/gpu` 的一次性 Pod 在 `gpupool` 完成
`nvidia-smi`，退出码为 0。

- [x] T007 [P] [US1] 将 Device Plugin `v0.18.0` 同步到
  `XAGPMCNINFCTREG001/thirdparty/nvidia-k8s-device-plugin:0.18.0`，记录 ACR digest
- [x] T008 [P] [US1] 将固定 CUDA 测试镜像同步到
  `XAGPMCNINFCTREG001/thirdparty/`，记录 ACR digest
- [x] T009 [US1] 创建 `grc-parser-engine/deploy/aks/gpu/namespace.yaml`
- [x] T010 [US1] 创建
  `grc-parser-engine/deploy/aks/gpu/nvidia-device-plugin.yaml`，使用 ACR digest、
  `accelerator=nvidia`、`sku=gpu:NoSchedule` toleration 和最小安全上下文
- [x] T011 [US1] 创建 `grc-parser-engine/deploy/aks/gpu/gpu-smoke-test.yaml`，
  请求一个 GPU，在 `gpupool` 执行 `nvidia-smi`
- [x] T012 [US1] 运行静态清单测试、`kubectl apply --dry-run=client` 和
  `kubectl apply --dry-run=server`，使测试转绿
- [x] T013 [US1] 使用临时受控诊断 Pod 在 GPU 节点执行宿主机 `nvidia-smi`，确认驱动
  可用后删除诊断 Pod
- [x] T014 [US1] 为现有 `gpupool` 添加 `sku=gpu:NoSchedule`，记录变更前后状态
- [x] T015 [US1] 部署 Namespace 和 Device Plugin，等待 DaemonSet rollout 成功
- [x] T016 [US1] 验证 `gpupool` 的 Capacity/Allocatable 出现
  `nvidia.com/gpu: 1`
- [x] T017 [US1] 从 ACR 按 digest 部署一次性 GPU smoke Pod，验证 NVIDIA T4 和
  `nvidia-smi` 退出码 0，随后删除 smoke Pod

**Checkpoint**: US1 独立验收通过，GPU 可被 Kubernetes 调度。

---

## Phase 4: User Story 2 - GPU 资源保持隔离 (Priority: P2)

**Goal**: Device Plugin 仅运行于 GPU 节点，普通业务不误用 GPU 节点。

**Independent Test**: 检查 taint、DaemonSet 落点和普通 Pod 调度行为。

- [x] T018 [US2] 验证 Device Plugin 仅有一个实例且运行在 `gpupool`
- [x] T019 [US2] 创建不带 GPU toleration 的临时普通测试 Pod，确认本次配置不会将其
  调度到 `gpupool`，随后删除测试 Pod
- [x] T020 [US2] 在 `grc-parser-engine/deploy/aks/gpu/README.md` 记录未来 parser
  工作负载必须声明的 GPU limit、nodeSelector/affinity 和 toleration

**Checkpoint**: US2 独立验收通过，GPU 节点隔离有效。

---

## Phase 5: User Story 3 - 失败可诊断、变更可回滚 (Priority: P2)

**Goal**: GPU 能力具备明确诊断和可重复回滚能力。

**Independent Test**: 删除插件和 taint 后集群仍健康，再按同一工件恢复并重复 GPU 测试。

- [x] T021 [US3] 在 `grc-parser-engine/deploy/aks/gpu/README.md` 编写部署、诊断、升级、
  回滚和重装 Runbook
- [x] T022 [US3] 执行回滚：删除本功能 Namespace/DaemonSet，恢复实施前 taint，并验证
  四个节点和系统组件保持健康
- [x] T023 [US3] 按 Runbook 重新添加 taint、部署插件并再次执行 GPU smoke test
- [x] T024 [US3] 验证 GPU 节点重获 `nvidia.com/gpu: 1`，集群无新增
  CrashLoopBackOff，删除全部临时测试资源

**Checkpoint**: US3 独立验收通过，部署与回滚均可重复。

---

## Phase 6: Documentation and Closure

- [x] T025 [P] 更新 `docs/temp/部署镜像清单.md`，补充 NVIDIA 两个镜像的源/目标
  digest、架构、许可证和 AKS 验证结果
- [x] T026 [P] 更新 `docs/temp/部署服务相关任务清单.md`，标记 GPU P0 完成并记录验收
- [x] T027 运行 `grc-parser-engine` 适用门禁、密钥扫描和 YAML/PowerShell 检查
- [x] T028 提交 `grc-parser-engine` 部署工件，提交信息引用
  `specs/010-aks-gpu-enablement`
- [x] T029 在 `grc-spec-hub/specs/010-aks-gpu-enablement/retro.md` 记录实施偏差、GPU
  运行事实和后续监控建议
- [x] T030 **更新 Project Memory**：更新 `memory/now/services/grc-parser-engine.md`、
  `memory/now/state.md` 及必要的 watchlist，提交后等待人审

## Dependencies & Execution Order

1. T001-T003 建立基线。
2. T004-T006 建立红灯测试，阻塞所有 manifest 实现。
3. T007-T008 完成镜像供应链后，T009-T012 才能引用最终 digest。
4. T013 驱动预检通过后，才能执行 T014-T016。
5. US1 通过后执行 T017-T020 的隔离验证。
6. US1/US2 通过后执行 T021-T024 回滚演练。
7. 所有运行时验收完成后执行 T025-T030。

## Parallel Opportunities

- T002 与 T003 可并行。
- T006 可与 T004 的基础结构编写并行，但合并到同一脚本时顺序执行。
- T007 与 T008 可并行同步两个镜像。
- T025 与 T026 可并行更新不同文档。

## Requirement Coverage

| Requirement | Tasks |
|-------------|-------|
| FR-001 保留现有节点池 | T001、T003、T022 |
| FR-002 注册 `nvidia.com/gpu` | T007、T010、T015、T016 |
| FR-003 固定 ACR 镜像 | T002、T007、T008、T010、T011、T025 |
| FR-004 仅运行于 `gpupool` | T004、T010、T018 |
| FR-005 GPU 节点隔离 | T014、T019、T020 |
| FR-006 `nvidia-smi` 验收 | T011、T017、T023 |
| FR-007 最小权限 | T004、T006、T010、T012 |
| FR-008 可诊断 | T001、T013、T016、T018、T021、T024 |
| FR-009 幂等部署与回滚 | T021、T022、T023、T024 |
| FR-010 不引入 Operator/Preview/新 VM | T004、T006、T010、T027 |
| FR-011 仅开发环境 | T001、T012、T027 |
| FR-012 文档、retro、Memory | T025、T026、T029、T030 |

## Implementation Strategy

1. 先完成 US1，交付最小可用 GPU 调度能力。
2. 再完成 US2，确保成本隔离。
3. 最后完成 US3，证明变更可恢复。
4. 任一阶段失败均停止后续步骤并按 Runbook 回滚，不使用公网镜像或 GPU Operator绕过。
