# Tasks: grc-ai-sdk（credentialId 解析与 Chat 图像输入承载）

**Input**: `specs/007-credential/spec.md`、`specs/007-credential/plan.md`、
`specs/001-conversation/spec.md`、`contracts/openapi/grc-mgmt-service.yaml`

**约定**（`sop/artifacts.md`）：按**服务**分组；`[P]` 标可并行任务；末尾固定“更新 Project Memory”。

---

## grc-python-sdk（共享库）

### 测试先行（先写，先红）

- [x] T701 [P] `credential_resolver.py` 行为测试：只按调用方给定的 `credentialId` 调
      `GET /mgmt/vault/outbound/credentials/{id}/resolve?userId=<int64>`；`userId` 对 grc-ai-sdk
      路径是 **必传的归属校验参数**，但不参与 SDK 内部选凭据
- [x] T702 [P] 鉴权测试：宿主工作负载访问令牌缺失 / 无效 / 无权限，以及 `userId`
      缺失 / 与凭据持有人不匹配时，mgmt-service resolve 失败直接向上返回，不做 SDK 内部降级
- [x] T703 [P] 缓存测试：解析结果仅按 **(`userId`, `credentialId`)** 做 60 秒进程内缓存，
      支持显式失效；严禁仅按 `credentialId` 缓存；
      `resolvedFields` 不写日志、不落盘
- [x] T704 [P] ChatPort 多模态序列化测试：Base64 JPEG/PNG/WebP → OpenAI-compatible
      content parts + data URI；纯文本请求保持兼容
- [x] T705 [P] 回归测试：图像输入场景下流式输出与 tool calling 兼容语义不退化
- [x] T706 [P] deprecated 兼容测试：raw `api_key` / `callback` / `*_for_user` 与历史
      `MULTIMODAL` 别名在一版过渡期内给出明确 deprecation 提示

### 实现

- [x] T707 `credential_resolver.py`：移除 `resolve-model` / `for_user` 默认主路径，改为
      `credentialId` 精确解析；兼容 `ApiResponse.code` 返回 `"0"` / `0`，并按运行时语义处理
      numeric `credentialId` / string `targetId`
- [x] T708 `factory.py` / public API：生产推荐入口收敛到 `credentialId`；旧入口保留一版
      deprecated shim，并计划于 1.0 移除
- [x] T709 `ports/` + `domain/`：为 ChatPort 增加图像输入规范类型（Base64、detail、数量/大小限制）；
      `DOCUMENT_PARSE` 与 Chat vision 分离
- [x] T710 `adapters/`：内部序列化为 OpenAI-compatible content parts / data URI；
      resolve 响应按 `targetType = NEXUS` / `authType = NEXUS_PERSONAL_TOKEN` 解释，
      `NEXUS_PERSONAL_TOKEN` 读取 `resolvedFields.nexus_token` 作为 Nexus Authorization token；
      `model_gateway_base_url` / provider / query params 取自调用方或模型配置，不取自 vault
      `endpoint` / `protocol`（二者仅为可空返回元数据）；Provider 4xx/5xx/网络错误直接返回调用方，
      不自动 fallback / report-failure / 改写快照
- [x] T711 模型类别迁移：保留历史 `MULTIMODAL -> DOCUMENT_PARSE` deprecated alias 一版，
      发布迁移说明，1.0 移除
- [x] T712 真实联调：2026-09-16 使用 GPT-5.5 完成 Base64 PNG PoC，模型正确识别图片主色；
      同时确认该模型应使用 `max_completion_tokens` 而不是 `max_tokens`

---

## grc-mgmt-service（契约与服务身份授权）

> 以下任务由负责 grc-mgmt-service 的团队执行；此处登记依赖与联调要求。

- [x] T721 保持既有 `GET /mgmt/vault/outbound/credentials/{id}/resolve` 为唯一 SDK 内部解析端点，
      不新增 `resolve-model`
- [ ] T722 对内部 resolve 端点启用服务身份授权：允许受信工作负载以 Azure Workload Identity
      访问令牌调用
- [x] T723 契约/文档对齐：明确 grc-ai-sdk 调用时必须传 int64 `userId` 做凭据归属校验；
      成功响应语义为 numeric `credentialId`、`targetType = NEXUS`、string `targetId`、
      `authType = NEXUS_PERSONAL_TOKEN`、nullable `endpoint` / `protocol`、
      `resolvedFields.nexus_token`；其中仅 `authType` / `resolvedFields` 供模型鉴权即时使用，
      `endpoint` / `protocol` 不是 SDK 模型 URL / provider 选择器；不得要求调用方落库或日志化

---

## grc-agent-service（当前首个消费方）

- [ ] T731 Chat 业务层在进入 SDK 前完成 `credentialId` 选择、用户/业务授权与模型选择；
      不再依赖 `build_chat_adapter_for_user`
- [ ] T732 Chat 图片输入：只接收 Base64 JPEG/PNG/WebP，单次 ≤ 4 张、单张 ≤ 10 MiB、
      总计 ≤ 20 MiB；120 秒默认超时可配置
- [ ] T733 非 vision 模型收到图片时保持 Provider 4xx 直返；不在 SDK 内自动兜底到平台凭据

---

## 收尾

- [x] T741 `retro.md`：记录从 `userId` 自动选凭据迁移到 `credentialId` 的偏差与影响，
      以及 `MULTIMODAL` deprecated alias 的退场计划
- [x] T742 **更新 Project Memory**（宪法第五条）：更新 `memory/now/services/grc-python-sdk.md`、
      `memory/now/services/grc-agent-service.md`、必要时 `memory/now/watchlist.md`
      （补记 Nexus Base64 图片 PoC 状态与兼容窗口）。**做不完本任务，本 spec 不算完成**
