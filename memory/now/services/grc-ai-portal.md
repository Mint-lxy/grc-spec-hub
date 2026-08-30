<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-ai-portal 状态卡（更新于 2026-W35）

## 职责与边界
AI 平台前端门户（SPA），提供管理、配置、对话、测评等全部用户界面。不做后端业务逻辑（→ 各后端服务）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：无（纯前端）
- 消费契约：contracts/openapi/grc-api-gateway.yaml
- Platform Shell 已落地（仅左侧栏、无顶栏；7 个建设中空路由；`/` 与 `/platform` 落到 `/platform/chat`）
- 侧栏品牌区（圆标 + grc/ AI Agent Portal + CONFIDENTIAL）与 QQ 头像 Popover 用户菜单已落地；折叠展开在侧栏/主内容交界边线；一期导航未改

## 近期重要变化（最近 4 周）
- W35: Marketplace 前端里程碑基本铺满（spec 002，feature/release260831）：M1 资产频道与列表可见性（`e7df1bf`）、M3 订阅申请+M4 审批工作台（`038894c`）、M5 订阅者中心（`b90a540`）、M6 凭据状态+M7 创作者中心（`af0c9cc`）、M8 生命周期联动+M9 发现增强（`3867951`）
- W35: 知识库概览与设置落地，对齐 spec 005 三档可见性与权限门控（`6047d48`）；知识域 API 与 feature 分层固化、目录树与建库向导（`74fc3c4`）
- W34: 侧栏品牌区与用户菜单（002-sidebar-brand-user）。圆标 +「grc/」+「AI Agent Portal」+ CONFIDENTIAL；底部 QQ 头像打开占位资料/通知/退出登录；无新跨服务契约；一期导航未改。
- W34: 落地运营平台页面底座（Platform Shell）。仅侧栏 + 主内容；对话/Marketplace/知识管理/订阅者中心/创作者中心/密钥库/管理后台为空态「建设中」。无新跨服务契约。
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- feature/release260831 领先 main 25 个提交未合并；release/release260831 落后——发版基线待确认
- logout URL [待确认]，退出仅为 UI 占位，不调用后端登出
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：React / TypeScript
<!-- /人工区块 -->
