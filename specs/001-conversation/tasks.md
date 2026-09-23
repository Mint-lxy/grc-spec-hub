# Tasks: 对话工作台（平台 Chat）

**Input**: `specs/001-conversation/spec.md`、`specs/001-conversation/plan.md`、
`contracts/openapi/grc-agent-service.yaml`、`contracts/openapi/grc-mgmt-service.yaml`

**约定**（`sop/artifacts.md`）：按**服务**分组；`[P]` 标可并行任务；末尾固定"更新 Project Memory"。

---

## grc-agent-service（无状态推理执行引擎）

### 测试先行（先写，先红）

- [ ] T101 [P] 契约测试：`POST /chat/sessions/{id}/messages` 请求/响应结构对齐
      `contracts/openapi/grc-agent-service.yaml`，`tests/test_chat_api.py`
- [ ] T102 [P] 契约测试：`.../regenerate`、`POST /chat/sessions/{id}/cancel`，`tests/test_chat_api.py`
- [ ] T103 [P] `mgt_client.py` 行为测试（`get_context`/`append_message` 正常与异常路径，
      用 `httpx.MockTransport` 隔离），`tests/test_mgt_client.py`
- [ ] T104 [P] `knowledge_client.py` 行为测试（多知识库检索调用），`tests/test_knowledge_client.py`
- [ ] T106 编排器测试：纯对话、知识库引用、步数超限、中止生成四类场景，
      `tests/test_orchestrator.py`（内存 fake 隔离外部依赖，不依赖真实网络）

### 实现

- [ ] T107 `app/config.py`：新增 `grc-mgmt-service`/`grc-knowledge-engine`/LLM 网关
      的地址配置
- [ ] T108 `app/services/mgt_client.py`：调用 `GET /mgmt/internal/chat/sessions/{id}/context`、
      `POST /mgmt/internal/chat/sessions/{id}/messages`（依赖 T103 先红）
- [ ] T109 [P] `app/services/knowledge_client.py`：调用 `grc-knowledge-engine`
      `POST /knowledge/retrievals`（依赖 T104 先红）
- [ ] T111 [P] `app/services/llm_client.py`：经 `grc-python-sdk` 的 `ChatPort` 调用 LLM，
      由业务层在进入 SDK 前完成模型与 `credentialId` 选择；纯文本路径保持兼容
- [ ] T112 `app/services/cancel_registry.py`：技术态缓存，记录进行中生成的中止标记
      （单实例先用进程内 set，多实例路由方案见 plan.md 待评审确认项，本任务不解决多实例问题）
- [ ] T113 `app/orchestrator.py`：检索增强编排 + 流式生成 + 中止信号检查，串联
      T108、T109、T111、T112（依赖 T106 先红）
- [ ] T114 `app/api/chat.py`：三个端点的路由与请求/响应装配（依赖 T101/T102 先红、T113）
- [ ] T115 `app/guardrails/hooks.py`：输出侧护栏钩子占位（非流式响应检测通过后直接完整呈现，
      流式响应走滑动窗口检测；具体由本服务还是网关实现待 plan.md 待评审确认项定论）
- [ ] T116 端到端本地联调：mock `grc-mgmt-service`/`grc-knowledge-engine` 与真实
      LLM 网关联调，验证四类能力组合（知识库引用、流式、中止、图像输入）

### 2026-09-15 补充变更集（Chat 图像输入 + SDK 边界）

- [ ] T117 [P] 契约/接口测试：`POST /chat/sessions/{id}/messages` 增加图像输入校验
      （Base64、JPEG/PNG/WebP、≤4 张、≤10 MiB/张、≤20 MiB 总量、`detail=auto/low/high`），
      `tests/test_chat_api.py`
- [ ] T118 [P] `app/services/llm_client.py` 与 `grc-python-sdk` 联调：图像输入走
      OpenAI-compatible content parts + data URI；Provider 4xx 直返，不依赖 SDK 自动 fallback
- [ ] T119 `app/orchestrator.py`：组合文本+图像输入、120 秒默认超时可配置、纯文本回归、
      流式输出与既有 tool-calling 承载兼容回归
- [x] T120 真实兼容性验证：2026-09-16 使用 GPT-5.5 完成 Nexus Base64 PNG PoC，
      图片解析与文本响应成功；业务 API/持久化接入仍由 T117~T119 承担

---

## grc-mgmt-service（chat 会话子域，跟踪依赖，非本方实现）

> 以下任务由负责 grc-mgmt-service 的团队执行，此处登记依赖关系，便于跟踪联调时间点。

- [ ] T201 会话 CRUD 实现：`POST/GET/PATCH/DELETE /mgmt/chat/sessions*`
- [ ] T202 知识库挂载实现：`PUT/GET /mgmt/chat/sessions/{id}/knowledge-mounts`
      （挂载前复用 `/mgmt/internal/check` 的 `CATALOG` 校验，无权限静默剔除）
- [ ] T203 内部接口实现：`GET /mgmt/internal/chat/sessions/{id}/context`、
      `POST /mgmt/internal/chat/sessions/{id}/messages`（grc-agent-service 的 T108 依赖此项）
- [ ] T204 消息历史持久化表设计（会话/挂载/消息三类数据的存储结构，由该团队自行设计，
      不受 grc-agent-service 约束）

---

## grc-api-gateway（路由透传）

- [ ] T301 新增路由：`/api/v1/chat/**` → grc-agent-service（SSE 响应需要关闭网关侧响应缓冲）
- [ ] T302 [P] 新增路由：`/api/v1/mgmt/chat/**` → grc-mgmt-service

---

## 收尾

- [ ] T401 跨服务集成验证：grc-agent-service ↔ grc-mgmt-service 的 context/回写接口联调
      （依赖 T108、T203 均完成）
- [ ] T402 `retro.md`：记录实现与 plan.md 的偏差（尤其是 plan.md 里标注的几个待评审确认项
      最终是怎么定的）
- [ ] T403 **更新 Project Memory**（宪法第五条）：更新 `memory/now/state.md`
      （spec 001 完成状态）、`memory/now/services/grc-agent-service.md` 与
      `memory/now/services/grc-mgmt-service.md` 服务记忆卡、`memory/now/watchlist.md`
      （登记"agent-service 多实例 cancel 路由方案未定"等遗留风险）。**做不完本任务，
      本 spec 不算完成**（宪法第五条）。
