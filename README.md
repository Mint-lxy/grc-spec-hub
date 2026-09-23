# GRC spec Hub

> 一个平台项目的**中枢仓库（spec coding hub）**：纯 AI coding · Spec 驱动 · 多服务架构。
> **框架无关**：可配合 GitHub Spec Kit、Claude Code、Copilot（以及未来的 OpenSpec 等）使用，
> 换框架只换适配器，事实与流程不变。**不依赖任何 CI/SaaS**：全部流程本地可跑。

本仓库不放业务代码，只放**事实源**，让多个服务仓库里的 AI coding agent 并行工作时
**共享同一份事实、遵守同一份契约、沉淀同一份记忆**。

> **第一次用？** 直接看 [使用说明书](manual/README.md)——全新系统 / 部分开发 / 已上线系统，三条傻瓜式路线。

---

## 三层架构（本仓库的设计）

```
┌────────────────────────────────────────────────────────┐
│ L3 适配层 adapters/        每个 AI 框架一个薄适配器        │
│    spec-kit / claude / copilot（只做指针+命令映射）       │
├────────────────────────────────────────────────────────┤
│ L2 流程层 sop/             框架无关的 SOP 状态机          │
│    阶段 → 工件 → 出口判据 → 守门点（artifacts.md 定工件）  │
├────────────────────────────────────────────────────────┤
│ L1 事实层                  specs/ contracts/ architecture/│
│    memory/ standards/ capabilities/ gates/               │
└────────────────────────────────────────────────────────┘
```

- **事实层**回答"是什么"：需求、契约、架构、记忆、标准、能力、门禁。
- **流程层**回答"做什么、判据是什么"：[`sop/`](sop/README.md) 六个阶段，永不出现框架专属命令。
- **适配层**回答"用你的工具怎么做"：[`adapters/`](adapters/README.md)。

## 仓库拓扑：中枢 + 服务群（pull 模型）

```
<workspace-root>/
  grc-spec-hub/          ← 本仓库：事实源 + SOP + 能力资产
  svc-order/             ← 服务仓库（与 hub 同级 clone）
  svc-billing/                agent 沿 ../grc-spec-hub/ 直读事实源
  ...                         （无副本、无同步、无 CI 依赖）
```

开发某个服务时：**先把 hub clone 到服务仓库同级目录**，在服务仓库跑一次
[`scripts/link-hub`](scripts/README.md)（生成 skills 链接与多根工作区），
之后该仓库中的任何 agent（Claude Code / Copilot / …）都能：
读 hub 宪法与记忆卡 → 引用已合并契约 → 调用 hub skills（`/contract-change` 等）。

## 30 分钟上手：一个 spec 从提出到完成

```
在 hub（spec 侧，命令对照见 sop/README.md）:
  specify  → specs/NNN/spec.md（WHAT/WHY）           ── 人审
  clarify  → 回写澄清项
  plan     → plan.md（必含「涉及服务」「契约影响」）    ── 人审
  契约影响 → /contract-change（草案→破坏性检测→消费者确认→合并）
  analyze  → 跨文档一致性检查
  tasks    → tasks.md（按服务分组，[P] 并行，末尾固定"更新记忆"）
在各服务仓库（并行）:
  agent 读 ../grc-spec-hub/（宪法→记忆卡→契约→service-map）
  → 先写测试 → 实现 → PR（本地门禁）→ 人审
回到 hub:
  集成验证（integration-check）
  spec-retro 生成 retro.md + 更新 memory/now/            ── 人审
```

守门点（必须人审）：**spec / plan / 契约 / memory-now**。其余 AI 可自主。

## 标准作业流程（SOP）

六个阶段，每阶段有出口判据，达标才进入下一阶段。详细步骤见 [`sop/`](sop/README.md)。

```
阶段0 绑定项目 → 阶段1 奠基 → 阶段2 声明服务清单 → 阶段3 批量孵化 → 阶段4 功能循环(反复) → 阶段5 常态运营
  hub.config     宪法+000-platform  services.manifest    /onboard-services    每个feature一圈      周digest/季度归档
```

| 阶段 | 入口 | 核心产出 |
|------|------|----------|
| 0 [绑定项目](sop/phases/00-bind-project.md) | 手动（半天） | `hub.config.yaml`、git 基线、守门点保护 |
| 1 [奠基](sop/phases/01-foundation.md) | 第 0 周会议 | 宪法、`specs/000-platform`、横切规范、初始记忆 |
| 2 [声明服务清单](sop/phases/02-declare-services.md) | 手动（半天） | [`services.manifest.yaml`](architecture/services.manifest.yaml)（无环） |
| 3 [批量孵化](sop/phases/03-onboard-services.md) | `/onboard-services` | service-map、记忆卡、服务仓库 + link-hub |
| 4 [功能循环](sop/phases/04-feature-loop.md) | 每个 feature | spec/plan/tasks/实现/retro/记忆更新 |
| 5 [常态运营](sop/phases/05-operations.md) | 周/双周/季度节拍 | 记忆摘要、契约演进、归档压缩 |

## 目录导航

