# ADR-005: 凭据解析归属 mgmt-service，双接口分离资产与模型两条路径

> 状态：Accepted
> 日期：2026-08-17 · 决策者：@nzhang · 关联 spec：`specs/007-credential`

## 背景

平台有两类出站调用需要凭据解析：

1. **资产调用**（Agent/MCP）— gateway 转发用户请求到外部资产，需注入正确的出站凭据。
2. **模型调用**（Nexus LLM/Embedding/Rerank）— 内部 Python 服务经 AI SDK 调用 Nexus，需注入正确的 Nexus PAT。

两条路径的解析规则不同：

| | 资产调用 | 模型调用 |
|---|---|---|
| 调用方 | gateway（Java） | AI SDK（Python 服务） |
| 输入 | assetId + userId | userId |
| 解析规则 | 按资产认证模式：service → 资产服务凭据；per-user → 个人出站凭据（AC-19/20，不兜底 AC-8） | 按序取个人 Nexus PAT（启用且可用）→ 平台默认兜底（AC-12） |
| 额外检查 | 订阅状态、admin 停用（AC-22） | 无 |
| 响应 | credential + source + targetEndpoint | credential + source + availableModels[] |

需要决定：(A) 解析 API 放哪个服务？(B) 一个接口还是两个？

## 决策

### D1 — 凭据解析 API 归属 mgmt-service

凭据解析所需的全部数据均归 mgmt-service 所有：

- 资产认证模式 → asset-catalog 模块
- 资产级服务凭据 → credential 模块
- 个人出站凭据 / 个人 Nexus PAT → credential 模块
- 平台默认 Nexus 凭据 → admin/model-settings 模块
- 订阅状态 → subscription 模块
- admin 出站停用标志 → admin 模块
- Key Vault 读取 → credential 模块基础设施

auth-service 不拥有上述任何数据，若放 auth-service 则需反调 mgmt-service，变成无逻辑的代理。

**auth-service 职责边界**：验证身份（"这个人是谁"），不负责业务凭据解析（"这个人对这个目标应该用哪把钥匙"）。

### D2 — 两个独立接口，不做合并

```
POST /mgt/vault/inbound/resolve-asset    ← gateway 调用
POST /mgt/vault/inbound/resolve-model    ← AI SDK 调用
```

不合并为单一接口的理由：

- 入参不同：resolve-asset 需 assetId（必填），resolve-model 不需要
- 出参不同：resolve-model 返回 availableModels[]，resolve-asset 不需要
- 校验逻辑不同：resolve-asset 需检查订阅 + admin 停用，resolve-model 不需要
- 调用方不同：各自只用一半的契约，合并后接口变成两套行为的 dispatcher

两个接口内部共享 Key Vault 读取层、Redis 缓存（TTL 5min）和审计日志（AC-23）。

### 解析流程

**resolve-asset**（gateway 调用）：
```
1. getAsset(assetId) → 认证模式
2. checkAdminDisabled(asset) → AC-22
3. checkSubscription(userId, asset)
4. if authMode == "service":
     return assetServiceCredential(asset) from Key Vault     → AC-19
   if authMode == "per-user":
     cred = personalCredential(userId, asset)
     if !cred: throw NO_CREDENTIAL                           → AC-8 不兜底
     return cred                                              → AC-20
5. 记录 source（审计 AC-23）
```

**resolve-model**（AI SDK 调用）：
```
1. pats = personalNexusPats(userId)        → 有序列表 AC-10
2. for pat in pats:
     if pat.enabled && pat.snapshotAvailable:                 → AC-12
       return pat + pat.availableModels
3. return platformDefaultPat()             → 兜底 AC-12
4. 记录 source（审计 AC-23）
```

## 备选方案

| 方案 | 优点 | 缺点 | 为何不选 |
|------|------|------|----------|
| 解析放 auth-service | 语义上"凭据"与 auth 相关 | 不拥有数据，需反调 mgmt，变成 pass-through proxy | 增加一跳延迟且无实际逻辑 |
| 单一统一接口 `POST /mgt/vault/inbound/resolve` + targetType | 端点数少 | 入参/出参/校验均需条件分支，接口契约不精确，测试矩阵翻倍 | 表面统一，实际两套行为 |
| gateway 直接访问 Key Vault 自行解析 | 少一次网络调用 | gateway 需理解认证模式/订阅/admin 停用等业务逻辑，侵入网关 | 违反关注点分离 |

## 影响

- 受影响服务：mgmt-service（credential 模块新增两个内部接口）
- 契约影响：需在 `contracts/openapi/grc-mgmt-service.yaml` 新增两个内部端点
- ADR-003 更新：Credential Resolver 层指向 mgmt-service（已同步修改）
- ADR-001 D4 保持兼容：gateway "内执行"含义为 gateway 发起调用，实际解析由 mgmt-service 提供

## 后果

### 正面
- 数据与逻辑同源——credential 模块拥有数据也拥有解析规则，无跨服务依赖
- auth-service 保持纯粹的身份验证职责
- 两个接口各自契约精确，独立演进互不影响

### 负面
- mgmt-service 成为资产调用和模型调用的关键路径——缓解：Redis 缓存凭据（TTL 5min），Key Vault 不可达时降级使用缓存
- 两个接口需各自维护——但共享底层基础设施，实际维护成本低
