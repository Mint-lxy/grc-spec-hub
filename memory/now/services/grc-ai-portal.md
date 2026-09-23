<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-ai-portal 状态卡（更新于 2026-W36）

## 职责与边界
AI 平台前端门户（SPA），提供管理、配置、对话、测评等全部用户界面。不做后端业务逻辑（→ 各后端服务）。

## 当前状态
- 知识管理（spec 005）里程碑：M1（Overview 入口）已完成，M2（目录管理）Phase A 已完成、Phase B 受契约阻塞
- 提供契约：无（纯前端）
- 消费契约：contracts/openapi/grc-api-gateway.yaml
- Platform Shell 已落地（仅左侧栏、无顶栏；7 个建设中空路由；`/` 与 `/platform` 落到 `/platform/chat`）
- 侧栏品牌区（圆标 + grc/ AI Agent Portal + CONFIDENTIAL）与 QQ 头像 Popover 用户菜单已落地；折叠展开在侧栏/主内容交界边线；一期导航未改

## 近期重要变化（最近 4 周）
- W37: spec 014 当前环境演示完成：从 EC2 恢复
  `feature/release260911@0cd6ab0`，以 AKS Gateway/Blob origin 和
  `NEXT_PUBLIC_USE_MOCK=false` 重建镜像；AKS Deployment Ready，Internal LoadBalancer
  为 `172.27.104.8`，浏览器等价 bootstrap + 知识库 API 链路通过。部署工件
  `97c36ce`。
- W36: Curate（知识管理）M2 目录管理 Phase A 落地：Knowledge Library 侧栏视觉对齐原型（头部/+Directory/+Knowledge base 按钮/搜索框/目录行样式）；新增顶部 Public Knowledge/My knowledge 范围切换标签，替代原先树内"公共目录/我的目录"虚拟根行；知识库以叶子节点形式懒加载并内联展示在目录树内（复用 `listKnowledgeBases`，未新增契约）；叶子目录（无子目录但有直属知识库）现可展开查看知识库列表。Phase B（创建目录审批人配置、一级目录冷启动）仍受 hub 契约阻塞，待发起 `/contract-change`。现有目录 CRUD 与知识库详情/设置/权限行为零回归。
- W36: Curate（知识管理）重构 M1 落地：入口改为「每次进入 Curate 先展示 Overview（Banner/KPI/Build Pipeline/Documents by Domain 演示数据），经 CTA/滚轮/触摸/滚动进入既有 Owner Knowledge Library」；Header 新增仅 Curate 显示的开发期角色选择器（默认 Owner，通过通用 `HeaderSlotProvider`/`useHeaderSlot` 插槽注入，不违反 ADR-0001 components 不依赖 features 的边界）；`KnowledgeWorkspace` 原有目录树/知识库创建/详情/设置/权限能力零改动、零回归；无新跨服务契约。真实聚合数据（M4）与 SSO/Alice 多角色授权（M5）列入后续子规格，见 `specs/005-knowledge/sub-specs/roadmap.md`。
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
