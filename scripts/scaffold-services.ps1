# scaffold-services.ps1 — 批量为服务仓库生成脚手架文件（AGENTS.md / CLAUDE.md / copilot-instructions / instructions / docs）
# 在 hub 目录运行：.\scripts\scaffold-services.ps1
# 只处理尚未有 AGENTS.md 的仓库，已有脚手架的不会被覆盖。

$ErrorActionPreference = "Stop"
$hubDir = "grc-spec-hub"
$hubRepo = "grc-spec-hub"
$base = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # 上级目录（GRC/）

# 需要初始化的服务定义
$services = @(
  @{ name = "grc-agent-service";      build = "uv sync --dev"; test = "uv run pytest" }
  @{ name = "grc-evaluation-service"; build = "uv sync --dev"; test = "uv run pytest" }
  @{ name = "grc-knowledge-engine";   build = "uv sync --dev"; test = "uv run pytest" }
  @{ name = "grc-parser-engine";      build = "uv sync --dev"; test = "uv run pytest" }
  @{ name = "grc-mcp-server";         build = "uv sync --dev"; test = "uv run pytest" }
  @{ name = "grc-ai-portal";          build = "npm run build"; test = "npm test" }
  @{ name = "grc-python-sdk";         build = "uv sync --dev"; test = "uv run pytest" }
)

