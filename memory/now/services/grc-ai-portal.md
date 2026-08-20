<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-ai-portal 状态卡（更新于 2026-W34）

## 职责与边界
AI 平台前端门户（SPA），提供管理、配置、对话、测评等全部用户界面。不做后端业务逻辑（→ 各后端服务）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：无（纯前端）
- 消费契约：contracts/openapi/grc-api-gateway.yaml
- Platform Shell 已落地（仅左侧栏、无顶栏；7 个建设中空路由；已登录 `/` 与 `/platform` 落到 `/platform/chat`）

## 近期重要变化（最近 4 周）
- W34: 落地运营平台页面底座（Platform Shell）。仅侧栏 + 主内容；对话/Marketplace/知识管理/订阅者中心/创作者中心/密钥库/管理后台为空态「建设中」。无新跨服务契约。
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- logout URL [待确认]，退出仅为 UI 占位，不调用后端登出
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：React / TypeScript
<!-- /人工区块 -->
