<#
.SYNOPSIS
    OpenClaw BG 卸载脚本 (PowerShell)
.DESCRIPTION
    移除 openclaw-bg 命令，可选择清理仓库。
#>

$ErrorActionPreference = "Continue"

function Write-Info    { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

$InstallDir = ""
$RepoDir = "$env:USERPROFILE\.openclaw-bg"

# 在 PATH 中搜索 openclaw-bg.cmd 来确定安装目录
foreach ($d in ($env:PATH -split ';')) {
    $d = $d.TrimEnd('\')
    if (Test-Path "$d\openclaw-bg.cmd") {
        $InstallDir = $d
        break
    }
}

Write-Host ""
Write-Info "OpenClaw BG 卸载脚本 (PowerShell)"
Write-Host ""

$removed = $false

if ($InstallDir -and (Test-Path "$InstallDir\openclaw-bg.cmd")) {
    Write-Host "移除: $InstallDir\openclaw-bg.cmd"
    Remove-Item "$InstallDir\openclaw-bg.cmd" -Force
    $removed = $true
}

if (-not $removed) {
    Write-Host "未找到已安装的 openclaw-bg"
}

# 停止运行中的 Gateway
$pidFile = "$env:USERPROFILE\.openclaw\gateway.pid"
if (Test-Path $pidFile) {
    $pid = Get-Content $pidFile -Raw
    if ($pid) {
        $pid = $pid.Trim()
        try {
            $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "停止运行中的 Gateway (PID: $pid)..."
                Stop-Process -Id $pid -Force
            }
        } catch { }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Success "卸载完成"

if (Test-Path $RepoDir) {
    Write-Host ""
    Write-Host "仓库目录仍保留: $RepoDir"
    Write-Host "如需彻底清理，请执行: Remove-Item -Recurse -Force `"$RepoDir`""
}
Write-Host ""
