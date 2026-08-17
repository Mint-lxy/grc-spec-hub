<#
.SYNOPSIS
将 .puml 渲染为同名 .svg（经 PlantUML server，本机无需 Java/GraphViz）。
渲染服务器缺省读 VS Code 用户 settings.json 的 plantuml.server，代理读 http.proxy。
.EXAMPLE
powershell -File export-svg.ps1 -Path architecture/diagrams/foo.puml
.EXAMPLE
powershell -File export-svg.ps1 -Path architecture/diagrams
.EXAMPLE
powershell -File export-svg.ps1 -Path foo.puml -Server http://localhost:8080
#>
[CmdletBinding()]
param(
    # .puml 文件、通配符或目录，可多个
    [Parameter(Mandatory, Position = 0)]
    [string[]]$Path,
    # 缺省取 settings.json 的 plantuml.server
    [string]$Server,
    # 缺省取 settings.json 的 http.proxy
    [string]$Proxy,
    # 缺省输出到源文件旁
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

function Get-VSCodeUserSetting([string]$Key) {
    # settings.json 可能含注释（JSONC），用正则取值避免解析失败
    foreach ($dir in @('Code', 'Code - Insiders')) {
        $file = Join-Path $env:APPDATA "$dir\User\settings.json"
        if (Test-Path $file) {
            $raw = Get-Content -Path $file -Raw
            if ($raw -match ('"' + [regex]::Escape($Key) + '"\s*:\s*"([^"]+)"')) { return $Matches[1] }
        }
    }
    return $null
}

if (-not $Server) { $Server = Get-VSCodeUserSetting 'plantuml.server' }
if (-not $Server) { throw 'no render server: pass -Server or set "plantuml.server" in VS Code settings.json' }
if (-not $Proxy)  { $Proxy  = Get-VSCodeUserSetting 'http.proxy' }
$proxyNote = if ($Proxy) { " (proxy: $Proxy)" } else { '' }
Write-Host "server: $Server$proxyNote"

function ConvertTo-PlantUmlEncoded([string]$Source) {
    # PlantUML URL 编码 = raw deflate + 自定义 base64 字母表
    $bytes = [Text.Encoding]::UTF8.GetBytes($Source)
    $ms = New-Object IO.MemoryStream
    $ds = New-Object IO.Compression.DeflateStream($ms, [IO.Compression.CompressionLevel]::Optimal, $true)
    $ds.Write($bytes, 0, $bytes.Length)
    $ds.Dispose()
    $std = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    $pu  = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'
    $b64 = [Convert]::ToBase64String($ms.ToArray()).TrimEnd('=')
    -join ($b64.ToCharArray() | ForEach-Object { $pu[$std.IndexOf($_)] })
}

$files = foreach ($p in $Path) {
    Get-ChildItem -Path $p -File -ErrorAction Stop | Where-Object Extension -eq '.puml'
}
$files = $files | Sort-Object FullName -Unique
if (-not $files) { throw "no .puml found: $Path" }

$failed = 0
foreach ($f in $files) {
    $svgPath = if ($OutDir) {
        New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
        Join-Path $OutDir ($f.BaseName + '.svg')
    } else {
        Join-Path $f.DirectoryName ($f.BaseName + '.svg')
    }
    try {
        $encoded = ConvertTo-PlantUmlEncoded (Get-Content -Path $f.FullName -Raw -Encoding UTF8)
        $req = @{ Uri = "$($Server.TrimEnd('/'))/svg/$encoded"; OutFile = $svgPath; UseBasicParsing = $true; TimeoutSec = 60 }
        if ($Proxy) { $req.Proxy = $Proxy }
        Invoke-WebRequest @req | Out-Null
        Write-Host "OK   $($f.Name) -> $svgPath"
    } catch {
        $failed++
        # HTTP 400 = puml 语法错误被 server 拒绝
        Write-Host "FAIL $($f.Name): $($_.Exception.Message)"
    }
}
if ($failed) { exit 1 }
