<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-java-common 状态卡（更新于 2026-W33）

## 职责与边界
Java 共享库：统一错误处理、认证工具类、公共模型，供 grc-api-gateway / grc-auth-service / grc-mgmt-service 三个 Java 服务共用。不含业务逻辑。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：无（内部共享库，不对外暴露 API）
- 消费契约：无
- 多模块：common-service-cache / common-service-common / common-service-core

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Java / Maven（多模块）
- 被三个 Java 服务以 Maven 依赖方式引用
<!-- /人工区块 -->
