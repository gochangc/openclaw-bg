<#
.SYNOPSIS
    OpenClaw BG 安装脚本 (PowerShell)
.DESCRIPTION
    一键安装 openclaw-bg，自动下载仓库、配置 PATH。
.EXAMPLE
    irm https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.ps1 | iex
#>

param(
    [string]$InstallDir = "",
    [string]$RepoDir = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Info    { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warn    { Write-Host $args -ForegroundColor Yellow }
function Write-Err     { Write-Host $args -ForegroundColor Red }

Write-Host ""
Write-Info "OpenClaw BG 安装脚本 (PowerShell)"
Write-Host ""

# ---- [1/4] 环境检测 ----
Write-Info "[1/4] 环境检测"

$openclawPath = Get-Command openclaw -ErrorAction SilentlyContinue
if ($openclawPath) {
    $ver = & openclaw --version 2>&1 | Select-Object -First 1
    Write-Success "  openclaw: 已安装 ($ver)"
} else {
    Write-Err "  openclaw: 未安装"
    Write-Host ""
    Write-Err "错误: 未检测到 openclaw"
    Write-Host "  npm install -g openclaw"
    Write-Host "  https://docs.openclaw.ai"
    return
}

$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($gitPath) {
    Write-Success "  git: 已安装"
} else {
    Write-Err "  git: 未安装"
    Write-Err "请先安装: https://git-scm.com"
    return
}

# 查找 bash
$bashExe = $null
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd -and $bashCmd.Source -notlike "*WindowsApps*") {
    $bashExe = $bashCmd.Source
} else {
    $gitBashDirs = @(
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\usr\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
    )
    foreach ($p in $gitBashDirs) {
        if (Test-Path $p) { $bashExe = $p; break }
    }
}
if (-not $bashExe) {
    Write-Err "  bash: 未找到 Git Bash，请先安装: https://git-scm.com"
    return
}
Write-Success "  bash: $bashExe"

Write-Host ""

# ---- [2/4] 准备目录 ----
Write-Info "[2/4] 准备目录"

if (-not $RepoDir) { $RepoDir = "$env:USERPROFILE\.openclaw-bg" }
if (-not $InstallDir) {
    $candidates = @(
        "$env:USERPROFILE\bin",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps",
        "$env:APPDATA\npm"
    )
    $InstallDir = $null
    foreach ($d in $candidates) {
        $paths = $env:PATH -split ';' | ForEach-Object { $_.TrimEnd('\') }
        if ($paths -contains $d.TrimEnd('\')) {
            $InstallDir = $d
            break
        }
    }
    if (-not $InstallDir) {
        $InstallDir = "$env:USERPROFILE\bin"
    }
}

Write-Host "  仓库: $RepoDir"
Write-Host "  安装: $InstallDir"
Write-Host ""

# ---- [3/4] 下载仓库 ----
Write-Info "[3/4] 下载仓库"

if (Test-Path "$RepoDir\.git") {
    Write-Host "  仓库已存在，正在更新..."
    Push-Location $RepoDir
    try {
        git pull --ff-only origin master 2>&1 | Out-Null
        Write-Success "  更新完成"
    } catch {
        Write-Warn "  (跳过更新)"
    }
    Pop-Location
} else {
    if (Test-Path $RepoDir) {
        Remove-Item -Recurse -Force $RepoDir
    }
    Write-Host "  正在 clone..."
    git clone --depth 1 https://github.com/gochangc/openclaw-bg.git $RepoDir 2>&1 | Out-Null
    Write-Success "  clone 完成"
}

Write-Host ""

# ---- [4/4] 安装命令 + PATH ----
Write-Info "[4/4] 安装命令 + PATH 配置"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 存储 wrapper 路径供卸载使用
"$InstallDir\openclaw-bg.cmd" | Set-Content -Path "$RepoDir\.wrapper-path" -Encoding ASCII

# 创建 .cmd wrapper
$wrapperPath = "$InstallDir\openclaw-bg.cmd"
$lines = @(
    '@echo off',
    "set OPENCLAW_BG_HOME=$RepoDir",
    "`"$bashExe`" `"%OPENCLAW_BG_HOME%\bin\openclaw-bg`" %*"
)
$lines -join "`r`n" | Set-Content -Path $wrapperPath -Encoding ASCII

Write-Success "  + openclaw-bg -> $wrapperPath"

# 自动配置用户 PATH
$paths = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($paths -notlike "*$InstallDir*") {
    $newPath = "$InstallDir;$paths"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    # 更新当前会话
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Success "  + PATH 已自动配置 ($InstallDir)"
} else {
    Write-Success "  + PATH 已包含此目录，无需配置"
}

Write-Host ""
Write-Info "=============================="
Write-Info "  OpenClaw BG 安装完成！"
Write-Info "=============================="
Write-Host ""
Write-Host "  后台启动:  openclaw-bg start"
Write-Host "  停止服务:  openclaw-bg stop"
Write-Host "  查看状态:  openclaw-bg status"
Write-Host "  卸载:      openclaw-bg uninstall"
Write-Host ""
Write-Host "  (新终端窗口生效，或重启终端)"
Write-Host ""