foreach ($svc in $services) {
  $svcPath = Join-Path $base $svc.name
  if (-not (Test-Path $svcPath)) {
    Write-Host "SKIP $($svc.name): directory not found" -ForegroundColor Yellow
    continue
  }
  if (Test-Path (Join-Path $svcPath "AGENTS.md")) {
    Write-Host "SKIP $($svc.name): AGENTS.md already exists" -ForegroundColor Yellow
    continue
  }

  $n = $svc.name
  $b = $svc.build
  $t = $svc.test

  Write-Host "Scaffolding $n ..." -ForegroundColor Cyan

  # --- AGENTS.md ---
  @"
# AGENTS.md — $n

> 面向任意 coding agent（Claude Code / Copilot / Cursor / …）的统一入口。
> 本服务属于平台项目 ``$hubRepo``，事实源在中枢仓库 hub。

## 上下文来源（pull 模型）

hub 与本仓库克隆在**同级目录**：``../$hubDir/``。
若不可达，先执行 ``git clone <hub-repo> ../$hubDir``，
再在本仓库根目录运行 ``../$hubDir/scripts/link-hub.ps1``（或 ``.sh``）。

**开始任何任务前，先拉新 hub，再按序读四份文件**：

0. ``git -C ../$hubDir pull --ff-only`` —— pull 模型没有自动同步，
   读过期上下文比没有上下文更危险。
1. ``../$hubDir/.specify/memory/constitution.md`` — 项目宪法（不可协商）
2. ``../$hubDir/memory/now/services/$n.md`` — 本服务记忆卡
   （可能写着"上周换了 X 库，别再用旧库"之类的关键近期变化）
3. ``../$hubDir/contracts/`` 中本服务 provides/consumes 的契约
   （清单见记忆卡与 service-map）
4. ``../$hubDir/architecture/service-map.md`` — 依赖方向与邻居

## 铁律

1. **契约先行**：跨服务交互只经 hub ``contracts/`` 中**已合并**的契约；
   不直连他人数据库、不隐式耦合。需要新接口 → 在 hub 走 ``/contract-change`` skill。
2. **测试先行**：实现前先写测试，先红后绿；禁止恒真断言
   （hub ``standards/testing.md``）。
3. **Spec 可追溯**：每个 PR 引用 hub 的 ``specs/NNN-<slug>``。
4. **不改 hub 事实源的守门内容**：``specs/** contracts/** memory/now/**`` 与宪法
   只能经 PR 人审变更。
5. **错误码必须注册**：新增接口错误必须在 hub ``architecture/cross-cutting/error-codes.md`` 注册编码（ADR-002）。
6. **AI API 调用经 SDK**：调用 LLM/Embedding/Rerank 等 AI API 统一经 ``grc-ai-sdk``，不直接调用 provider API（ADR-003）。

## 构建与测试

- 构建：``$b``
- 测试：``$t``

## 门禁（合并前必须全绿）

lint · 单测 · 契约一致性（provider/consumer）· 密钥扫描 · 依赖许可证
（清单与阈值见 hub ``gates/GATES.md``）。coding agent 的 PR 必须由人类 approve，发起人不可自批。

## 服务内部技术文档

hub 的 spec 覆盖需求与跨服务方案，服务内部技术设计在本仓库维护：

| 目录 | 写什么 |
|------|--------|
| ``docs/design/`` | 数据模型、内部模块划分、关键算法、性能方案 |
| ``docs/adr/`` | 服务内部架构决策（ORM 选型、缓存策略、框架选型等） |

跨服务决策放 hub ``architecture/adr/``，服务内部决策放本仓库 ``docs/adr/``。

## 路径级指令

见 ``.github/instructions/``（tests / api / db 各有专门约定）。
"@ | Set-Content -Path (Join-Path $svcPath "AGENTS.md") -Encoding utf8

  # --- CLAUDE.md ---
  @"
# CLAUDE.md — $n

@AGENTS.md

hub skills 通过 ``.claude/skills`` 链接可用（由 ``../$hubDir/scripts/link-hub`` 生成）。
"@ | Set-Content -Path (Join-Path $svcPath "CLAUDE.md") -Encoding utf8

  # --- .github/copilot-instructions.md ---
  $ghDir = Join-Path $svcPath ".github"
  New-Item -ItemType Directory -Path $ghDir -Force | Out-Null
  @"
# $n — Copilot 指令

> 由 hub ``templates/service-repo/`` 实例化。
> 通用规则见根 ``AGENTS.md``（本文件只补充 Copilot/VS Code 特定事项，内容不重复）。

## 必读

开始任何任务前，先按根 ``AGENTS.md`` 的顺序读 hub（``../$hubDir/``）的
宪法、本服务记忆卡、相关契约与 service-map。hub 不可达时停下来提示用户运行
``../$hubDir/scripts/link-hub.ps1``。

## VS Code 工作区

用仓库根的 ``*.code-workspace`` 打开（多根：本仓库 + hub），hub 的 skills
（``/contract-change``、``/cross-service-debug`` 等）即可直接调用。

## 提交与 PR

- 祈使句提交，引用 hub 的 ``specs/NNN-<slug>``。
- 你（coding agent）的 PR 必须由**人类** approve，发起人不可自批。

## 服务内部设计文档

hub spec 覆盖需求与跨服务方案，服务内部技术设计在 ``docs/design/`` 维护，
服务内部架构决策在 ``docs/adr/`` 记录。跨服务决策放 hub ``architecture/adr/``。
"@ | Set-Content -Path (Join-Path $ghDir "copilot-instructions.md") -Encoding utf8

  # --- .github/instructions/ ---
  $instrDir = Join-Path $ghDir "instructions"
  New-Item -ItemType Directory -Path $instrDir -Force | Out-Null

  @"
---
applyTo: "**/api/**,**/controllers/**,**/handlers/**,**/routers/**"
---
# API 路径级指令

- 对外接口必须与 hub（``../$hubDir/contracts/``）中本服务**已合并**的契约一致；
  不得引入契约未声明的字段/端点/事件。
- 错误响应遵循 RFC 9457 统一错误体与服务前缀错误码（见 hub ``architecture/cross-cutting/error-codes.md``，ADR-002）。
- 新增接口错误码必须在 hub ``error-codes.md`` 注册后再使用。
- AI API 调用（LLM/Embedding/Rerank）统一经 ``grc-ai-sdk``，不直接调用 provider API（ADR-003）。
- 需要新增或修改跨服务接口 → 回 hub 走 ``contract-change``，不要在此私自扩展。
"@ | Set-Content -Path (Join-Path $instrDir "api.instructions.md") -Encoding utf8

  @"
---
applyTo: "**/db/**,**/migrations/**,**/repositories/**,**/models/**"
---
# 数据层路径级指令

- 只访问本服务自己的数据；**禁止直连其他服务的数据库**（宪法第四条）。
- schema 变更需可迁移、可回滚；破坏性迁移需在 PR 说明与回滚方案。
- 不在数据层泄露 PII 到日志。
"@ | Set-Content -Path (Join-Path $instrDir "db.instructions.md") -Encoding utf8

  @"
---
applyTo: "**/tests/**,**/*.test.*,**/*.spec.*,**/test_*"
---
# 测试路径级指令

- 遵循 hub ``standards/testing.md``：禁止恒真断言，先红后绿，断言行为非实现。
- 契约相关行为必须有 provider/consumer 契约测试。
- 覆盖 happy path 与错误/边界/并发/幂等重放路径。
"@ | Set-Content -Path (Join-Path $instrDir "tests.instructions.md") -Encoding utf8

  # --- docs/design/ & docs/adr/ ---
  New-Item -ItemType Directory -Path (Join-Path $svcPath "docs/design") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $svcPath "docs/adr") -Force | Out-Null
  Set-Content -Path (Join-Path $svcPath "docs/design/.gitkeep") -Value "" -Encoding utf8
  Set-Content -Path (Join-Path $svcPath "docs/adr/.gitkeep") -Value "" -Encoding utf8

  Write-Host "  OK: $n scaffolded" -ForegroundColor Green
}

Write-Host "`nScaffolding complete." -ForegroundColor Cyan
