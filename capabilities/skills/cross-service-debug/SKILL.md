---
name: cross-service-debug
description: "跨服务问题定位：沿 service-map 依赖链排查，以契约为裁判基准。Use when: 联调失败、跨服务行为异常、疑似实现漂移出契约、integration debugging、跨服务 bug 定位。"
argument-hint: "现象与涉及服务，如 'svc-notify 收不到 refund.completed'"
---
# Skill: 跨服务问题定位

## 步骤

1. **锁定边界**：从现象出发，沿 `architecture/service-map.md` 的依赖链
   定位可能的责任服务与跳数。

2. **契约对照**：对每一跳，核对实际请求/事件是否符合 `contracts/` 契约
   （字段/类型/状态码/事件 schema/幂等约定），找出"实现漂移出契约"处。

3. **分类**：契约缺陷 / 实现缺陷 / 配置环境问题。

4. **最小复现**：给出可复现步骤与验证方法。

5. **修复方向**：
   - 契约缺陷 → 走 `contract-change` skill；
   - 实现缺陷 → 指明目标服务与文件方向，交该服务 agent 修；
   - 技术债 → 加入 `memory/now/watchlist.md`。

可直接调用 `integration-check` prompt 执行分析。

## 完成判据
- 责任边界与根因明确；给出复现与修复路径；必要的记忆/契约联动已发起。
