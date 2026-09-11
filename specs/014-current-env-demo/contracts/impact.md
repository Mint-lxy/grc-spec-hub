# Contract Impact: 当前环境端到端演示

## 变更范围

### `grc-api-gateway.yaml`

- 版本从 `0.1` 升至 `0.2`。
- 新增当前知识库演示所需的 Auth/Mgmt 代理路径。
- Path Item 直接引用 Auth/Mgmt 的既有契约，Gateway 不重新定义业务 DTO。
- 新增 `bearerAuth`，登录与刷新继续沿用 Auth 契约中的匿名安全声明。

**兼容性结论**：非破坏性。原契约 `paths` 为空，本次只新增端点。

**消费方**：`grc-ai-portal`。

### `grc-knowledge-engine.yaml`

- `/readyz` 新增 `503` 响应，表示一个或多个必需运行时依赖不可用。
- `200` 响应保持原有自由对象结构，不收紧字段。

**兼容性结论**：按 `contracts/POLICY.md`，“修改状态码语义”视为破坏性。虽然新增失败响应
不改变成功响应，但消费方若假设 `/readyz` 永远返回 200，会受到影响。

**需确认消费方**：

- `confirmed-by:grc-api-gateway`（2026-09-11 用户人审确认）
- `confirmed-by:grc-mgmt-service`（2026-09-11 用户人审确认）
- `confirmed-by:grc-agent-service`（2026-09-11 用户人审确认）

### 服务地图

- 补录代码中已经存在的 `grc-mgmt-service → grc-knowledge-engine` 调用关系。
- 同步更新 `architecture/service-map.md` 与 `architecture/services.manifest.yaml`。

## 兼容策略

1. Gateway facade 只发布本次 P1 演示使用的登录、上传、知识库和任务查询路径。
2. Knowledge `/readyz` 的 `200` body 保持兼容；只在真实必需依赖失败时返回 `503`。
3. Kubernetes readinessProbe 原本已按非 2xx 判定未就绪，无需迁移。
4. 业务调用方不得依赖 `/readyz` 永远成功；消费方确认后再实现 503 行为。

## 门禁结果

- Gateway 草案经 Redocly 校验为 valid，仅继承被引用 Mgmt 操作缺少 4xx 响应的既有警告。
- 全仓 `check-contracts.ps1` 当前仍因基线问题失败：
  - Auth/Knowledge 既有 `security-defined`/server 错误；
  - AsyncAPI 校验器请求不存在的 `@asyncapi/studio@^1.2.0`；
  - 本机缺少 `oasdiff`，无法自动执行破坏性对比。
- 合并前必须完成缺失的破坏性人工复核与上述消费方确认。

## 人类守门点

2026-09-11 用户确认契约草案无问题并批准继续，三个消费方确认已齐全。
