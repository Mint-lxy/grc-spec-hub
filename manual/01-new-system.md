# 手册一：全新系统（greenfield）

> 前提：已完成 [公共准备](README.md)。
> 全程对应 SOP 阶段 0→5（[sop/README.md](../sop/README.md)），本手册把每一步摊开讲。
> 时间感：阶段 0 半天 → 阶段 1 约 1–3 天 → 阶段 2 半天 → 阶段 3 约 1–2 天 → 之后进入循环。

---

## 阶段 0：把 hub 绑定到你的项目（半天）

**在 hub 目录里做：**

1. 打开 [hub.config.yaml](../hub.config.yaml)，把 `[待确认]` 全部填成真话：
   - `project.id`：小写连字符，如 `acme-shop`（定了就别改）
   - `project.name` / `org` / `description`
   - `hub.repo`：hub 自己的远程仓库地址
2. 提交并推送：
   ```powershell
   git add -A; git commit -m "chore: bind project"; git push -u origin main
   ```
3. 在远程托管（GitHub/GitLab）上给四个守门点开**合并必审**：
   `specs/**`、`contracts/**`、`memory/now/**`、`.specify/memory/constitution.md`。
   最简单做法：分支保护「必须 1 个 approve」+ CODEOWNERS 指到 tech lead。

**验收**：`hub.config.yaml` 无 `[待确认]`；守门点有人审保护。

---

## 阶段 1：奠基会（第 0 周最重要的 1–3 天，核心团队全员）

会议产出四样东西，都在 hub 里改、走 PR 人审：

1. **宪法**：编辑 [.specify/memory/constitution.md](../.specify/memory/constitution.md)。
   六条骨架已写好，逐条讨论：要么接受、要么改、要么删——但每条必须是"可判定违反与否"的硬规则。≤ 2 页。
2. **平台总体 spec**：填 [specs/000-platform/spec.md](../specs/000-platform/spec.md)
   （愿景一段话、里程碑表、服务划分依据）和 `plan.md`（运行时/消息中间件/认证等平台选型表）。
   可以让 agent 起草再人改：对 agent 说
   *"读 specs/000-platform/spec.md 的骨架，基于以下信息填写：<你的项目描述>"*。
3. **横切规范**：补齐 [architecture/cross-cutting/](../architecture/cross-cutting) 三件
   （auth / observability / error-codes）里的 `[待确认]`。
4. **初始记忆**：把 [memory/now/state.md](../memory/now/state.md) 改成一句真话，
   如"项目启动，M1 目标是 X，截止 Y"。

**验收**：宪法与 000-platform 的 `[待确认]` 清零，全部经人审合并。

---

## 阶段 2：声明服务清单（半天）

把拆解好的服务写进 [architecture/services.manifest.yaml](../architecture/services.manifest.yaml)：

```yaml
project: acme-shop            # 与 hub.config.yaml 的 project.id 一致
services:
  - name: svc-order
    repo: acme/svc-order
    owner: "@alice"
    domain: 订单
    provides: [contracts/openapi/svc-order.yaml]
    consumes: [contracts/events/payment.asyncapi.yaml]
    depends-on: [svc-payment]
    milestone: M1
  - name: svc-payment
    ...
```

自查两条：服务名唯一；`depends-on` 单向无环（A→B→A 不行，改事件解耦并写 ADR）。

**验收**：清单覆盖全部服务、无环，经人审合并。

---

## 阶段 3：批量孵化服务（1–2 天）

**在 hub 工作区对 agent 说：**

```
/onboard-services architecture/services.manifest.yaml 已评审，开始批量孵化
```

agent 会按 [skill](../capabilities/skills/onboard-services/SKILL.md) 依次做：
校验清单 → 生成 service-map + Mermaid 依赖图 → 批量建记忆卡 →（**停下等你人审合并这个 PR**）
→ 批量建服务仓库（克隆到 hub 同级目录、脚手架实例化、替换占位符）→ 逐个 link-hub。

你需要人工做的只有三件事：
1. 审那个 service-map + 记忆卡 PR；
2. 在远程托管上创建各服务的空仓库（agent 没有建远程仓库的权限时）；
3. 抽 1–2 个服务冒烟：用生成的 `<svc>.code-workspace` 打开，问 agent
   *"读一下项目宪法和本服务的记忆卡，告诉我本服务的职责"*——能答上来就通了。

**验收**：每个服务有仓库（同级目录）、记忆卡、link-hub 校验全过。

---

## 阶段 4：第一个 feature（跑通一圈，之后每个需求都这样走）

以"用户下单"为例，**在 hub 工作区**：

```
/speckit.specify 用户可以从购物车创建订单，库存不足时提示……
```
→ 生成 `specs/001-create-order/spec.md` → 提 PR → **人审合并**。

```
/speckit.clarify        # 追问边界，回写 spec
/speckit.plan           # 生成 plan.md（必含「涉及服务」「契约影响」两章）
```
→ plan 若有契约影响，先走 `/contract-change`（起草→门禁→消费者确认→合并）。
→ plan 提 PR 前跑门禁：`./gates/scripts/check-plan.ps1` → **人审合并**。

```
/speckit.analyze        # 跨文档一致性，清零 CRITICAL
/speckit.tasks          # 生成 tasks.md（按服务分组，末尾固定"更新 Project Memory"）
```

**切到各服务仓库**（可多人/多 agent 并行）：用 `<svc>.code-workspace` 打开，对 agent 说
*"执行 specs/001-create-order/tasks.md 中分配给本服务的任务"*。
agent 会按服务仓库 AGENTS.md：先 pull hub → 读宪法/记忆卡/契约 → 先写测试（红）→ 实现（绿）→ 提 PR。
**你人审每个 PR**（agent 不可自批）。

**回到 hub 收尾**：全部服务 PR 合并后——

```
执行 capabilities/prompts/integration-check.prompt.md 检查 001 的跨服务一致性
执行 capabilities/prompts/spec-retro.prompt.md 为 001 生成 retro 和记忆更新
```
→ retro.md + memory/now 更新作为一个 PR → **人审合并**。至此该 spec 才算完成。

---

## 阶段 5：常态节拍（从第 5 周起，全是人触发）

| 频率 | 做什么 | 怎么做 |
|------|--------|--------|
| 每周一 ~15 分钟 | 记忆摘要 | 在 hub 对 agent 说"执行 memory-digest prompt"，审它提的 PR |
| 每双周 | 检视 watchlist | 人工过一遍 [watchlist.md](../memory/now/watchlist.md) |
| 每季度 | 归档 + 宪法回顾 | 按 [memory/PIPELINE.md](../memory/PIPELINE.md) 降温规则 |

红线：state.md 超 14 天没更新、记忆 PR 积压超 5 天 → 当作事故处理（记忆腐化是最大风险）。
