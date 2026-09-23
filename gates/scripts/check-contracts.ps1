# check-contracts.ps1 — 契约门禁（本地版）：语法校验 + 破坏性变更检测。
# 在 hub 根目录运行: ./gates/scripts/check-contracts.ps1 [-BaseRef main]
# 依赖（缺失则对应检查降级为警告）: npx redocly / npx @asyncapi/cli / oasdiff
# 行为需与 check-contracts.sh 保持同步。

[CmdletBinding()]
param(
  [string]$BaseRef = ""
)

$ErrorActionPreference = "Stop"
$failed = $false
if (-not (Test-Path "contracts")) { Write-Host "✗ 请在 hub 根目录运行。" -ForegroundColor Red; exit 1 }

# 未指定基准分支时自动探测（main → master）
if (-not $BaseRef) {
  git rev-parse --verify --quiet main *> $null
  $BaseRef = if ($LASTEXITCODE -eq 0) { "main" } else { "master" }
}

function Has-Cmd([string]$name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# 1) OpenAPI 语法校验
$openapi = Get-ChildItem contracts -Recurse -Include *.yaml, *.yml -File |
  Where-Object { $_.FullName -match '[\\/]openapi[\\/]' }
if ($openapi -and (Has-Cmd "npx")) {
  foreach ($f in $openapi) {
    npx --yes @redocly/cli lint $f.FullName --format=summary
    if ($LASTEXITCODE -ne 0) { $failed = $true }
  }
} elseif ($openapi) {
  Write-Host "⚠ 缺 npx/redocly，跳过 OpenAPI 语法校验" -ForegroundColor Yellow
}

# 2) AsyncAPI 语法校验
$asyncapi = Get-ChildItem contracts -Recurse -Include *.asyncapi.yaml, *.asyncapi.yml -File
if ($asyncapi -and (Has-Cmd "npx")) {
  foreach ($f in $asyncapi) {
    npx --yes @asyncapi/cli validate $f.FullName
    if ($LASTEXITCODE -ne 0) { $failed = $true }
  }
} elseif ($asyncapi) {
  Write-Host "⚠ 缺 npx/@asyncapi/cli，跳过 AsyncAPI 语法校验" -ForegroundColor Yellow
}

# 3) 破坏性变更检测（对比 BaseRef 上的旧版本）
if (Has-Cmd "oasdiff") {
  $changed = git diff --name-only "$BaseRef...HEAD" -- 'contracts/**' 2>$null |
    Where-Object { $_ -match 'openapi/.*\.ya?ml$' }
  foreach ($rel in $changed) {
    $old = New-TemporaryFile
    git show "${BaseRef}:$rel" 2>$null | Set-Content $old -Encoding UTF8
    if ((Get-Item $old).Length -gt 0) {
      $breaking = oasdiff breaking $old $rel
      if ($breaking | Where-Object { $_ -match '^(error|warning)\s' }) {
        Write-Host "✗ 破坏性变更: $rel" -ForegroundColor Red
        Write-Host $breaking
        Write-Host "  → 按 contracts/POLICY.md 处理：列出 service-map 中全部消费方并取得逐一确认。" -ForegroundColor Yellow
        $failed = $true
      }
    }
    Remove-Item $old -Force
  }
} else {
  Write-Host "⚠ 缺 oasdiff，跳过破坏性检测（安装: go install github.com/oasdiff/oasdiff@latest）" -ForegroundColor Yellow
}

if ($failed) { Write-Host "`n契约门禁：未通过。" -ForegroundColor Red; exit 1 }
Write-Host "`n契约门禁：通过（破坏性变更为零或已按 POLICY 处理）。" -ForegroundColor Green
exit 0
