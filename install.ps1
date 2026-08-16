#Requires -Version 5.1
<#
.SYNOPSIS
    把 Claude Code 四角色 Agents 工作流装到一个项目,或装到全机器。

.EXAMPLE
    .\install.ps1 -Target "H:\我的项目"
    .\install.ps1 -Global
    .\install.ps1 -Target "H:\我的项目" -Force
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    # 装到 ~/.claude,对本机所有项目生效
    [switch]$Global,

    # 允许覆盖已存在的 CLAUDE.md(默认不覆盖,写成旁边的 .agents-workflow.md)
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Ok($msg)   { Write-Host "  OK   $msg" -ForegroundColor Green }
function Skip($msg) { Write-Host "  SKIP $msg" -ForegroundColor Yellow }

if (-not $Global -and [string]::IsNullOrWhiteSpace($Target)) {
    Write-Host ""
    Write-Host "用法:" -ForegroundColor Cyan
    Write-Host "  .\install.ps1 -Target <项目根目录>   装到一个项目"
    Write-Host "  .\install.ps1 -Global                装到 ~/.claude(全机器生效)"
    Write-Host "  加 -Force 允许覆盖已存在的 CLAUDE.md"
    Write-Host ""
    exit 1
}

if ($Global) {
    $claudeDir = Join-Path $env:USERPROFILE '.claude'
    $agentsDir = Join-Path $claudeDir 'agents'
    $mdPath    = Join-Path $claudeDir 'CLAUDE.md'
    $scopeDesc = "全机器 ($claudeDir)"
} else {
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        Fail "目标目录不存在: $Target"
    }
    $Target    = (Resolve-Path -LiteralPath $Target).Path
    if ($Target -eq $src) { Fail "目标目录就是本仓库,换一个真实的项目目录" }
    $agentsDir = Join-Path $Target '.claude\agents'
    $mdPath    = Join-Path $Target 'CLAUDE.md'
    $scopeDesc = "项目 ($Target)"
}

Write-Host ""
Write-Host "安装范围: $scopeDesc" -ForegroundColor Cyan
Write-Host ""

# --- agents ---
if (-not (Test-Path -LiteralPath $agentsDir)) {
    New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
}

$agentFiles = Get-ChildItem -LiteralPath (Join-Path $src 'agents') -Filter '*.md' -File
if ($agentFiles.Count -eq 0) { Fail "本仓库的 agents\ 目录里没有 .md 文件" }

foreach ($f in $agentFiles) {
    $dst = Join-Path $agentsDir $f.Name
    Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
    Ok ".claude\agents\$($f.Name)"
}

# --- CLAUDE.md ---
$srcMd = Join-Path $src 'CLAUDE.md'
if (-not (Test-Path -LiteralPath $srcMd)) { Fail "本仓库缺少 CLAUDE.md" }

if ((Test-Path -LiteralPath $mdPath) -and -not $Force) {
    $sideCar = Join-Path (Split-Path $mdPath -Parent) 'CLAUDE.agents-workflow.md'
    Copy-Item -LiteralPath $srcMd -Destination $sideCar -Force
    Skip "CLAUDE.md 已存在,没有覆盖"
    Write-Host "       新内容写到了: $sideCar" -ForegroundColor Yellow
    Write-Host "       请自己合并,或重跑加 -Force 覆盖" -ForegroundColor Yellow
} else {
    Copy-Item -LiteralPath $srcMd -Destination $mdPath -Force
    Ok (Split-Path $mdPath -Leaf)
}

Write-Host ""
Write-Host "装完了。还差两步:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. 重开编辑器窗口 —— .claude/agents/ 只在启动时扫一次,不重开等于没装" -ForegroundColor White
Write-Host "  2. 新会话里问一句「现在有哪些 subagent 可用?」" -ForegroundColor White
Write-Host "     看到 auditor / implementer / scout 三个才算真的生效" -ForegroundColor White
Write-Host ""
Write-Host "  可选:打开 .claude/agents/auditor.md,把本项目「长得像 BUG 其实是刻意设计」" -ForegroundColor DarkGray
Write-Host "        的地方填进底部的 PROJECT-SPECIFIC TRAPS 注释里。" -ForegroundColor DarkGray
Write-Host ""
