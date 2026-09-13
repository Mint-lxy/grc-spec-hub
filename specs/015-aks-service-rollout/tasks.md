# Tasks: EC2 已验证版本滚动更新至 AKS

**Input**: `spec.md`, `plan.md`

## Phase 1: 基线与契约

- [ ] T001 保存当前六服务 Deployment、Service、digest、rollout history 和 Ready 状态
- [ ] T002 记录远端候选 Git SHA，并明确其不等同于未经取证的 EC2 image digest
- [ ] T003 比对 Mgmt/Knowledge provider 与 Hub OpenAPI
- [ ] T004 必要时完成 contract-change、破坏性判定和消费者确认
- [ ] T005 为 Knowledge 时间字段补迁移与旧数据验证

## Phase 2: Gateway

- [ ] T006 从 AKS runtime 基线集成 Gateway `3e63ec1`
- [ ] T007 先写 KE 路由、完整路径、临时白名单和下游失败测试
- [ ] T008 更新 `KE_SERVICE_URL` 与 AKS ConfigMap，保留 Auth/Mgmt 路由
- [ ] T009 运行 Gateway 测试、构建与清单校验

## Phase 3: Mgmt

- [ ] T010 从 AKS runtime 基线集成 Mgmt `7fdc5a3`
- [ ] T011 先写 document/stage/enhance 与配置键契约测试
- [ ] T012 修复 `KE_SERVER_URL` 与 AKS 配置，恢复必要授权边界
- [ ] T013 运行 Mgmt 定向测试、构建与清单校验，记录既有失败

## Phase 4: Knowledge

- [ ] T014 将 Knowledge `843ee71` 合并到 AKS runtime 基线
- [ ] T015 保留 HTTPS source、Parser token、non-root、8080、Service Bus 与清单修复
- [ ] T016 增加迁移、provider contract、文档构建和 stage 投影测试
- [ ] T017 运行 Knowledge 单测、静态检查、迁移和镜像 smoke

## Phase 5: Parser

- [ ] T018 从 AKS runtime 基线仅集成 Parser PNG hotfix `1b88123`
- [ ] T019 先写 PNG/PDF 回归测试
- [ ] T020 验证 CUDA、GPU、模型 PVC、Docling/MinerU 与 `/readyz`

## Phase 6: 发布与 AKS

- [ ] T021 构建 Gateway/Mgmt/Knowledge/Parser 并推送 ACR
- [ ] T022 记录 Git SHA、tag、ACR digest、测试和旧 digest
- [ ] T023 按 Parser → Knowledge → Mgmt → Gateway rollout
- [ ] T024 每个服务执行 readiness、日志与 smoke 门禁
- [ ] T025 执行 VPN Portal、登录、开放路由和固定 DOCX 完整 E2E
- [ ] T026 演练单服务回滚并恢复验收版本

## Phase 7: 交付

- [ ] T027 更新 `docs/temp/部署镜像清单.md`
- [ ] T028 完成并复核 `docs/temp/EC2已验证版本更新至AKS运维Runbook.md`
- [ ] T029 生成 `retro.md`
- [ ] T030 更新 Project Memory 并提交人审
