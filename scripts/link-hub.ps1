# link-hub.ps1 — 在服务仓库根目录运行，把该仓库接到同级目录的 hub（pull 模型）。
# 用法: ../grc-spec-hub/scripts/link-hub.ps1 [-HubPath <path>]
# 幂等，可重复运行。行为需与 link-hub.sh 保持同步。

[CmdletBinding()]
param(
  [string]$HubPath = "../grc-spec-hub"
)

$ErrorActionPreference = "Stop"
$failed = $false

function Fail([string]$msg) {
  Write-Host "✗ $msg" -ForegroundColor Red
  $script:failed = $true
}
function Ok([string]$msg) { Write-Host "✓ $msg" -ForegroundColor Green }

# 0) 必须在服务仓库根目录运行
if (-not (Test-Path ".git")) {
  Write-Host "✗ 请在服务仓库根目录运行本脚本。" -ForegroundColor Red; exit 1
}

# 1) 校验 hub 可达
$hubFull = Resolve-Path -Path $HubPath -ErrorAction SilentlyContinue
if (-not $hubFull -or -not (Test-Path (Join-Path $hubFull "hub.config.yaml"))) {
  Write-Host "✗ 找不到 hub：'$HubPath' 不存在或缺少 hub.config.yaml。" -ForegroundColor Red
  Write-Host "  请把 hub 与本服务仓库克隆到同一父目录，例如：" -ForegroundColor Yellow
  Write-Host "    <root>/grc-spec-hub 与 <root>/$(Split-Path -Leaf (Get-Location))"
  exit 1
}
Ok "hub 可达: $hubFull"

# 2) .claude/skills -> <hub>/capabilities/skills（junction，幂等）
$skillsTarget = Join-Path $hubFull "capabilities/skills"
$linkPath = ".claude/skills"
New-Item -ItemType Directory -Path ".claude" -Force | Out-Null
if (Test-Path $linkPath) {
  $item = Get-Item $linkPath -Force
  if ($item.LinkType) { Remove-Item $linkPath -Force }
  else { Fail "$linkPath 已存在且不是链接——请人工处理（不要把 hub 内容复制进来）。" }
}
if (-not (Test-Path $linkPath)) {
  New-Item -ItemType Junction -Path $linkPath -Target $skillsTarget | Out-Null
  Ok ".claude/skills -> $skillsTarget"
}

# 确保 .claude/skills 被忽略（本地生成物，不入库）
$giLine = ".claude/skills"
if (-not (Test-Path ".gitignore") -or -not (Select-String -Path ".gitignore" -Pattern ([regex]::Escape($giLine)) -Quiet)) {
  Add-Content -Path ".gitignore" -Value $giLine
  Ok ".gitignore 已加入 $giLine"
}

# 3) 多根工作区文件（服务仓库 + hub），已存在则不覆盖
$svcName = Split-Path -Leaf (Get-Location)
$wsFile = "$svcName.code-workspace"
if (-not (Get-ChildItem -Filter "*.code-workspace" -File -ErrorAction SilentlyContinue)) {
  $hubRel = $HubPath -replace '\\', '/'
  @"
{
  "folders": [
    { "path": "." },
    { "path": "$hubRel" }
  ],
  "settings": {
    "chat.agentSkillsLocations": { "$hubRel/capabilities/skills": true }
  }
}
"@ | Set-Content -Path $wsFile -Encoding utf8
  Ok "已生成 $wsFile（多根工作区：服务仓库 + hub）"
} else {
  Ok "已存在 .code-workspace，跳过生成"
}

# 4) 校验 AGENTS.md
if (-not (Test-Path "AGENTS.md")) {
  Fail "缺少 AGENTS.md——请从 hub 的 templates/service-repo/ 实例化。"
} elseif (Select-String -Path "AGENTS.md" -Pattern '\{\{[A-Z_]+\}\}' -Quiet) {
  Fail "AGENTS.md 仍含 {{...}} 占位符——孵化未完成，请替换后重跑。"
} else {
  Ok "AGENTS.md 就绪"
}

if ($failed) { exit 1 }
Write-Host "`nlink-hub 完成：本仓库已接通 hub（pull 模型）。" -ForegroundColor Cyan
exit 0
