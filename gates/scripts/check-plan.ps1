# check-plan.ps1 — spec 门禁（本地版）：校验 plan.md 含「涉及服务」「契约影响」两章。
# 在 hub 根目录运行: ./gates/scripts/check-plan.ps1 [-SpecDir specs/013-order-query]
# 不带参数时检查所有 specs/*/plan.md。行为需与 check-plan.sh 保持同步。

[CmdletBinding()]
param(
  [string]$SpecDir
)

$ErrorActionPreference = "Stop"
$failed = $false

$plans = if ($SpecDir) { Get-ChildItem (Join-Path $SpecDir "plan.md") -ErrorAction Stop }
         else { Get-ChildItem specs -Recurse -Filter plan.md -File }

foreach ($p in $plans) {
  $text = Get-Content $p.FullName -Raw -Encoding UTF8
  foreach ($section in @("涉及服务", "契约影响")) {
    if ($text -notmatch "(?m)^#{1,3}\s*.*$section") {
      Write-Host "✗ $($p.FullName) 缺少「$section」章节" -ForegroundColor Red
      $failed = $true
    }
  }
  if ($text -match '\[待确认\]') {
    Write-Host "⚠ $($p.FullName) 仍含 [待确认]，进入实现前需清零" -ForegroundColor Yellow
  }
}

if ($failed) { Write-Host "`nspec 门禁：未通过（plan 模板两章缺失）。" -ForegroundColor Red; exit 1 }
Write-Host "`nspec 门禁：通过。" -ForegroundColor Green
exit 0
