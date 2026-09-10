# Tasks: Milvus 开发环境部署

**Input**: `specs/011-milvus-dev-deployment/spec.md`、`plan.md`

**Prerequisites**: spec 与 plan 已分别完成人审；无契约变更。

**Tests**: 必须先建立 Chart/values/smoke 的失败测试，再创建实现工件。集群实施必须完成
CRUD/search、逐组件重建、隔离、Helm rollback 和卸载重装验证。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行且修改不同文件。
- **[US1/US2/US3/US4]**: 对应 spec 用户故事。

## Phase 1: Setup

- [x] T001 同步 `grc-knowledge-engine` 的 `feature/release260831` 到最新远端基线，确认工作区干净
- [x] T002 [P] [US1] 记录 `milvuspool` 资源、taint、现有 Pod、Namespace 和 StorageClass
  基线到 `grc-knowledge-engine/deploy/aks/milvus/README.md`
- [x] T003 [P] [US4] 将官方 `milvus-4.2.49.tgz` vendoring 到
  `grc-knowledge-engine/deploy/aks/milvus/charts/`，记录 SHA256

---

## Phase 2: Foundational - Tests First

**⚠️ CRITICAL**: T004/T005 必须在实现工件缺失时先失败。

- [x] T004 [US1] 创建
  `grc-knowledge-engine/deploy/aks/milvus/tests/validate-milvus-deployment.ps1`，
  检查 Chart SHA、拓扑、ACR digest、PVC、调度、资源预算、Secret 和外部暴露
- [x] T005 [US1] 在 values 和 smoke 工件尚未创建时运行静态测试，确认红灯
- [x] T006 [P] [US1] 创建 `grc-knowledge-engine/deploy/aks/milvus/smoke/tests/`
  下的 pytest，先定义凭据初始化幂等性、CRUD/search、失败非零退出和 collection 清理行为
- [x] T007 [US1] 在 smoke 实现缺失时运行 pytest，确认红灯

**Checkpoint**: 静态测试与 smoke 单测均已红灯。

---

## Phase 3: User Story 1 - 知识引擎可使用 Milvus (Priority: P1)

**Goal**: 部署可认证连接、可执行向量 CRUD/search 的 Milvus。

- [x] T008 [P] [US1] 将 Chart 兼容的 `milvusdb/etcd:3.5.18-r1` 同步到项目 ACR并记录 digest
- [x] T009 [P] [US1] 创建最小 pymilvus 2.5.x smoke 镜像并推送项目 ACR，记录 digest
- [x] T010 [US1] 创建 `grc-knowledge-engine/deploy/aks/milvus/values-dev.yaml`，
  固定 Chart 模式、镜像 digest、资源、PVC、调度和 probe
- [x] T011 [US1] 创建 `grc-knowledge-engine/deploy/aks/milvus/scripts/New-MilvusSecrets.ps1`，
  仅在内存中生成凭据并幂等创建 `milvus-credentials`
- [x] T012 [US1] 实现
  `grc-knowledge-engine/deploy/aks/milvus/smoke/bootstrap_auth.py` 和
  `smoke_test.py`，使 T006 测试转绿
- [x] T013 [US1] 创建 smoke Dockerfile、requirements 和
  `bootstrap-auth-job.yaml`、`smoke-test-job.yaml`
- [x] T014 [US1] 运行静态测试、smoke pytest、`helm lint`、`helm template`、
  rendered manifest secret scan 和 Kubernetes server dry-run

**Checkpoint**: 所有部署工件门禁通过，尚未部署业务组件。

---

## Phase 4: AKS Install and CRUD Acceptance (US1)

- [x] T015 [US1] 创建 `milvus` Namespace 和 `milvus-credentials` Secret
- [x] T016 [US3] 为 `milvuspool` 添加持久 taint `sku=milvus:NoSchedule`
- [x] T017 [US1] 使用 vendored Chart执行
  `helm upgrade --install --atomic --wait --timeout 15m`
- [x] T018 [US1] 验证 Milvus、etcd、MinIO 各一个 Pod Ready，三个 64 GiB PVC Bound，
  所有组件位于 `milvuspool`
- [x] T019 [US1] 执行幂等认证初始化 Job，确认默认 root 密码失效、新密码可连接
- [x] T020 [US1] 执行 CRUD/search smoke Job，确认预期主键和查询顺序，清理临时 collection/Job

**Checkpoint**: US1 独立通过，knowledge-engine 具备可用的内部 Milvus。

---

## Phase 5: User Story 2 - 数据在 Pod 重建后保持 (Priority: P1)

- [x] T021 [US2] 创建专用持久化测试 collection并记录查询断言
- [x] T022 [US2] 删除 Milvus Standalone Pod，等待恢复 Ready并重新查询成功
- [x] T023 [US2] 删除 etcd Pod，等待恢复 Ready并重新查询成功
- [x] T024 [US2] 删除 MinIO Pod，等待恢复 Ready并重新查询成功
- [x] T025 [US2] 验证三个 PVC 名称、UID、容量和 Bound 状态未变化，清理持久化测试 collection