| 目录 | 层 | 作用 | 入口文件 |
|------|----|------|----------|
| [hub.config.yaml](hub.config.yaml) | — | ★ 本 hub 绑定的**唯一项目**锚点 | [hub.config.yaml](hub.config.yaml) |
| [manual/](manual/README.md) | — | ★ 使用说明书（三种接入场景，傻瓜式） | [manual/README.md](manual/README.md) |
| [AGENTS.md](AGENTS.md) | — | 任意 agent 的统一入口（开放约定） | [AGENTS.md](AGENTS.md) |
| [sop/](sop/README.md) | L2 | ★ 框架无关 SOP + 工件规范 | [sop/README.md](sop/README.md) · [artifacts.md](sop/artifacts.md) |
| [adapters/](adapters/README.md) | L3 | 框架适配器（spec-kit / claude / copilot） | [adapters/README.md](adapters/README.md) |
| [specs/](specs/README.md) | L1 | 全平台唯一 spec 看板 | [000-platform](specs/000-platform/spec.md) |
| [contracts/](contracts/README.md) | L1 | 跨服务契约中心 | [POLICY.md](contracts/POLICY.md) |
| [architecture/](architecture/README.md) | L1 | 服务地图 + 服务清单 + ADR + 横切规范 + 架构图 | [services.manifest.yaml](architecture/services.manifest.yaml) · [service-map.md](architecture/service-map.md) |
| [memory/](memory/PIPELINE.md) | L1 | ★ Project Memory（三态） | [PIPELINE.md](memory/PIPELINE.md) · [now/state.md](memory/now/state.md) |
| [standards/](standards/coding-general.md) | L1 | 工程标准 | [testing.md](standards/testing.md) · [review.md](standards/review.md) |
| [capabilities/](capabilities/README.md) | L1 | skills / prompts / mcp（能力资产唯一家） | [skills](capabilities/skills) · [prompts](capabilities/prompts) |
| [gates/](gates/README.md) | L1 | 门禁（本地脚本 + 人审） | [GATES.md](gates/GATES.md) |
| [scripts/](scripts/README.md) | — | link-hub 等接入脚本 | [scripts/README.md](scripts/README.md) |
| [templates/](templates/service-repo/README.md) | — | 服务仓库脚手架（pull 模型） | [service-repo](templates/service-repo) |
| [.specify/](.specify/README.md) | L3 落点 | Spec Kit 工具链 + **项目宪法** | [constitution.md](.specify/memory/constitution.md) |

## 六条不可协商原则（宪法摘要）

1. **Spec 先行** — 任何代码变更可追溯到一个 spec。
2. **契约先行** — 跨服务接口先在 `contracts/` 合并，代码只引用已合并契约。
3. **测试先行** — 先写测试，先红后绿，禁止恒真断言。
4. **服务边界** — 只经契约交互，依赖方向符合 service-map。
5. **记忆义务** — 每个 spec 收尾 task 固定为"更新 Project Memory"。
6. **人类守门点** — spec / plan / 契约 / memory-now 必须人审。

全文见 [`.specify/memory/constitution.md`](.specify/memory/constitution.md)。

## Project Memory（三态）

```
now/（当前态，agent 每次必读）──滚动降温──▶ digests/（周摘要）──季度压缩──▶ archive/（归档）
```

- **now 的价值来自它的小**：`state.md` ≤ 2 页，服务卡各 ≤ 1 页。
- 写入入口：① spec 收尾 task（主动） ② 每周 digest（被动兜底） ③ ADR 合并。
- 三条铁律：AI 永不直接写 now 主干（经 PR）；每条记忆带来源 PR 链接；
  自动区块与人工区块物理隔离。
- 详见 [`memory/PIPELINE.md`](memory/PIPELINE.md)。

## 门禁（无 CI 依赖）

门禁 = **本地检查脚本 + 人审 checklist**（[`gates/GATES.md`](gates/GATES.md)）：

| 场景 | 合并前必跑 |
|------|-----------|
| `contracts/**` 变更 | `./gates/scripts/check-contracts.{ps1,sh}`（语法 + oasdiff 破坏性检测 + 消费者确认流程） |
| `specs/**` 变更 | `./gates/scripts/check-plan.{ps1,sh}`（plan 两章校验）+ analyze |
| 服务仓库 PR | lint / 单测 / 契约一致性自查 / 人审（发起人不可自批） |

团队若有 CI，可自行把脚本包成流水线（可选增强，非前提）。

## 换一个 spec coding 框架要做什么

1. 在 `adapters/<framework>/` 写一个 README：落点文件 + SOP 动作命令映射；
2. 保证产出物满足 [`sop/artifacts.md`](sop/artifacts.md)（这是验收标准）；
3. 跑一圈 [阶段 4 功能循环](sop/phases/04-feature-loop.md) 冒烟。
事实层与 `sop/` **零改动**。

## 语言约定

文档默认中文；代码标识符、契约字段、文件路径保持英文。

> 启动前待办见 [`LAUNCH-CHECKLIST.md`](LAUNCH-CHECKLIST.md)。
