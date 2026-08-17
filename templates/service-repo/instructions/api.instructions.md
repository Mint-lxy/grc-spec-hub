---
applyTo: "**/api/**,**/controllers/**,**/handlers/**"
---
# API 路径级指令

- 对外接口必须与 hub（`../{{HUB_DIR}}/contracts/`）中本服务**已合并**的契约一致；
  不得引入契约未声明的字段/端点/事件。
- 错误响应遵循 RFC 9457 统一错误体与服务前缀错误码（见 hub `architecture/cross-cutting/error-codes.md`，ADR-002）。
- 新增接口错误码必须在 hub `error-codes.md` 注册后再使用。
- AI API 调用（LLM/Embedding/Rerank）统一经 `grc-ai-sdk`，不直接调用 provider API（ADR-003）。
- 需要新增或修改跨服务接口 → 回 hub 走 `contract-change`，不要在此私自扩展。
