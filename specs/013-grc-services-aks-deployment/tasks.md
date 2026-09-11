# Tasks: GRC 服务上 AKS（开发环境第一阶段）

**Input**: `specs/013-grc-services-aks-deployment/spec.md`, `plan.md`

**Prerequisites**: spec/plan 已完成评审；无契约变更。

## Phase 1: Setup

- [x] T001 记录 parser/knowledge 当前 ACR tag 与 digest
- [x] T002 确认 parser 模型 PVC 与 GPU 前置能力已就绪
- [x] T003 确认 Milvus 开发服务地址与 knowledge 依赖项

## Phase 2: Tests First

- [x] T004 [P] 为 parser 新建 `deploy/aks/runtime/tests/validate-runtime-manifests.ps1`
- [x] T005 [P] 为 knowledge 新建 `deploy/aks/runtime/tests/validate-runtime-manifests.ps1`
- [x] T006 先定义校验规则：ACR digest、禁用 latest、关键调度与挂载约束

## Phase 3: Parser AKS Runtime

- [x] T007 创建 parser runtime Namespace/ConfigMap/Secret 模板
- [x] T008 创建 parser Deployment（GPU 调度 + parser-models 只读挂载）
- [x] T009 创建 parser ClusterIP Service
- [x] T010 运行 parser 清单静态校验脚本

## Phase 4: Knowledge AKS Runtime

- [x] T011 创建 knowledge runtime Namespace/ConfigMap/Secret 模板
- [x] T012 创建 knowledge Deployment（deployed 模式必需配置）
- [x] T013 创建 knowledge ClusterIP Service
- [x] T014 运行 knowledge 清单静态校验脚本

## Phase 5: Closure

- [x] T015 更新 `docs/temp/部署服务相关任务清单.md` 的 AKS 服务部署进展
- [x] T016 执行 `kubectl apply --dry-run=client` 校验
- [x] T017 在开发 AKS 执行 rollout 与 `/health` `/readyz` 验收
- [x] T018 **更新 Project Memory**（服务状态、风险与后续待办）
