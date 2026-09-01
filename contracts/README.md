# contracts/ — 跨服务契约中心

接口的**唯一事实源**。先读 [`POLICY.md`](POLICY.md)。

- `openapi/` — 每个服务对外提供的 REST 契约（`<svc>.yaml`，OpenAPI 3.1）
- `events/` — 事件/消息契约（`<domain>.asyncapi.yaml`，AsyncAPI 2.x）
- `shared/` — 跨服务共享的数据模型（`*.schema.json`，JSON Schema）

`_example/` 下有可参照的样例，正式契约请放在对应子目录，不要放在 `_example/`。
