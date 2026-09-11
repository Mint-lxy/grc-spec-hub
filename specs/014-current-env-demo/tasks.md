# Tasks: 当前环境端到端演示

**Input**: `spec.md`, `plan.md`

**Prerequisites**: spec 与 plan 已完成人审；任何跨服务契约缺口必须先走 contract-change。

## Phase 1: Gate 0 与事实基线

- [x] T001 确认 `grc-ai-portal` 的准确仓库 URL、访问权限、目标分支
  `feature/release260911` 与演示 commit SHA
- [x] T002 [P] 记录 Auth/Mgmt/Gateway/Knowledge/Parser 当前分支、commit、构建命令和运行端口
- [x] T003 [P] 盘点 AKS 现有 Ingress/Application Gateway/内部入口能力，确认浏览器访问方案
- [x] T004 确认演示身份方案：OIDC/Alice 优先，否则使用仅限 XAG 的隔离账号

## Phase 2: 契约判定与测试基线

- [x] T005 比对 Portal 请求、Gateway 路由及 Auth/Mgmt/Knowledge/Parser 已合并契约
- [x] T006 若 Gateway 空契约或 watchlist #71 覆盖演示字段，先完成 contract-change 与消费者确认
- [x] T007 [P] 在 `grc-knowledge-engine` 先写 deployed 持久队列和真实 readiness 失败测试
- [x] T008 [P] 在 `grc-api-gateway` 先写 Auth/Mgmt 路由、无 Token 拒绝和后端失败传播测试
- [ ] T009 [P] 在 `grc-auth-service` 先写演示身份登录、verify/refresh 和无效身份拒绝测试
- [ ] T010 [P] 在 `grc-mgmt-service` 先写上传会话、完成上传、创建文档及调用 Knowledge 的链路测试
- [ ] T011 [P] 获取 Portal 后先写关闭 Mock、真实 API origin 和失败态可见测试
- [ ] T012 定义固定 PDF/DOCX、演示账号、预期状态与失败场景的端到端 smoke/E2E 脚本

## Phase 3: Knowledge 真实 deployed 运行时

- [x] T013 在 `grc-knowledge-engine` 将 deployed 模式接入 `AzureServiceBusQueue` 与 worker
- [ ] T014 在 `grc-knowledge-engine` 补齐并实际消费 PostgreSQL、Redis、Service Bus、Blob、
  Milvus、Parser 配置
- [ ] T015 在 `grc-knowledge-engine` 增加占位 Secret 拒绝和真实依赖 readiness
- [x] T016 为 `stage-jobs` Topic、`stage-worker` Subscription、Blob 容器和数据库初始化提供
  可审计、幂等的部署步骤
- [ ] T017 运行 Knowledge 单测、静态检查和镜像启动 smoke
- [x] T018 构建并推送 Knowledge 镜像到 ACR，记录远端 digest，统一 README/Deployment 真相源

## Phase 4: Java 服务容器化

- [ ] T019 [P] 为 `grc-auth-service` 新增测试覆盖的多阶段 Dockerfile、`.dockerignore`
  与 AKS runtime 清单
- [ ] T020 [P] 为 `grc-mgmt-service` 新增测试覆盖的多阶段 Dockerfile、`.dockerignore`
  与 AKS runtime 清单
- [ ] T021 [P] 为 `grc-api-gateway` 新增测试覆盖的多阶段 Dockerfile、`.dockerignore`
  与 AKS runtime 清单
- [ ] T022 先构建/install `grc-java-common`，再运行 Auth/Mgmt/Gateway 现有测试和构建
- [x] T023 清除 Java 运行配置中的 localhost、`172.16.*`、默认 token 和占位 Secret
- [x] T024 构建并推送 Auth/Mgmt/Gateway 镜像到 ACR，记录各自 commit 与远端 digest

## Phase 5: Portal 构建与入口

- [x] T025 获取 Portal 后核对其 `AGENTS.md`、package manager、测试与构建约定
- [x] T026 以 `NEXT_PUBLIC_USE_MOCK=false` 和真实 Gateway origin 构建 Portal
- [x] T027 为 Portal 新增测试覆盖的 Dockerfile、`.dockerignore` 与 AKS runtime 清单
- [x] T028 构建并推送 Portal 镜像到 ACR，记录 commit 与远端 digest
- [x] T029 配置批准的内部浏览器入口，不创建默认公网 LoadBalancer

## Phase 6: Secret 与 AKS 部署

- [ ] T030 将 Auth/Mgmt/Gateway/Knowledge Secret 替换为真实值并记录批准的来源
- [x] T031 部署 Auth，并验证登录/verify 与未认证拒绝
- [x] T032 复核 Parser production、GPU、PVC、Docling/MinerU 与 `/readyz`
- [ ] T033 部署 Knowledge，验证数据库、队列、Blob、Milvus、Parser readiness
- [x] T034 部署 Mgmt，验证上传会话、Blob 与 Knowledge 内部调用
- [x] T035 部署 Gateway，验证 Auth/Mgmt 路由和失败传播
- [x] T036 部署 Portal 与内部入口，验证浏览器无 kubectl 前置即可访问

## Phase 7: 端到端演示验收

- [x] T037 验证 Portal 核心请求不命中 Mock，所有工作负载镜像均按 ACR digest 固定
- [x] T038 使用固定 PDF/DOCX 完成上传、Blob、Mgmt、Knowledge、Parser、Milvus 真实构建
- [x] T039 验证成功终态与可诊断失败；失败不得长期无界等待
- [x] T040 AI SDK 真凭据可用时执行检索；不可用时验证明确降级
- [x] T041 冻结最近一次通过的 manifest + digest 集合并演练入口逆序回滚

## Phase 8: 文档与记忆

- [x] T042 更新 `docs/temp/部署服务相关任务清单.md` 和 Azure 通用部署经验
- [x] T043 编写不含凭据的部署、验证、重置和回滚 Runbook
- [x] T044 生成 `retro.md`
- [x] T045 **更新 Project Memory**（state、服务卡、决策与 watchlist），提交人审
