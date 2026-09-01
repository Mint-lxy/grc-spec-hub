# 启动前清单（LAUNCH CHECKLIST）

hub 的骨架与基础功能已就位。下面是"项目正式启动前，还需补齐/落实"的事项。
带 ⬜ 的是待办；已由初始化/重构完成的标 ✅。

---

## A. 结构与内容（已完成的骨架）

- ✅ 三层架构：事实层（specs / contracts / architecture / memory / standards /
  capabilities / gates）+ 流程层（`sop/`）+ 适配层（`adapters/`）
- ✅ 框架无关 SOP（六阶段 + 工件规范 `sop/artifacts.md`）
- ✅ 三个适配器：spec-kit / claude / copilot（含根 `AGENTS.md`、`CLAUDE.md` 中立入口）
- ✅ pull 模型：`scripts/link-hub.{ps1,sh}` + 服务脚手架 `templates/service-repo/`
  （AGENTS / CLAUDE / copilot-instructions 模板，`{{HUB_DIR}}` 相对路径直读 hub）
- ✅ 本地门禁脚本：`gates/scripts/check-contracts.{ps1,sh}`、`check-plan.{ps1,sh}`
- ✅ 项目宪法骨架（六条原则）、契约政策 + 三类契约样例、机器可读 service-map、
  三态记忆骨架 + `PIPELINE.md`、四个 prompts、五个 skills
- ✅ Spec Kit 已初始化（`.specify/` + `.github/prompts/speckit.*`）
- ✅ git 已初始化并有基线提交

## B. 版本控制与守门点（必须）

- ⬜ 创建远程仓库并推送（若团队协作）；设置默认分支 `main`。
- ⬜ 守门点必审落地：`specs/**`、`contracts/**`、`memory/now/**`、
  `.specify/memory/constitution.md`——远程托管用分支保护 + CODEOWNERS（最便宜的落地方式）；
  纯本地协作写入团队评审约定。
- ⬜ 服务仓库约定：coding agent 的 PR 必须人类 approve、发起人不可自批。

## C. 工具依赖（本地，一次性）

- ⬜ 门禁工具：Node.js（`npx @redocly/cli`、`npx @asyncapi/cli`）+
  `oasdiff`（`go install github.com/oasdiff/oasdiff@latest` 或二进制）。
- ⬜ Spec Kit：`specify check` 通过；`pwsh`（PowerShell 7+）可用（`--script ps` 需要）。
- ⬜ Claude Code 用户：运行 `specify init --here --ai claude` 生成 `.claude/commands/`，
  并跑 `scripts/link-hub` 生成 `.claude/skills` 链接（见 `adapters/claude/README.md`）。
- ⬜ 若曾重装 Spec Kit：核对 `plan-template.md` 定制两章仍在（`adapters/spec-kit/README.md`）。

## D. 首个真实内容（第 0 周奠基，SOP 阶段 0–1）

- ⬜ 填 [`hub.config.yaml`](hub.config.yaml)：`project.id/name/org` 与 `hub.repo`。
- ⬜ 全团队共写**真实宪法**（替换占位，≤ 2 页）。
- ⬜ 填写 `specs/000-platform/spec.md` 与 `plan.md`（里程碑、服务划分、平台选型）。
- ⬜ 用一句话初始化 `memory/now/state.md`。
- ⬜ 补 `architecture/cross-cutting/`（auth / observability / error-codes）的 `[待确认]`。

## E. 声明与批量孵化服务（SOP 阶段 2–3）

- ⬜ 把全部已拆解服务写进 [`architecture/services.manifest.yaml`](architecture/services.manifest.yaml)。
- ⬜ 用 `/onboard-services` 生成 service-map + 记忆卡（校验无环）→ 人审合并；
  删除 `_EXAMPLE-svc-order.md` 与 service-map 的 `svc-example` 样例。
- ⬜ 批量建服务仓库（与 hub **同级目录**），逐个跑 `scripts/link-hub` 并确认校验全过。

## F. 首服务闭环（第 1–2 周，SOP 阶段 4 冒烟）

- ⬜ 跑通第一个完整 spec 循环（specify → … → 实现 → retro → memory 更新）。
- ⬜ 验证服务仓库 agent 能沿 `../<hub>/` 读到宪法/记忆卡/契约并调用 hub skills。

## G. 多服务与记忆管线（第 3–4 周）

- ⬜ 跑第一个**跨服务** spec（验证契约先行 + 消费者确认 + 并行实现）。
- ⬜ 首次手动运行 memory-digest prompt，完成第一次周摘要人审。

## H. 常态节拍（第 5 周起，SOP 阶段 5）

- ⬜ 每周一记忆摘要审核（~15 分钟）。
- ⬜ 每双周检视 watchlist 与门禁豁免。
- ⬜ 每季度归档压缩与宪法回顾。

---

## 已知占位（搜索 `[待确认]` 逐一消除）

- 宪法修订记录、000-platform 里程碑与选型、cross-cutting 三件套、
  service-map 真实服务、GATES 覆盖率阈值、契约兼容窗口时长、MCP 登记。

> `[待确认]` 是本仓库刻意留下的"待决策"标记；正式启动前应清零或转为明确的 spec/issue。
