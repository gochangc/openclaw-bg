<#
.SYNOPSIS
    OpenClaw BG 安装脚本 (PowerShell)
.DESCRIPTION
    一键安装 openclaw-bg，自动下载仓库并配置到 PATH。
    支持 Windows PowerShell 5.1+ 和 PowerShell Core 7+。
.PARAMETER InstallDir
    命令安装目录，默认自动检测 PATH 中第一个可写目录
.PARAMETER RepoDir
    仓库 clone 目录，默认 ~/.openclaw-bg
.EXAMPLE
    # 本地安装
    .\install.ps1

    # 远程安装（一条命令）
    irm https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.ps1 | iex
#>

param(
    [string]$InstallDir = "",
    [string]$RepoDir = ""
)

$ErrorActionPreference = "Stop"

# ---- 颜色函数 ----
function Write-Info    { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error   { Write-Host $args -ForegroundColor Red }

# ---- 标题 ----
Write-Host ""
Write-Info "OpenClaw BG 安装脚本 (PowerShell)"
Write-Host ""

# ---- 检测 openclaw ----
Write-Info "[1/5] 环境检测"

$openclawPath = Get-Command openclaw -ErrorAction SilentlyContinue
if ($openclawPath) {
    $version = & openclaw --version 2>&1 | Select-Object -First 1
    Write-Success "  openclaw: 已安装 ($version)"
} else {
    Write-Error "  openclaw: 未安装"
    Write-Host ""
    Write-Error "错误: 未检测到 openclaw，请先安装"
    Write-Host "  npm install -g openclaw"
    Write-Host "  或访问: https://docs.openclaw.ai"
    exit 1
}

Write-Host "  当前系统: Windows"
Write-Host ""

# ---- 依赖检查 ----
Write-Info "[2/5] 依赖检查"

$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($gitPath) {
    Write-Success "  git: 已安装"
} else {
    Write-Error "  git: 未安装"
    Write-Error "错误: 需要 git 来下载仓库，请先安装: https://git-scm.com"
    exit 1
}

# 检查 bash (Git Bash)
$bashPath = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashPath -or $bashPath.Source -like "*WindowsApps*") {
    # WSL 存根不可用，尝试找 Git Bash
    $gitBashPaths = @(
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\usr\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
    )
    $found = $false
    foreach ($p in $gitBashPaths) {
        if (Test-Path $p) {
            $env:BASH_EXE = $p
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Error "  bash: 未找到 Git Bash，请先安装: https://git-scm.com"
        exit 1
    }
    Write-Success "  bash: $env:BASH_EXE"
} else {
    $env:BASH_EXE = $bashPath.Source
    Write-Success "  bash: $env:BASH_EXE"
}

Write-Host ""

# ---- 确定目录 ----
if (-not $RepoDir) { $RepoDir = "$env:USERPROFILE\.openclaw-bg" }
if (-not $InstallDir) {
    # 自动找 PATH 中第一个可写的用户目录
    $candidates = @(
        "$env:USERPROFILE\bin",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps",
        "$env:APPDATA\npm"
    )
    foreach ($d in $candidates) {
        if (($env:PATH -split ';' | ForEach-Object { $_.TrimEnd('\') }) -contains $d.TrimEnd('\')) {
            $InstallDir = $d
            break
        }
    }
    if (-not $InstallDir) {
        $InstallDir = "$env:USERPROFILE\bin"
        Write-Warning "  未找到合适的 PATH 目录，将使用: $InstallDir"
        Write-Warning "  安装后请手动将此目录加入 PATH"
    }
}

Write-Info "[3/5] 准备目录"
Write-Host "  仓库目录: $RepoDir"
Write-Host "  安装目录: $InstallDir"
Write-Host ""

# ---- 下载仓库 ----
Write-Info "[4/5] 下载仓库"

if (Test-Path "$RepoDir\.git") {
    Write-Host "  仓库已存在，正在更新..."
    Push-Location $RepoDir
    try {
        git pull --ff-only origin master 2>&1 | Out-Null
        Write-Success "  更新完成"
    } catch {
        Write-Warning "  (跳过更新, 使用已有版本)"
    }
    Pop-Location
} else {
    if (Test-Path $RepoDir) {
        Write-Host "  清理旧目录..."
        Remove-Item -Recurse -Force $RepoDir
    }
    Write-Host "  正在 clone..."
    git clone --depth 1 https://github.com/gochangc/openclaw-bg.git $RepoDir 2>&1 | Out-Null
    Write-Success "  clone 完成"
}

Write-Host ""

# ---- 创建 wrapper ----
Write-Info "[5/5] 安装命令"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Host "  创建目录: $InstallDir"
}

# 创建 openclaw-bg.cmd wrapper（兼容 CMD 和 PowerShell）
$wrapperPath = "$InstallDir\openclaw-bg.cmd"
$bashExe = $env:BASH_EXE -replace '\\', '\\'
@"
@echo off
set OPENCLAW_BG_HOME=$RepoDir
"$bashExe" "%OPENCLAW_BG_HOME%\bin\openclaw-bg" %*
"@ | Set-Content -Path $wrapperPath -Encoding ASCII

Write-Success "  + $wrapperPath"

# ---- PATH 检查 ----
$installDirNorm = $InstallDir.TrimEnd('\')
$inPath = ($env:PATH -split ';' | ForEach-Object { $_.TrimEnd('\') }) -contains $installDirNorm

Write-Host ""
if ($inPath) {
    Write-Success "  + 目录已在 PATH 中"
} else {
    Write-Warning "  ! 请将以下目录加入 PATH 环境变量:"
    Write-Host "    $InstallDir"
    Write-Host ""
    Write-Host "    [System.Environment]::SetEnvironmentVariable('PATH',"
    Write-Host "      [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';$InstallDir',"
    Write-Host "      'User')"
}

Write-Host ""
Write-Info "========================================"
Write-Info "  OpenClaw BG 安装完成！"
Write-Info "========================================"
Write-Host ""
Write-Host "  后台启动:  openclaw-bg start"
Write-Host "  停止服务:  openclaw-bg stop"
Write-Host "  查看状态:  openclaw-bg status"
Write-Host "  查看帮助:  openclaw-bg help"
Write-Host ""
Write-Host "  仓库目录:  $RepoDir"
Write-Host "  运行日志:  $RepoDir\logs\gateway.log"
Write-Host ""
Write-Host "  卸载方式:  cd $RepoDir; .\uninstall.ps1"
Write-Host ""
