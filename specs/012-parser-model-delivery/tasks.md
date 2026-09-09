# Tasks: Parser 模型制品交付

**Input**: `specs/012-parser-model-delivery/spec.md`、`plan.md`

**Prerequisites**: spec/plan 已人审；无契约变更。

## Phase 1: Setup

- [ ] T001 同步 `grc-parser-engine` 远端基线并确认工作区干净
- [ ] T002 [P] [US1] 记录 EC2 源目录、canonical/cache容量、文件数和磁盘空间基线
- [ ] T003 [P] [US2] 记录 AKS `gpupool`、GPU、StorageClass、Namespace和现有 PVC 基线

## Phase 2: Tests First

- [ ] T004 [US1] 创建 `deploy/aks/models/tests/test_manifest.py`，定义 deterministic
  manifest、路径安全、文件 size/hash 行为
- [ ] T005 [US1] 创建 `deploy/aks/models/tests/test_staging.py`，定义 canonical allowlist、
  cache denylist、symlink拒绝和24 GiB上限
- [ ] T006 [US1] 创建 `deploy/aks/models/tests/validate-model-delivery.ps1`，定义镜像 digest、
  PVC、loader、只读 mount、taint和Secret禁用规则
- [ ] T007 [US1] 在工具/PVC/Job不存在时运行测试并确认红灯

## Phase 3: Bundle and Images (US1)

- [ ] T008 [US1] 实现 `deploy/aks/models/scripts/build-model-bundle.py`
- [ ] T009 [US1] 实现 `deploy/aks/models/scripts/model-loader.sh`
- [ ] T010 [US1] 创建三个模型 Dockerfile，仅复制各自 canonical payload
- [ ] T011 [US1] 在 `/data/grc-model-staging/` 创建只读源派生 staging，不修改源目录
- [ ] T012 [US1] 生成文件级 manifest、manifest SHA和 bundle ID
- [ ] T013 [US1] 运行 staging/manifest测试并确认 canonical容量≤24 GiB
- [ ] T014 [P] [US1] 构建并推送 Docling模型镜像，记录 ACR digest
- [ ] T015 [P] [US1] 构建并推送 OFA模型镜像，记录 ACR digest
- [ ] T016 [US1] 构建并推送 MinerU模型镜像，记录 ACR digest
- [ ] T017 [US1] 检查三个镜像内容、架构、无凭据、无重复 cache

## Phase 4: PVC and Loader (US1)

- [ ] T018 [US1] 创建 `grc-parser` Namespace 和 `parser-models` 128 GiB Premium PVC
- [ ] T019 [US1] 创建使用三个 ACR digest 的 Model Loader Job
- [ ] T020 [US1] 运行静态测试和 Kubernetes client/server dry-run使门禁转绿
- [ ] T021 [US1] 应用 PVC/Job并等待完整 bundle加载成功
- [ ] T022 [US1] 在 PVC 中校验文件数、总字节和所有 SHA256
- [ ] T023 [US1] 重复执行 loader，确认5分钟内幂等成功且文件未重写

## Phase 5: Parser Read-only Validation (US2)

- [ ] T024 [US2] 将现有 parser验证镜像按固定版本推送 ACR
- [ ] T025 [US2] 创建 parser模型验证 Pod，PVC按 bundle subPath只读挂载
- [ ] T026 [US2] 执行本地模型必需目录检查和禁止运行时下载检查
- [ ] T027 [US2] 执行 Docling warmup/样例解析
- [ ] T028 [US2] 执行 MinerU warmup/样例解析
- [ ] T029 [US2] 执行 OFA image-caption warmup/样例
- [ ] T030 [US2] 验证模型目录写入失败，清理验证 Pod

## Phase 6: Versioning and Failure Handling (US3/US4)

- [ ] T031 [US3] 验证 bundle metadata和显式 bundle路径可用于parser切换
- [ ] T032 [US4] 使用错误 SHA运行 verifier，确认 Job失败且不写 `.complete`
- [ ] T033 [US4] 确认错误 bundle不影响已完成 bundle并清理错误测试目录
- [ ] T034 [US4] 创建 `Remove-ParserModelBundle.ps1`，默认dry-run且要求完整ID二次确认
- [ ] T035 [US4] 编写模型列表、空间、加载、验证、回滚、清理 Runbook

## Phase 7: Closure

- [ ] T036 [P] 更新 `docs/temp/部署镜像清单.md`
- [ ] T037 [P] 更新 `docs/temp/部署服务相关任务清单.md`
- [ ] T038 运行 parser仓库适用门禁、专项测试、密钥扫描和集群健康检查
- [ ] T039 提交 parser模型交付工件并创建 PR，引用 spec 012
- [ ] T040 创建 `specs/012-parser-model-delivery/retro.md`
- [ ] T041 **更新 Project Memory**：更新 parser服务卡、state和必要watchlist

## Dependencies

1. T001-T003 建立基线。
2. T004-T007 红灯测试阻塞实现。
3. T008-T013 生成不可变 bundle。
4. T014-T017 完成 ACR制品后才能 T018-T023。
5. PVC 完成后执行 T024-T030 parser验证。
6. 正向验证后执行 T031-T035 失败/清理测试。
7. 最后执行 T036-T041。

## Requirement Coverage

| Requirements | Tasks |
|---|---|
| FR-001–FR-005 源只读/canonical/manifest | T002、T004、T005、T008、T011-T013 |
| FR-006–FR-008 三镜像/ACR/内容边界 | T006、T009、T010、T014-T017 |
| FR-009–FR-013 PVC/loader/幂等 | T006、T018-T023 |
| FR-014–FR-016 parser只读/离线/warmup | T024-T030 |
| FR-017–FR-019 Runbook/保留/清理 | T031-T035 |
| FR-020 文档和记忆 | T036、T037、T040、T041 |
