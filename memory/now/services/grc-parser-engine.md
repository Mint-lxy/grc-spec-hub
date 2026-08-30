<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-parser-engine 状态卡（更新于 2026-W35）

## 职责与边界
文档解析（GPU 优化）：Docling/MinerU 解析器执行，接收知识引擎调度。不做向量化（→ grc-knowledge-engine）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-parser-engine.yaml
- 消费契约：无

## 近期重要变化（最近 4 周）
- W35: 解析状态 fix（`c291db9`，+4756）——与 knowledge-engine `08a25b2` 构成解析链路两侧联动，支撑 005 Pipeline 阶段状态展示
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- knowledge 与 parser 两份契约的 ParserConfig 互不一致（watchlist #71⑦）
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI（GPU 优化部署）
<!-- /人工区块 -->
