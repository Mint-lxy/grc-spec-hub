# 门禁清单（GATES）

门禁即政策。本体系**不依赖任何 CI/SaaS**：门禁 = 本地检查脚本（agent 或人合并前运行）
+ 人审 checklist。有条件的团队可自行把这些脚本包进任意 CI，但那是可选增强，不是前提。

## 契约门禁（hub，`contracts/**` 变更时）

执行：`./gates/scripts/check-contracts.{ps1,sh}`（在 hub 根目录，合并前必跑）
- openapi/asyncapi 语法校验（redocly / asyncapi CLI）
- 破坏性变更检测（oasdiff，对比 main）
- **破坏性变更的人工流程**（脚本会提示，人审强制执行）：
  1. 从 `architecture/service-map.md` 的 `consumes:` 列出全部消费方；
  2. 在 PR 描述中逐一 @ 消费方 owner，收集 `confirmed-by:<svc>` 确认回复；
  3. 集齐全部确认后方可合并（这一步本身就是接口变更通知）。

## Spec 门禁（hub，`specs/**` 变更时）

执行：`./gates/scripts/check-plan.{ps1,sh}`（合并前必跑）
- plan.md 必须包含「涉及服务」「契约影响」两章（见 [`sop/artifacts.md`](../sop/artifacts.md)）
- 合并前跑一次一致性检查（analyze，命令对照见 [`sop/README.md`](../sop/README.md)），清零 CRITICAL

## 服务仓库门禁（合并前本地必跑）

- 常规：lint / 单测 / 密钥扫描 / 依赖许可证（用服务自身工具链）
- **契约一致性**：对外接口与 hub `contracts/` 中已合并契约逐字段核对
  （provider 侧验证自己实现的契约，consumer 侧验证自己消费的契约）——
  agent 在 PR 前自查，评审人抽查
- coding agent 的 PR 必须由人类 approve，发起人不可自批
- PR 必须引用 hub 的 `specs/NNN-<slug>`（无关联需说明）

## 记忆门禁（hub，人工节拍）

- `memory/now/state.md` 超过 14 天未更新 → 周会提醒
- 记忆 PR 超过 5 个工作日未处理 → 升级提醒（记忆腐化是最大单点风险）
- `now/` 超限（state > 2 页、服务卡 > 1 页）→ 立即降温

## 覆盖率阈值（供服务门禁引用）

- 关键路径（钱 / 状态机 / 鉴权）分支覆盖 ≥ `[待确认: 如 80%]`
- 全局行覆盖建议 ≥ `[待确认: 如 70%]`（辅助信号，非硬门禁）

## 工具依赖（本地安装一次）

`npx @redocly/cli` · `npx @asyncapi/cli` · `oasdiff`（Go 安装或二进制）。
缺失时脚本降级为警告，但**破坏性检测缺席的契约 PR 必须人工双倍谨慎**。
