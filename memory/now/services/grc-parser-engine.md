<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-parser-engine 状态卡（更新于 2026-W37）

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
- 正式 parser镜像尚未补齐 OFA的 ModelScope多模态依赖（watchlist #87）
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI（GPU 优化部署）
- 开发 AKS 已采用自管 NVIDIA Device Plugin v0.18.0；`gpupool` 使用
  `sku=gpu:NoSchedule`，可分配 `nvidia.com/gpu: 1`。
- parser 部署必须声明 GPU limit、`gpupool` 调度约束和对应 toleration；部署工件见
  `grc-parser-engine/deploy/aks/gpu/`（spec 010，commit `513d51d`）。
- 开发 AKS 已交付 `parser-models-0c032755b9083fff`：518 个文件、约 19.8 GiB，位于
  `grc-parser/parser-models` 128 GiB Premium PVC；部署工件见
  `grc-parser-engine/deploy/aks/models/`（spec 012，commit `3484fcc`）。
- parser必须显式按 bundle ID只读挂载模型；Docling布局目录使用
  `docling-project--docling-layout-heron`。
- 生产环境不得直接照搬开发配置，须重新验收驱动、镜像 digest、taint 和 GPU smoke。
<!-- /人工区块 -->
