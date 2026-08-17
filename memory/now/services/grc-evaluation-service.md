<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
# grc-evaluation-service 状态卡（更新于 2026-W33）

## 职责与边界
测评服务：发布准入测评任务执行（三类检测）、结果计算与回写。不做任务派发（→ grc-mgmt-service 通过事件触发）。

## 当前状态
- 里程碑 M1 进行中
- 提供契约：contracts/openapi/grc-evaluation-service.yaml, contracts/events/eval-result.asyncapi.yaml
- 消费契约：contracts/events/eval-task.asyncapi.yaml

## 近期重要变化（最近 4 周）
- W33: 服务孵化，初始化仓库脚手架

## 已知问题
- 无
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 技术栈：Python / FastAPI
- AI API 调用统一经 grc-ai-sdk（grc-python-sdk），不直接调用 provider API（ADR-003）
<!-- /人工区块 -->
