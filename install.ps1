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

# 查找 bash (Git Bash)
$bashExe = $null

# 方式1: 直接在 PATH 中找（排除 WSL 存根）
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd -and $bashCmd.Source -notlike "*WindowsApps*") {
    $bashExe = $bashCmd.Source
}

# 方式2: 从 git 的安装位置推导 bash 路径（逐层向上搜索）
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $bashExe -and $gitPath) {
    $dir = Split-Path -Parent $gitPath.Source
    for ($i = 0; $i -lt 4; $i++) {
        $candidate = Join-Path $dir "usr\bin\bash.exe"
        if (Test-Path $candidate) { $bashExe = $candidate; break }
        $dir = Split-Path -Parent $dir
    }
}

# 方式3: 遍历常见安装目录（多盘符）
if (-not $bashExe) {
    $searchPaths = @()
    foreach ($drive in @('C:', 'D:', 'E:')) {
        $searchPaths += "$drive\Program Files\Git\usr\bin\bash.exe"
        $searchPaths += "$drive\Program Files (x86)\Git\usr\bin\bash.exe"
    }
    $searchPaths += "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
    foreach ($p in $searchPaths) {
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
    $InstallDir = "$env:USERPROFILE\bin"
}

Write-Host "  仓库: $RepoDir"
Write-Host "  安装: $InstallDir"
Write-Host ""

# ---- [3/4] 下载仓库 ----
Write-Info "[3/4] 下载仓库"
Write-Host "  正在下载..."

$ArchiveUrl = "https://github.com/gochangc/openclaw-bg/archive/refs/heads/master.zip"
$tmpZip = "$env:TEMP\openclaw-bg-$([System.IO.Path]::GetRandomFileName()).zip"
$tmpDir = "$env:TEMP\openclaw-bg-$([System.IO.Path]::GetRandomFileName())"
$downloadOk = $false

try {
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $tmpZip
    Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force
    $innerDir = Get-ChildItem -Directory $tmpDir | Select-Object -First 1
    # 移除旧仓库，安装新文件
    if (Test-Path $RepoDir) {
        Remove-Item -Recurse -Force $RepoDir -ErrorAction SilentlyContinue
    }
    Move-Item -Path "$($innerDir.FullName)" -Destination $RepoDir -Force
    $downloadOk = $true
} catch {
    Write-Err "  下载失败: $_"
} finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    Remove-Item -Force $tmpZip -ErrorAction SilentlyContinue
}

# 验证下载结果
if (-not $downloadOk -or -not (Test-Path "$RepoDir\bin\openclaw-bg")) {
    Write-Err "  仓库下载不完整，请检查网络后重试"
    return
}
Write-Success "  下载完成"

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
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$InstallDir*") {
    $newPath = "$InstallDir;$userPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
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
