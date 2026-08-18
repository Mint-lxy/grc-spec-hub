---
name: hub-qa
description: "项目答疑：基于 hub 事实源（specs/contracts/architecture/memory/standards）回答项目问题，答案必须带出处；答不出即登记文档缺口。Use when: 新人提问、这个接口谁定义的、为什么这么设计、某服务负责什么、术语是什么意思、项目现状如何、任何关于本项目的事实性提问。"
argument-hint: "问题，如 'refund.completed 事件有哪些消费方？' 或 '为什么选了事件驱动？'"
---
# Skill: 项目答疑（hub-qa）

## 铁律

1. **只答有出处的**：每个结论必须附 hub 内文件路径（精确到章节/行）。
   hub 里没有的，明说「hub 未记录」，**不许推测编造**。
2. **以事实层为准**：口头共识、聊天记录、你自己的常识都不是事实源；
   与 hub 冲突时以 hub 为准，并指出冲突。
3. 标注 `[待确认]` 的事实，回答时必须保留该标注。

## 检索路由

| 问题类型 | 先查 |
|---|---|
| 需求/验收标准/为什么做这个 feature | `specs/NNN-*/spec.md` |
| 技术方案/涉及哪些服务 | `specs/NNN-*/plan.md` |
| 接口字段/事件 schema/错误码 | `contracts/`、`architecture/cross-cutting/error-codes.md` |
| 谁消费/谁依赖/服务边界 | `architecture/service-map.md` |
| 为什么这么设计（决策） | `architecture/adr/`、`memory/now/decisions.md`（含被取代的看 `memory/archive/decisions-superseded.md`） |
| 术语 | `memory/now/glossary.md` |
| 项目现状/进行中的事 | `memory/now/state.md`、`memory/now/watchlist.md` |
| 用户疑问/质疑待办（谁提的疑问/哪些疑问未关闭/某文档有哪些疑问） | `memory/now/watchlist.md`（用户疑问分区），并可全局 grep `疑问 #` 定位原文标记 |
| 某服务的现状 | `memory/now/services/<svc>.md`，历史细节下钻 `memory/digests/` |
| 流程/怎么走审批 | `sop/README.md`、`gates/GATES.md` |
| 编码/测试/评审标准 | `standards/` |

## 步骤

1. 按路由表定位候选文件，检索并交叉核对（现状类问题至少同时看
   state.md 与相关服务卡，防止过期信息）。
2. 组织回答：结论 + 出处链接；有多个相关事实时按时间/权威度排序
   （now/ 优先于 digests/ 优先于 archive/）。
3. **缺口回灌**：若答不出或出处过期——
   - 事实缺失 → 提示提问人补记，或将问题登记到 `memory/now/watchlist.md`；
   - 术语缺失 → 建议补 `memory/now/glossary.md`（走人审）。

## 完成判据
- 每个结论有出处；无出处的部分已明确标注「hub 未记录」；缺口已登记或给出补录建议。
