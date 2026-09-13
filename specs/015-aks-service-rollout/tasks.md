# Tasks: EC2 已验证版本滚动更新至 AKS

**Input**: `spec.md`, `plan.md`

## Phase 1: 基线与契约

- [x] T001 保存当前六服务 Deployment、Service、digest、rollout history 和 Ready 状态
- [x] T002 记录远端候选 Git SHA，并明确其不等同于未经取证的 EC2 image digest
- [x] T003 比对 Mgmt/Knowledge provider 与 Hub OpenAPI
- [x] T004 必要时完成 contract-change、破坏性判定和消费者确认
- [x] T005 为 Knowledge 时间字段补迁移与旧数据验证

## Phase 2: Gateway

- [x] T006 从 AKS runtime 基线集成 Gateway `3e63ec1`
- [x] T007 先写 KE 路由、完整路径、临时白名单和下游失败测试
- [x] T008 更新 `KE_SERVICE_URL` 与 AKS ConfigMap，保留 Auth/Mgmt 路由
- [x] T009 运行 Gateway 测试、构建与清单校验

## Phase 3: Mgmt

- [x] T010 从 AKS runtime 基线集成 Mgmt `7fdc5a3`
- [x] T011 先写 document/stage/enhance 与配置键契约测试
- [x] T012 修复 `KE_SERVER_URL` 与 AKS 配置，恢复必要授权边界
- [x] T013 运行 Mgmt 定向测试、构建与清单校验，记录既有失败

## Phase 4: Knowledge

- [x] T014 将 Knowledge `843ee71` 合并到 AKS runtime 基线
- [x] T015 保留 HTTPS source、Parser token、non-root、8080、Service Bus 与清单修复
- [x] T016 增加迁移、provider contract、文档构建和 stage 投影测试
- [x] T017 运行 Knowledge 单测、静态检查、迁移和镜像 smoke

## Phase 5: Parser

- [x] T018 从 AKS runtime 基线仅集成 Parser PNG hotfix `1b88123`
- [x] T019 先写 PNG/PDF 回归测试
- [x] T020 验证 CUDA、GPU、模型 PVC、Docling/MinerU 与 `/readyz`

## Phase 6: 发布与 AKS

- [x] T021 构建 Gateway/Mgmt/Knowledge/Parser 并推送 ACR
- [x] T022 记录 Git SHA、tag、ACR digest、测试和旧 digest
- [x] T023 按 Parser → Knowledge → Mgmt → Gateway rollout
- [x] T024 每个服务执行 readiness、日志与 smoke 门禁
- [x] T025 执行 VPN Portal、登录、开放路由和固定 DOCX 完整 E2E
- [x] T026 演练单服务回滚并恢复验收版本

## Phase 7: 交付

- [x] T027 更新 `docs/temp/部署镜像清单.md`
- [x] T028 完成并复核 `docs/temp/EC2已验证版本更新至AKS运维Runbook.md`
- [x] T029 生成 `retro.md`
- [x] T030 实现并测试 EC2 `publish-to-acr.sh`，同步详细 Runbook
- [x] T031 更新 Project Memory 并提交人审
