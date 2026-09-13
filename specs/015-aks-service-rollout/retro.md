# Retrospective: EC2 已验证版本滚动更新至 AKS

**Date**: 2026-09-13

**Status**: Implementation complete; Project Memory pending review

## 结果

在保留 Portal/Auth 稳定版本的前提下，完成 Gateway、Mgmt、Knowledge 和 Parser 的集成、
不可变镜像构建与 XAG AKS 更新。所有业务 Deployment 为 Ready，固定 DOCX 完成真实上传、
构建、104 chunks、104 Milvus vectors 和 5 条检索结果。

## 发布版本

| 服务 | 集成提交 | ACR digest |
|---|---|---|
| Gateway | `a715658` | `sha256:f33309876da2b8e1e0a3987b0118cada35eb6e9c10f3861ab47ecc8b567ded2a` |
| Mgmt | `7fbf66b` | `sha256:e3c59f02b3b425bf42ee6a69dbbdef58ebb4996209bc50523ed3a7d6fc01b7bf` |
| Knowledge | `71c4972` | `sha256:afe7e9184e07d73e039d215b54430e7f2b75f0643c8133cd94fbfd7974b8f6c1` |
| Parser | `2cd898f` | `sha256:a8e787951c464ecae24cbbbaf84f954294413f3204e0011b8eab07811456a18d` |

Auth `c62dcd9` 和 Portal 当前构建无必要更新，保持 spec 014 digest。

## 验证

- Gateway：23 项测试通过；Auth/Mgmt 无 Token 返回 401；`/open/v1/**` 完整路径转发。
- Mgmt：19 项目标链路测试通过；JAR 构建、清单校验通过；列表与 Overview 返回 200。
- Knowledge：239 项 pytest、123 个 mypy 文件、变更文件 Ruff、清单校验通过。
- Parser：PNG/PDF 定向测试、模型对齐和清单校验通过；运行 Pod 真实 PNG 解析 1 页。
- Knowledge migration 007：1903 行、0 NULL；`update_time` 从无时区转换为
  `timestamptz`，默认值与 NOT NULL 保持；迁移已改为按列类型幂等执行。
- E2E：文档 `357490951490396160` 为 `ACTIVE`，批次 `357491467674980352`
  为 `SUCCEEDED`；PostgreSQL 104 条 `INDEXED`，Milvus 104 条，检索返回 5 条。
- Gateway 旧 digest 回滚和新 digest 恢复均通过健康检查。

## 关键决策

1. 用户批准 `/open/v1/**` 在 XAG 私网演示环境临时跳过 Gateway JWT，以次日客户演示为优先。
2. 不整体更新 Parser release 分支，仅提取 PNG hotfix，避免引入重建式数据库和 CUDA 基线变化。
3. Java/Python 镜像使用已验收 ACR digest 作为基础层，只覆盖测试后的 JAR/app/migrations，
   避免 ACR Build 访问 Docker Hub失败并保持运行时一致。
4. EC2 运行镜像无法在当前环境直接取证，因此发布来源记录为远端 release commit，
   不宣称与 EC2 image digest 完全相同。

## 问题与处理

- ACR Build 无法访问 Docker Hub：改用已验收 ACR digest 作为不可变基础镜像。
- Gateway/Mgmt/Knowledge/Parser release 分支均与 AKS runtime 分叉：使用独立集成分支保留
  部署工件和环境修复。
- Knowledge 缺迁移 007：补充安全的 UTC 转换、NULL 回填和幂等保护后执行。
- Mgmt 上传 ETag 初次验收失败：确认服务要求无引号 Azure ETag，使用精确值后通过。
- Hub 全局契约门禁存在既有错误：Mgmt 变更前后均为 6 errors/162 warnings，本轮可选
  `jobId` 未增加错误；AsyncAPI CLI 依赖版本也无法解析。

## 遗留项

- Gateway `/open/v1/**` 正式 PAT/scope 鉴权必须在生产前恢复。
- Knowledge 仍为 local worker；Service Bus deployed worker、重启恢复仍受权限阻塞。
- Mgmt 全量测试仍有 22 failures/32 errors；本轮只对目标链路和真实 E2E负责。
- Java 镜像仍以 root 运行；生产需重建 non-root。
- EC2 image digest 取证、镜像漏洞扫描和许可证审查仍需运维补齐。
