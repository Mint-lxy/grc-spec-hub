# AGENTS.md — GRC spec Hub（任意 coding agent 的入口）

本仓库是一个平台项目的**中枢仓库（hub）**：不放业务代码，只放事实源——
需求（specs/）、契约（contracts/）、架构（architecture/）、项目记忆（memory/）、
工程标准（standards/）、能力资产（capabilities/）、流程（sop/）与门禁（gates/）。
多个服务仓库的 coding agent 依赖本仓库的上下文并行工作。

## 开始任何任务前

1. 读项目宪法 [.specify/memory/constitution.md](.specify/memory/constitution.md)（不可协商原则，冲突时以它为准）。
2. 读当前态记忆 [memory/now/state.md](memory/now/state.md)。
3. 术语歧义查语义基线 [memory/now/glossary.md](memory/now/glossary.md)（业务术语镜像自 BA 工作区 `CONTEXT.md`——单一权威；冲突以 CONTEXT.md 原文为准并回同步镜像）。
4. 流程问题查 [sop/README.md](sop/README.md)；你所用框架的接入方式查 [adapters/](adapters/README.md)。

## 在本仓库工作的规则

1. **改 spec**（`specs/**`）→ 遵守 [sop/artifacts.md](sop/artifacts.md) 工件规范；
   plan 必须含「涉及服务」「契约影响」两章。
2. **改契约**（`contracts/**`）→ 先读 [contracts/POLICY.md](contracts/POLICY.md)；
   判定是否破坏性；破坏性变更必须列出 service-map 里的全部消费方并逐一确认。
3. **改记忆**（`memory/**`）→ 遵守 [memory/PIPELINE.md](memory/PIPELINE.md)：
   只写"自动区块"，永不触碰"人工区块"；每条事实附来源 PR 链接；
   不确定的信息标 `[待确认]`，不要编造。
4. **改架构**（`architecture/**`）→ 跨服务决策写 ADR；依赖变化同步 service-map.md。
5. **改流程**（`sop/**`）→ 保持框架无关；框架专属内容只能进 `adapters/`。
6. **保持 memory/now/ 精简**：state ≤ 2 页、服务卡 ≤ 1 页，超限降温到 digests/。
7. **术语基线**：`memory/now/glossary.md` 是本仓库的语义基线——写作与评审引用业务术语
   以其为准；它镜像 BA 工作区 `CONTEXT.md`（单一权威），术语变更先改 CONTEXT.md
   再同步本表，禁止在本表单独新增/修改业务术语。

## 守门点（必须人审，你不可自行合并）

`specs/**` · `contracts/**` · `memory/now/**` · 宪法。

**分支规则**：一律不在 `main` 上直接改动；所有工作在功能分支进行。
任何合并或推送到 `main` 的操作必须先向用户确认，得到明确同意后方可执行。

## 能力资产

- skills：[capabilities/skills/](capabilities/README.md)（Agent Skills 约定，`/名称` 调用）
- prompts：[capabilities/prompts/](capabilities/prompts)（读文件即可执行）

## 语言

文档默认中文；代码标识符、契约字段、文件路径保持英文。
提交信息用祈使句，关联对应 spec/issue。
