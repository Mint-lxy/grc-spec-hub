# ADR-005: 凭据解析归属 mgmt-service，业务选凭据与密钥解析分层

> 状态：Accepted
> 日期：2026-08-17 · 决策者：@nzhang · 关联 spec：`specs/007-credential`
> 2026-08-24 修订：按凭据模型裁定移除资产级服务凭据；一切资产调用使用调用人的个人凭据，平台资源凭据仅用于平台自有资源。
> 2026-09-15 修订：撤回模型类 `POST /mgt/vault/inbound/resolve-model` 提案；SDK 改为由调用方显式传 `credentialId`，复用既有 `GET /mgmt/vault/outbound/credentials/{id}/resolve` 做精确解析。

## 背景

平台仍有两类出站调用需要凭据参与，但 2026-09-15 后要把**业务选哪把钥匙**与**按 ID 取出钥匙**拆开：

1. **资产调用**（Agent/MCP）——需按资产订阅、Owner/Deputy、自身绑定关系和管理员停用规则先决定可用的个人凭据，再执行出站调用。
2. **模型调用**（Nexus LLM/Embedding/Rerank/Chat vision）——业务层或配置层先决定本次该用哪条 `credentialId`，SDK 只负责解析并调用。

旧口径把模型类调用定义为「按触发人解析个人 Nexus 凭据，必要时平台默认兜底」，并因此提出单独的 `resolve-model` 端点。用户已确认该策略不应由 SDK 承担，现需改回与现有 contract 一致的 **credentialId 精确解析** 模式。

## 决策

### D1 — 凭据解析 API 归属 mgmt-service

无变化：凭据相关事实仍归 mgmt-service 所有。

- 个人资产调用凭据 / 个人 Nexus 凭据 → credential 模块
- 平台凭据对象与模型配置 → admin / platform-resource registry 模块
- 订阅状态、Owner/Deputy 免订阅使用授权 → subscription / asset ownership 模块
- admin 出站停用标志 → admin 模块
- Key Vault 读取 → credential 模块基础设施

auth-service 不拥有上述业务数据，因此仍不承担业务凭据解析职责。

### D2 — 业务选凭据与 secret resolve 分层，不新增 `resolve-model`

**现行边界**：

- **业务层 / 调用方**：决定 `credentialId`、完成用户/业务授权、为 SDK 路径提供 int64 `userId` 上下文、决定 credential 使用策略、决定是否 fallback / retry
- **mgmt-service**：接收一个明确的 `credentialId`；对 grc-ai-sdk 路径再结合 `userId` 校验凭据归属，并返回解析结果（当前 Nexus 模型调用语义对齐为 numeric `credentialId`、`targetType = NEXUS`、string `targetId`、`authType = NEXUS_PERSONAL_TOKEN`、nullable `endpoint` / `protocol` 与 `resolvedFields`）
- **SDK**：拿着这个解析结果直调目标 Provider，不做再选择

模型类调用**不再新增**：

```text
POST /mgt/vault/inbound/resolve-model   ← 撤回提案
```

继续使用：

```text
GET /mgmt/vault/outbound/credentials/{id}/resolve
```

该接口是**内部精确解析接口**，不是「按 userId / modelId 选凭据」接口。

### D3 — 认证与授权边界

- 宿主工作负载通过 **Azure Workload Identity** 获取访问令牌调用 mgmt-service
- Workload Identity 证明的是「哪个服务在调用」
- 是否有权替某个用户 / 某条业务流程使用某条凭据，由**调用方在进入 SDK 前**自行保证；对 grc-ai-sdk 路径，SDK 仍必须把该 `userId` 传给 mgmt-service 做归属校验
- mgmt-service 对内部 resolve 接口按**服务身份**授权

### 解析流程

**资产调用**（平台运行时 / gateway）：

```text
1. getAsset(assetId) → 资产状态 + 凭据元数据声明
2. checkAdminDisabled(asset)
3. checkEffectiveUseAuthorization(userId, asset)
4. credentialId = boundPersonalCredentialId(userId, asset)
5. GET /mgmt/vault/outbound/credentials/{credentialId}/resolve
6. return resolved credential
7. 审计记录凭据主体三元组
```

资产调用仍不允许平台共享身份兜底。

**模型调用**（AI SDK 调用）：

```text
1. caller chooses credentialId
2. caller completes user/business authorization and provides userId context
3. SDK uses Azure Workload Identity access token
4. GET /mgmt/vault/outbound/credentials/{credentialId}/resolve?userId=<int64>
5. SDK keeps the resolved response in memory only; cache key, if any, is (userId, credentialId)
6. SDK interprets the current response shape as numeric credentialId + targetType=NEXUS + string targetId + authType=NEXUS_PERSONAL_TOKEN + nullable endpoint/protocol, maps resolvedFields.nexus_token as the token, and uses caller/model config supplied model_gateway_base_url/provider/query params rather than vault endpoint/protocol
7. provider / resolve errors propagate to caller
```

控制器层可为其他已有用户上下文的内部调用方保留 `userId` 可选，但 **grc-ai-sdk 调用时必须传 `userId`** 做凭据归属校验；该 `userId` 不参与 SDK 内部选凭据。

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 解析放 auth-service | 语义上“凭据”和 auth 相关 | 不拥有业务数据，需反调 mgmt | 额外一跳且无业务价值 |
| 单独新增 `resolve-model` | 调用方参数少 | 把选凭据策略压进 mgmt/SDK，且与现有 contract 脱节 | 已被 2026-09-15 用户裁定否决 |
| SDK 按 userId 自动选个人凭据并平台兜底 | 上层接入简单 | 混入授权、策略、快照治理和失败分类 | 边界错误 |
| 运行时组件直接访问 Key Vault 自行解析 | 少一次网络调用 | 运行时需理解订阅/绑定/停用等业务逻辑 | 违反关注点分离 |

## 影响

- 受影响服务：mgmt-service、grc-python-sdk、grc-agent-service 等所有经 SDK 调模型的服务
- 契约影响：`contracts/openapi/grc-mgmt-service.yaml` 只需澄清现有 `GET /mgmt/vault/outbound/credentials/{id}/resolve` 的内部语义与服务身份鉴权，并移除未引用的旧 `ResolveModelResponseEnvelope`
- 历史文档影响：凡写有 `resolve-model` / `report-credential-failure` / `for_user` 自动选凭据 的 spec / plan / ADR 均需收敛到本边界

## 后果

### 正面

- contract、spec、SDK 边界一致，不再反向发明旧端点
- mgmt-service 继续拥有凭据事实与 secret resolve 能力，职责集中
- 调用方对用户授权和凭据策略负责，责任边界清晰
- SDK 可在不理解业务授权的前提下支持文本、图像、流式等统一调用形态

### 负面

- 调用方需要显式管理 `credentialId`，不再享受 SDK 自动兜底
- 兼容过渡期需维护旧 public API / 旧文档口径的 deprecated 标记

### 风险

- 若调用方未正确选择或授权 `credentialId`，resolve 会失败并直接暴露给上层
- 若服务身份未被 mgmt-service 授权，内部 resolve 接口整体不可用
