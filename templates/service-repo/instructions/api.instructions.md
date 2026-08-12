---
applyTo: "**/api/**,**/controllers/**,**/handlers/**"
---
# API 路径级指令

- 对外接口必须与 hub（`../{{HUB_DIR}}/contracts/`）中本服务**已合并**的契约一致；
  不得引入契约未声明的字段/端点/事件。
- 错误响应遵循统一错误体与服务前缀错误码（见 hub cross-cutting/error-codes）。
- 需要新增或修改跨服务接口 → 回 hub 走 `contract-change`，不要在此私自扩展。
