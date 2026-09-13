# Implementation Plan: EC2 已验证版本滚动更新至 AKS

**Branch**: `015-aks-service-rollout` | **Date**: 2026-09-13

**Spec**: [spec.md](./spec.md)

## Summary

以远端 release commit 为可复现构建来源，将 Gateway、Mgmt、Knowledge 和 Parser 的演示所需
更新集成到当前 AKS 稳定基线；Portal 与 Auth 无必要更新时保持原 digest。每个服务先解决
运行清单、契约、迁移和测试问题，再构建 ACR 镜像、按 digest 分阶段部署并执行真实 E2E。

## Technical Context

**Target**: Azure China AKS `XAGPMCNINFAKS001`

**Registry**: `xagpmcninfctreg001-ekbagyfzhvg7bwfy.azurecr.cn`

**Languages**: Java 17、Python 3.12、TypeScript/Next.js

**Runtime dependencies**: PostgreSQL、Redis、Blob、Milvus、Parser GPU/PVC

**Rollback anchor**: 2026-09-11 已通过完整演示的六服务 ACR digest 集合

## 涉及服务（Affected Services · 必填）

| 服务 | 本轮处理 |
|---|---|
| `grc-api-gateway` | 集成 `3e63ec1`，补 KE Service 路由与临时私网开放规则 |
| `grc-mgmt-service` | 集成 `7fdc5a3`，恢复 AKS 清单并修正 KE 配置键 |
| `grc-knowledge-engine` | 将 `843ee71` 合并到 AKS 基线，保留认证/non-root/端口修复并补迁移 |
| `grc-parser-engine` | 仅从 release 集成 PNG 修复，保留 GPU/PVC/模型运行时 |
| `grc-auth-service` | 候选与当前基线一致，验证后跳过 |
| `grc-ai-portal` | 仓库远端不可访问，保持当前已验收 digest |

## 契约影响（Contract Impact · 必填）

本轮候选包含 Mgmt/Knowledge API 变化。实现前必须：

1. 比较 Mgmt、Knowledge provider 实现与 Hub 当前 OpenAPI。
2. 对 endpoint/响应结构差异更新契约草案。
3. 运行 `check-contracts.ps1` 和破坏性变更判定。
4. 若属于破坏性变化，取得 Gateway/Portal/Mgmt 等全部消费方确认。

Gateway `/open/v1/**` 私网临时放行是人工批准的演示例外，但仍需用测试固定路径转发行为。

## Constitution Check

- **Spec 先行**：实现追溯到已人工裁定的 spec 015。
- **契约先行**：Mgmt/Knowledge 漂移必须先合并契约。
- **测试先行**：先增加路由、迁移、PNG 和跨服务失败测试。
- **服务边界**：Portal 仅访问 Gateway；Mgmt 通过 API 访问 Knowledge。
- **记忆义务**：发布后更新 retro、服务卡、state 和 watchlist。
- **人类守门点**：契约、服务 PR、迁移和 memory 各自保留审批。

## 实施策略

### Phase 1: 冻结与集成分支

1. 保存当前 AKS Deployment、Service、digest 和 rollout history。
2. 每个服务从已验收 AKS 分支创建独立集成分支。
3. 合并或摘取 release commit，不直接覆盖 AKS runtime 工件。

### Phase 2: 契约与数据库

1. 对齐 Mgmt/Knowledge OpenAPI。
2. 为 Knowledge 增加缺失的时间字段迁移并验证旧数据。
3. Parser 不接受 release 的重建式数据库基线。
4. 所有迁移先在测试数据库或恢复副本执行。

### Phase 3: 服务修复与测试

1. Gateway：KE 地址、完整路径、临时白名单、超时和运行清单测试。
2. Mgmt：KE 配置键、授权例外边界、document/stage/enhance 契约测试。
3. Knowledge：合并业务修复并保留 HTTPS source、Parser token、non-root、8080 与 AKS 清单。
4. Parser：仅集成 PNG hotfix，补 PNG/PDF 回归测试。

### Phase 4: 镜像与部署

1. 使用准确 Git SHA 构建镜像。
2. 推送 ACR 并读取远端 digest。
3. 更新 Deployment 清单为 digest。
4. Parser → Knowledge → Mgmt → Gateway 顺序 rollout。
5. 每一步失败立即恢复该服务旧 digest。

### Phase 5: 演示验收

1. VPN Portal 加载。
2. Auth/Mgmt 受保护接口仍验证身份。
3. 临时 `/open/v1/**` 路由按演示决策可用。
4. 固定 DOCX 完成上传、解析、chunks、vectors 和检索。
5. 更新镜像清单、Runbook、retro 和 Project Memory。

## 停止条件

- 契约门禁未通过。
- Knowledge 迁移缺失或旧数据验证失败。
- 新镜像丢失 non-root、端口、GPU/PVC 或 Secret 注入行为。
- 任一 Pod 6 分钟内未 Ready。
- 真实文档 E2E 失败且无法在 10 分钟内定位。

## 回滚

- 使用本轮前保存的 digest 逐服务恢复。
- 顺序：Gateway → Mgmt → Knowledge → Parser。
- 不删除 PostgreSQL、Blob、Milvus 或 PVC。
- 临时开放路由可通过恢复 Gateway 旧 digest 立即关闭。
