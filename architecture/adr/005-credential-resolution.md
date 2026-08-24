# ADR-005: 凭据解析归属 mgmt-service，分离资产调用与模型调用两条路径

> 状态：Accepted
> 日期：2026-08-17 · 决策者：@nzhang · 关联 spec：`specs/007-credential`
> 2026-08-24 修订：按凭据模型裁定移除资产级服务凭据；一切资产调用使用调用人的个人凭据，平台资源凭据仅用于平台自有资源。

## 背景

平台有两类出站调用需要凭据解析：

1. **资产调用**（Agent/MCP）— 平台代理用户请求到外部资产，需按调用人注入其个人资产调用凭据。
2. **模型调用**（Nexus LLM/Embedding/Rerank）— 内部服务经 AI SDK 调用 Nexus，需按触发人解析个人 Nexus 凭据，必要时使用平台默认凭据兜底。

两条路径的解析规则不同：

| | 资产调用 | 模型调用 |
|---|---|---|
| 调用方 | 平台代理资产调用的运行时组件 | AI SDK（Python 服务） |
| 输入 | assetId + userId | userId |
| 解析规则 | 校验有效使用授权（已通过订阅，或有效 Owner/Deputy 免订阅自用）与管理员出站停用；使用 userId 对该资产绑定的个人凭据；未配置、未绑定、失效或调用失败均不回落共享身份 | 按序取个人 Nexus 凭据（启用且可用）→ 平台默认 Nexus 凭据对象兜底 |
| 额外检查 | 资产状态、有效使用授权、admin 出站停用 | 模型可用性快照 |
| 响应 | credential + source + targetEndpoint | credential + source + availableModels[] |

需要决定：(A) 解析 API 放哪个服务？(B) 一个接口还是两个？

## 决策

### D1 — 凭据解析 API 归属 mgmt-service

凭据解析所需的业务数据均归 mgmt-service 所有：

- 资产凭据元数据声明 → asset-catalog 模块
- 个人资产调用凭据 / 个人 Nexus 凭据 → credential 模块
- 平台默认 Nexus 凭据对象引用 → admin/model-settings 与 platform-resource registry 模块
- 订阅状态与 Owner/Deputy 免订阅使用授权 → subscription / asset ownership 模块
- admin 出站停用标志 → admin 模块
- Key Vault 读取 → credential 模块基础设施

资产侧无平台代持服务凭据；资产只声明凭据元数据，创建者全程不接触密钥值。

auth-service 不拥有上述业务数据，若放 auth-service 则需反调 mgmt-service，变成无逻辑的代理。

**auth-service 职责边界**：验证身份（"这个人是谁"），不负责业务凭据解析（"这个人对这个目标应该用哪把钥匙"）。

### D2 — 两个独立接口，不做合并

```
POST /mgt/vault/inbound/resolve-asset    ← 资产调用运行时调用
POST /mgt/vault/inbound/resolve-model    ← AI SDK 调用
```

不合并为单一接口的理由：

- 入参不同：resolve-asset 需 assetId（必填），resolve-model 不需要
- 出参不同：resolve-model 返回 availableModels[]，resolve-asset 不需要
- 校验逻辑不同：resolve-asset 需检查有效使用授权、资产状态与 admin 出站停用，resolve-model 需检查模型可用性快照
- 调用方不同：各自只用一半的契约，合并后接口变成两套行为的 dispatcher

两个接口内部共享 Key Vault 读取层、缓存和审计日志。

### 解析流程

**resolve-asset**（资产调用运行时调用）：
```
1. getAsset(assetId) → 资产状态 + 凭据元数据声明
2. checkAdminDisabled(asset)
3. checkEffectiveUseAuthorization(userId, asset)
   # 已通过订阅，或有效 Owner/Deputy 免订阅自用
4. cred = personalCredential(userId, asset)
5. if !cred: throw NO_CREDENTIAL
6. return cred
7. 记录 source（审计：个人凭据 ID + 持有人账号）
```

资产调用不使用旧资产凭据模型，也不使用平台资源凭据兜底。动态凭据资产在订阅通过或负责人自用触发时由平台代颁发；颁发失败不影响订阅/负责人使用授权本身，但调用前仍因无可用个人凭据失败并引导处理。

**resolve-model**（AI SDK 调用）：
```
1. creds = personalNexusCredentials(userId)        → 有序列表
2. for cred in creds:
     if cred.enabled && cred.snapshotAvailable:
       return cred + cred.availableModels
3. return platformDefaultNexusCredentialObject()
4. 记录 source（审计：个人凭据 ID 或平台内部 Nexus 凭据对象 ID）
```

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 解析放 auth-service | 语义上"凭据"与 auth 相关 | 不拥有数据，需反调 mgmt，变成 pass-through proxy | 增加一跳延迟且无实际逻辑 |
| 单一统一接口 `POST /mgt/vault/inbound/resolve` + targetType | 端点数少 | 入参/出参/校验均需条件分支，接口契约不精确，测试矩阵翻倍 | 表面统一，实际两套行为 |
| 运行时组件直接访问 Key Vault 自行解析 | 少一次网络调用 | 运行时组件需理解订阅、Owner/Deputy 免订阅、凭据绑定、admin 停用等业务逻辑 | 违反关注点分离 |
| 资产调用使用平台资源凭据兜底 | 可减少用户配置失败 | 模糊调用责任主体，违背 2026-08-24 凭据模型裁定 | 禁止：资产调用未配置/失效即失败并引导配置 |

## 影响

- 受影响服务：mgmt-service（credential 模块维护两个内部解析端点）
- 契约影响：`contracts/openapi/grc-mgmt-service.yaml` 中解析端点须表达有效使用授权、个人凭据缺失与平台默认 Nexus 凭据对象三类结果
- ADR-001 D4 需按本 ADR 更新：运行时发起解析请求，业务解析由 mgmt-service 提供；不得再描述运行时直接取资产服务凭据

## 后果

### 正面

- 数据与逻辑同源——credential 模块拥有数据也拥有解析规则，无跨服务业务逻辑重复
- auth-service 保持纯粹的身份验证职责
- 两个接口各自契约精确，独立演进互不影响
- 资产调用责任主体清晰：个人凭据失败即失败，不回落共享身份

### 负面

- mgmt-service 成为资产调用和模型调用的关键路径——缓解：缓存非敏感解析元数据与凭据引用；Key Vault 不可达时只按安全策略使用仍有效的短期缓存
- 两个接口需各自维护——但共享底层基础设施，实际维护成本低
