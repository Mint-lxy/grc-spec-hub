# Implementation Plan: GRC 服务上 AKS（开发环境第一阶段）

**Branch**: `013-grc-services-aks-deployment` | **Date**: 2026-09-10
**Spec**: [spec.md](./spec.md)

## Summary

在不变更跨服务契约的前提下，交付 `grc-parser-engine` 与 `grc-knowledge-engine` 的 AKS
运行清单（Namespace、ConfigMap、Secret 模板、Deployment、Service、静态校验脚本），并
将镜像固定到已发布 ACR digest：

- parser: `sha256:8328074d7c016039c9cee7d02ba0d976aff36b21927390d6325fc49f2ec8f0f8`
- knowledge: `sha256:0746a1875f127b11a6900e19c26aa4e9beaef4e0ffaa3fc688791f15b0c6c124`

## Technical Context

**Language/Version**: Kubernetes YAML, PowerShell 5.1
**Primary Dependencies**: AKS, ACR, parser-models PVC, Milvus in-cluster service
**Target Platform**: Azure China AKS `XAGPMCNINFAKS001`
**Testing**: 清单静态校验脚本 + kubectl dry-run + rollout/探针检查（人工执行）

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|---|---|---|
| grc-parser-engine | 新增部署清单 | 新增 AKS runtime manifests 与校验脚本，绑定 GPU 和模型 PVC |
| grc-knowledge-engine | 新增部署清单 | 新增 AKS runtime manifests 与校验脚本，注入 Milvus/Parser/PaaS 配置 |
| grc-spec-hub | 规格工件 | 新增 spec/plan/tasks，记录部署阶段约束与验收口径 |

## 契约影响（Contract Impact · 必填）

无契约影响。此次仅交付部署形态，不修改 REST/事件契约。

## Constitution Check

- **Spec 先行**: 先落地 spec/plan/tasks，再交付实现清单。
- **契约先行**: 无跨服务契约变更，不走 contract-change。
- **测试先行**: 先交付静态校验脚本，作为清单门禁。
- **服务边界**: parser/knowledge 清单放在各自仓库 `deploy/aks/runtime/`。
- **记忆义务**: 更新 `docs/temp/部署服务相关任务清单.md` 记录实施进度。
- **人类守门点**: 上集群 apply 与 rollout 保留人工执行/审批。

结论：满足当前宪法约束。

## Design Notes

1. parser 使用 `grc-parser` Namespace，并复用已存在 `parser-models` PVC。
2. knowledge 使用 `grc-knowledge` Namespace，`PARSER_ENGINE_BASE_URL` 指向
   `http://parser-engine.grc-parser.svc.cluster.local:8888`。
3. 两服务均只使用 `ClusterIP`，不在本阶段暴露 Ingress/LB。
4. Secret 仅提供模板，不在仓库记录真实凭据。
5. parser 按 GPU 规范声明：
   - `nodeSelector: agentpool=gpupool`
   - `tolerations: sku=gpu:NoSchedule`
   - `resources.requests/limits.nvidia.com/gpu=1`
