# 契约兼容性政策（POLICY）

`contracts/` 是**跨服务接口的唯一事实源**。代码只能引用已合并的契约版本（宪法第二条）。

## 1. 契约类型与位置

| 类型 | 位置 | 规范 |
|------|------|------|
| REST 接口 | `openapi/<svc>.yaml` | OpenAPI 3.1 |
| 事件/消息 | `events/<domain>.asyncapi.yaml` | AsyncAPI 2.x |
| 共享数据模型 | `shared/*.schema.json` | JSON Schema |

## 2. 什么算破坏性变更

**破坏性（需消费者确认）：**
- 删除或重命名端点 / 事件 / 字段；
- 收紧类型、缩小枚举、把可选字段改为必填；
- 修改路径、方法、状态码语义；
- 修改事件的 channel / routing key / 分区键含义。

**非破坏性（可直接合并）：**
- 新增端点 / 事件 / 可选字段；
- 放宽约束（扩大枚举、可选化必填字段）；
- 文档/示例/描述性变更。

判定由本地门禁脚本 `gates/scripts/check-contracts.{ps1,sh}` 用 `oasdiff`（OpenAPI）
等工具检测，人审复核。

## 3. 版本策略

- 语义化：`MAJOR.MINOR`（契约层不区分 patch）。
- **破坏性变更 → MAJOR+1**，且在过渡期内**新旧版本并存**（`order.yaml` 与
  `order.v2.yaml`，或 OpenAPI 内 `servers`/路径前缀 `/v2`）。
- 非破坏性 → MINOR+1。
- 事件破坏性变更优先"新增新事件 + 双写过渡"，而非原地改。

## 4. 变更流程（对应 skill: contract-change）

```
1. 在 specs/NNN/contracts/ 起草，或直接对 contracts/ 提 PR
2. 合并前跑 gates/scripts/check-contracts：语法校验 + 破坏性检测
3. 非破坏性 -> 人审合并
   破坏性 -> 在 PR 中列出全部消费方并逐一 @ owner（消费方来自 service-map.md）
4. 全部消费方以 `confirmed-by:<svc>` 评论确认
5. 合并即发布：pull 模型下各服务 agent 直读 hub contracts/，无需同步副本
```

## 5. 消费者确认机制

- 消费方清单**唯一来源**是 `architecture/service-map.md` 中各服务的 `consumes:` 声明。
- 因此：新增一个消费方，必须先更新 service-map.md，否则不会收到确认请求。
- 确认以对上游 PR 追加评论 `confirmed-by:<service-name>` 完成；
  人审合并前核对是否集齐全部消费方确认。

## 6. 兼容窗口

破坏性变更合并后，旧版本至少保留 `[待确认: 一个里程碑 / N 周]`，
待所有消费方迁移并在各自 retro 中确认后，由一条清理 spec 下线旧版本。
