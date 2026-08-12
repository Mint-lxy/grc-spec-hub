---
name: contract-change
description: "契约变更全流程：草案、破坏性评审(oasdiff)、消费者确认、发布。Use when: 新增/修改 contracts/ 下任何跨服务接口(REST/事件/共享模型)、breaking change、OpenAPI/AsyncAPI 变更、consumer confirmation。"
argument-hint: "要变更的契约与意图，如 'billing 新增 refund.completed 事件'"
---
# Skill: 契约变更全流程

遵守宪法第二条（契约先行）与 `contracts/POLICY.md`。

## 步骤

1. **起草**：在 `specs/<NNN>/contracts/` 或直接对 `contracts/` 提草案 PR。
   - REST → `openapi/<svc>.yaml`；事件 → `events/<domain>.asyncapi.yaml`；
     共享模型 → `shared/*.schema.json`。

2. **自评审**：运行 `contract-review` prompt 生成影响分析
   （破坏性结论 + 消费方影响表 + 兼容策略）。

3. **本地门禁**：在 hub 根目录运行 `./gates/scripts/check-contracts.ps1`（或 `.sh`）：
   - 语法校验（redocly / asyncapi）；
   - 破坏性检测（oasdiff，对比 main）。

4. **分流**：
   - **非破坏性** → 人审后合并。
   - **破坏性** → 从 `service-map.md` 的 `consumes:` 列出**全部消费方**，
     写进 PR 描述并逐一 @ owner。按 POLICY 采用
     "新版本并存 + 双写过渡"，而非原地改。

5. **消费者确认**：各消费方 owner 在 PR 追加 `confirmed-by:<svc>` 评论；
   集齐全部消费方后方可合并（这一步本身就是接口变更通知）。

6. **发布**：合并即发布——pull 模型下各服务 agent 直读 hub `contracts/`，
   无需同步副本。各消费方在兼容窗口内完成迁移，之后用一条清理 spec 下线旧版本。

7. **记忆**：在相关服务卡"近期重要变化"记录本次契约变化（随 spec 收尾 task）。

## 完成判据
- 本地门禁绿；破坏性变更已集齐消费者确认；记忆已更新。
