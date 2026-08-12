# gates/ — 门禁（本地脚本 + 人审）

- `GATES.md` — 门禁清单与阈值（唯一事实源）
- `scripts/` — 本地检查脚本（**跨平台：每个都有 `.ps1` 与 `.sh`**）
  - `check-contracts.{ps1,sh}` — 契约门禁：语法校验 + 破坏性检测（合并契约 PR 前必跑）
  - `check-plan.{ps1,sh}` — spec 门禁：plan 两章校验（合并 spec PR 前必跑）
  - 详见 [`scripts/README.md`](scripts/README.md)

> 本体系不依赖 CI：门禁由 agent/人在合并前本地运行，人审为最终裁决。
> 团队若有 CI，可自行把上述脚本包成流水线步骤（可选增强）。