**Checkpoint**: US2 独立通过，三个组件重建均不丢数据。

---

## Phase 6: User Story 3 - Milvus 资源隔离 (Priority: P2)

- [x] T026 [US3] 验证 Milvus、etcd、MinIO 均仅运行在 `milvuspool`
- [x] T027 [US3] 创建不带 toleration 的普通测试 Pod并显式选择 `milvuspool`，
  确认因 untolerated taint 保持 Pending 后删除
- [x] T028 [US3] 验证总 requests 符合 2000m CPU / 9.5 GiB 内存预算，节点及系统 Pod 健康

**Checkpoint**: US3 独立通过，节点池隔离和容量边界有效。

---

## Phase 7: User Story 4 - 回滚与重装 (Priority: P2)

- [x] T029 [US4] 在 `grc-knowledge-engine/deploy/aks/milvus/README.md` 编写安装、认证、
  诊断、升级、rollback、卸载、重装和显式数据清理 Runbook
- [x] T030 [US4] 产生无害的 Helm revision 2，执行 rollback 到上一成功 revision，
  重跑查询确认数据保持
- [x] T031 [US4] 卸载 Helm release，确认 Secret 和三个 PVC 保留，其他 Namespace 健康
- [x] T032 [US4] 使用相同 Chart/values 重装，重新执行认证初始化与 CRUD/search smoke
- [x] T033 [US4] 删除全部临时 Job/Pod/collection，确认 release Ready、PVC Bound、
  四个 AKS 节点 Ready且无新增 CrashLoopBackOff/ImagePullBackOff

**Checkpoint**: US4 独立通过，部署、rollback 和重装均可重复。

---

## Phase 8: Documentation and Closure

- [x] T034 [P] 更新 `docs/temp/部署镜像清单.md`，补充 Chart、兼容 etcd、smoke 镜像
  的来源、目标 digest、架构和许可证状态
- [x] T035 [P] 更新 `docs/temp/部署服务相关任务清单.md`，记录 Milvus 拓扑、PVC、
  taint 和验收结果
- [x] T036 运行 `grc-knowledge-engine` 适用门禁、部署专项测试、密钥扫描和 Git diff检查
- [x] T037 提交 `grc-knowledge-engine` 部署工件并创建 PR，引用
  `specs/011-milvus-dev-deployment`
- [x] T038 创建 `specs/011-milvus-dev-deployment/retro.md`，记录实施事实和偏差
- [x] T039 **更新 Project Memory**：更新 knowledge-engine 服务卡、state 和必要的
  watchlist，提交后等待人审

## Dependencies & Execution Order

1. T001-T003 建立干净基线和固定 Chart。
2. T004-T007 建立红灯测试，阻塞后续实现。
3. T008-T013 完成镜像和实现工件。
4. T014 全绿后才能执行 T015-T020。
5. US1 通过后依次执行 US2、US3、US4。
6. 所有集群验收通过后执行 T034-T039。

## Requirement Coverage

| Requirement | Tasks |
|-------------|-------|
| FR-001 Chart 4.2.49 | T003、T004、T010、T014 |
| FR-002 Standalone/Rocksmq | T004、T010、T014 |
| FR-003 etcd/MinIO 单副本 | T008、T010、T018 |
| FR-004 ACR digest | T004、T008-T010、T014、T034 |
| FR-005 三个 64 GiB PVC | T004、T010、T018、T025 |
| FR-006 PVC 保留 | T004、T010、T030-T032 |
| FR-007 milvuspool 隔离 | T010、T016、T026、T027 |
| FR-008 资源预算 | T004、T010、T028 |
| FR-009 ClusterIP | T004、T010、T014 |
| FR-010 Milvus 认证 | T011-T013、T019 |
| FR-011 MinIO Secret | T004、T010、T011、T014 |
| FR-012 probes/Ready | T010、T014、T017、T018 |
| FR-013 诊断 | T018、T028、T029、T033 |
| FR-014 CRUD/search | T006、T012、T013、T020 |
| FR-015 逐组件重建 | T021-T025 |
| FR-016 幂等与回滚 | T029-T033 |
| FR-017 静态门禁 | T004-T007、T014、T036 |
| FR-018 文档与记忆 | T034、T035、T038、T039 |

## Parallel Opportunities

- T002 与 T003 可并行。
- T006 可与 T004 并行编写。
- T008 与 T009 可并行构建和推送。
- T034 与 T035 可并行更新不同文档。

## Implementation Strategy

1. 先完成 US1，交付最小可用向量数据库。
2. 再验证 US2 数据持久化。
3. 再验证 US3 节点隔离。
4. 最后完成 US4 rollback 和重装演练。
5. 任一阶段失败均停止，不删除 PVC，不使用公网镜像或默认凭据绕过。
