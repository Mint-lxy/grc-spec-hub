---
name: onboard-services
description: "批量孵化已拆解好的多个服务：读取 services.manifest.yaml，一次性生成 service-map 段落、记忆卡、服务仓库脚手架并 link-hub 接通上下文。Use when: 项目启动时子服务已全部拆解、需要一次性接入多个服务、bulk onboard services、批量建仓、from service manifest。"
argument-hint: "确认清单已填好，如 'architecture/services.manifest.yaml 共 8 个服务，已评审无环'"
---
# Skill: 批量孵化服务

当项目启动时子服务**已经拆解完毕**，用本流程把它们一次性接入平台，而不是逐个手动
重复 `/new-service`。单个新增服务仍用 [`/new-service`](../new-service/SKILL.md)。

## 前置
- [`architecture/services.manifest.yaml`](../../../architecture/services.manifest.yaml) 已填入全部真实服务
  （name / repo / owner / domain / provides / consumes / depends-on / milestone）。
- [`hub.config.yaml`](../../../hub.config.yaml) 已绑定项目；守门点人审机制已就位。
- 平台边界已在 `specs/000-platform` 论证过，各服务边界与之一致。

## 步骤

1. **校验清单**（先做，失败就停）：
   - `project` 与 `hub.config.yaml` 的 `project.id` 一致；
   - 服务名唯一、符合命名规范；
   - `depends-on` 引用的服务都在清单内；
   - 依赖图**单向无环**（拓扑排序成功）；成环 → 报告环路并停止，改为事件解耦 + ADR。

2. **按拓扑顺序生成 `service-map.md`**：为每个服务生成一段机器可读块，
   并据 `depends-on` 生成 Mermaid 依赖图。整段替换 `## 服务清单` 下的占位样例。
   格式严格对齐 [`service-map.md` 的“机器可读约定”](../../../architecture/service-map.md)。

3. **批量建记忆卡**：对每个服务复制 [`_TEMPLATE.md`](../../../memory/now/services/_TEMPLATE.md)
   为 `memory/now/services/<svc>.md`，填入 `domain`/初始状态/里程碑。删除 `_EXAMPLE-svc-order.md`。

4. **人审合并（第一个守门点）**：把 service-map + 记忆卡作为**一个 PR** 提交人审。
   这是“项目服务拓扑”的正式确认点，必须人审通过再继续。

5. **批量实例化服务仓库**：对每个服务执行 [`/new-service`](../new-service/SKILL.md) 的建仓步骤
   （克隆到 hub 同级目录 + 脚手架 `templates/service-repo/` + 占位替换）。
   可脚本化循环 manifest；每个服务一个建仓 PR，便于分别人审。

6. **逐个 link-hub 接线**：在每个服务仓库根目录运行
   `../<hub-dir>/scripts/link-hub.ps1`（或 `.sh`），确认全部校验通过
   （hub 可达、skills 链接、工作区、AGENTS.md 无占位符）。

7. **冒烟**：挑 1–2 个入口服务，用多根工作区跑一个最小任务，
   验证 agent 能沿 `../<hub-dir>/` 读到宪法/记忆卡/契约。

## 完成判据
- 清单校验通过（无环）；service-map 全部服务已登记且图无环；
- 每个服务都有记忆卡、服务仓库；link-hub 校验全部通过；
- manifest ↔ service-map 一致（服务数量、依赖方向对齐）。

## 与其它 skill 的关系
- 批量之后新增单个服务 → [`/new-service`](../new-service/SKILL.md)（记得回填 manifest）。
- 服务间接口变更 → [`/contract-change`](../contract-change/SKILL.md)。
