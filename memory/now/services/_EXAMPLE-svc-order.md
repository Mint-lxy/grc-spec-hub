<!-- 自动区块：由 memory-digest 管线维护，人工修改会被覆盖 -->
<!--
  这是一张【示例】服务卡，展示格式与信息密度。
  第 0 周孵化真实服务时，用 _TEMPLATE.md 生成真实服务卡并删除本示例。
-->
# svc-order 状态卡（示例 · 更新于 2026-W28）

## 职责与边界
订单生命周期管理。不做支付（→ svc-billing）、不做库存（→ svc-inventory）。

## 当前状态
- 里程碑 M2 进行中：specs/007（通知）、specs/009（退款流程）
- 提供契约：contracts/openapi/order.yaml v1.3
- 消费契约：billing v2.1、inventory v1.0；订阅事件：payment.completed

## 近期重要变化（最近 4 周）
- W28: 订单状态机新增 REFUNDING 态（ADR-014），下游若有状态枚举硬编码需适配
- W26: 幂等键从 header 迁移到 body（契约 v1.3 破坏性变更，消费者已全部确认）

## 已知问题
- 高并发下超时取消存在竞态（watchlist#3），临时方案见 ADR-013
<!-- /自动区块 -->

<!-- 人工区块：owner 手工维护 -->
## 给 agent 的特别提醒
- 状态机变更必须走 src/domain/state_machine.ts 的声明式定义，
  不要在业务代码里散落状态判断
<!-- /人工区块 -->
