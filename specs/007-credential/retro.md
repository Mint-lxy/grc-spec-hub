# Retro: grc-ai-sdk credentialId 解析与 Chat 图像输入

> 日期：2026-09-16
> 实现：`grc-python-sdk@bd27788`

## 结局

grc-python-sdk 0.2.0 已实现 `userId + credentialId` 精确解析 Vault 凭据、Azure
Workload Identity 服务认证，以及 Base64 图片输入的 OpenAI-compatible Chat 调用。

## 新业务规则与约束

- 调用方负责凭据选择、业务授权、fallback 与 retry；SDK 不自动选凭据或切换凭据。
- SDK 调 `GET /mgmt/vault/outbound/credentials/{id}/resolve` 时必须传 int64 `userId`，
  由 mgmt-service 校验凭据归属。
- Vault 的 `NEXUS_PERSONAL_TOKEN` 读取 `resolvedFields.nexus_token`；模型地址、
  provider 与 query params 由调用方或模型配置提供。
- 凭据缓存按 `(userId, credentialId)` 隔离，默认 60 秒；secret 不落盘、不写日志。
- 图片输入仅支持 Base64 JPEG/PNG/WebP，最多 4 张、单张 10 MiB、合计 20 MiB；
  SDK 不读取文件、不抓取 URL、不管理图片生命周期。
- raw `api_key`、callback、`*_for_user` 与旧 `MULTIMODAL -> parser` 保留一版 deprecated
  兼容，计划在 1.0 移除。

## 契约变化

- 澄清 `contracts/openapi/grc-mgmt-service.yaml` 中
  `GET /mgmt/vault/outbound/credentials/{id}/resolve` 的 `userId` 归属校验、
  int64 凭据 ID、nullable endpoint/protocol 与 `nexus_token` 响应语义。
- 未新增 `resolve-model` 或失败上报接口。

## 决策

- ADR-003/005 修订为“调用方选择凭据，SDK 精确解析并调用”。
- Chat vision 继续走 ChatPort；文档解析改用 `DOCUMENT_PARSE`。
- GPT-5.5 使用 `max_completion_tokens`，SDK 同时兼容旧 `max_tokens`，但禁止同时设置。

## 踩坑与遗留

- 1×1 PNG 被 Nexus 判为不支持图片；换用标准 32×32 PNG 后真实联调成功。
- grc-agent-service 当前仍使用 deprecated `*_for_user`/静态 Key 路径；待业务层具备
  credentialId 后执行 T731~T733 迁移。
- mgmt-service 的 Workload Identity 服务授权仍由 T722 跟踪。

## 偏差

原 plan 让 SDK 按 userId 自动选个人凭据并在失败时回落平台默认；最终依据团队现有
Vault 契约和用户裁定，收敛为调用方显式选择 credentialId，SDK 不承担任何业务策略。

## Project Memory 更新

- 更新 `memory/now/services/grc-python-sdk.md`：版本、契约、测试、凭据边界和图像 PoC。
- 将旧“Vault 契约断裂”问题标记为已解决。
- 保留消费方迁移与 Workload Identity 授权为后续任务。
