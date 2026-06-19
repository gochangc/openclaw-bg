# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

OpenClaw BG — OpenClaw Gateway 后台管理脚本，提供 `openclaw-bg {start|stop|status|uninstall}` 命令，支持 Windows/macOS/Linux。

## 架构

```
install.sh/install.ps1  →  生成 wrapper 脚本到 PATH  →  wrapper 调用 bin/openclaw-bg
```

- **`bin/openclaw-bg`** — 核心脚本，通过 `OPENCLAW_BG_HOME` 环境变量定位项目根目录
- **`install.sh`** — bash 安装器，支持远程检测（当脚本旁无 `bin/openclaw-bg` 时自动下载 tar.gz 解压）
- **`install.ps1`** — PowerShell 安装器，生成 `.cmd` wrapper 调用 Git Bash 执行核心脚本
- **`uninstall.sh` / `uninstall.ps1`** — 独立卸载脚本（传统方式）；`openclaw-bg uninstall` 是推荐方式

### 安装模式

```
远程模式（检测到脚本旁无 bin/openclaw-bg）:
  下载 tar.gz/zip 解压到 ~/.openclaw-bg → exec 本地 install.sh

本地模式:
  生成 wrapper 脚本 → 写入 PATH → 自动配置 shell RC/PowerShell PATH
```

### Wrapper 机制

- **Linux/macOS**: bash 脚本，export `OPENCLAW_BG_HOME`，exec 核心脚本
- **Windows**: `.cmd` 文件，set 环境变量后调用 Git Bash 执行核心脚本
- Wrapper 路径记录在 `$PROJECT_DIR/.wrapper-path`，供卸载时定位

### 进程管理

- 使用 `$HOME/.openclaw/gateway.pid` 记录 PID
- `start`: `nohup openclaw gateway run ... &`，写 PID
- `stop`: SIGTERM → 10s 等 → SIGKILL
- `is_running`: `kill -0 $pid` 检测

### 日志

所有日志在项目 `logs/` 目录下（`.gitignore` 已排除）：
- `gateway.log` — Gateway 运行输出
- `openclaw-bg.log` — 启停事件 + 时间戳
- `install.log` — 安装/卸载记录

## PATH 自动配置

- **install.sh**: 追加 `export PATH="..."` 到 `~/.bashrc` / `~/.zshrc` / `~/.profile`
- **install.ps1**: 调用 `[Environment]::SetEnvironmentVariable("PATH", ..., "User")`

## 平台差异

|  | Linux/macOS | Windows |
|---|---|---|
| 默认 bin 目录 | `~/.local/bin` | `~/bin` |
| Wrapper 扩展名 | 无 | `.cmd` |
| PATH 配置方式 | shell RC 文件 | `SetEnvironmentVariable` |
| 安装方式 | `curl\|bash` 或本地 `./install.sh` | `irm\|iex` 或本地 `.\install.ps1` |

## 测试

```bash
# bash 安装测试（远程模式检测：从非项目目录执行 install.sh）
cp install.sh /tmp/ && cd /tmp && bash install.sh

# PowerShell 测试（注意编码：必须用 UTF-8 下载）
# 关键：Invoke-WebRequest -OutFile 会损坏中文，必须用 Invoke-RestMethod + Set-Content -Encoding UTF8
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -RepoDir D:/test_repo

# 功能测试
openclaw-bg start
openclaw-bg status
openclaw-bg stop
openclaw-bg help
openclaw-bg uninstall
```

## 已知陷阱

- **PowerShell 编码**: `Invoke-WebRequest -OutFile` 保存时可能损坏 UTF-8 中文，导致解析错误。`irm` (Invoke-RestMethod) 直接返回字符串则无此问题
- **PowerShell 终端显示**: 中文乱码是终端字体问题，不影响实际功能
- **`param()` 与 `irm\|iex` 冲突**: `param()` 块只在脚本文件直接执行时有效，`irm\|iex` 会把 `[string]$Var = ""` 当作无效赋值表达式解析。应使用普通变量 `$Var = ""` 代替
- **`<#...#>` 块注释与 BOM**: `irm\|iex` 获取的内容在 BOM 字符后跟 `<#` 时，PowerShell 无法识别块注释开头，导致 `.SYNOPSIS` 等被当作命令执行。用 `#` 行注释代替
- **UTF-8 BOM 与 `irm\|iex`**: BOM 会导致脚本首字符被识别为 `?#` 而非 `#`，产生非致命但难看的第一行错误。`.ps1` 在 `irm\|iex` 为首要场景时**不应包含 BOM**
- **`exit` vs `return`**: `irm | iex` 远程执行时 `exit 1` 会直接杀死终端进程，`.ps1` 中必须用 `return`
- **here-string**: PowerShell 的 `@""@` here-string 与 `%*` 等特殊字符可能冲突，用 `@()` 数组 + `-join` 更安全
- **`write-error` 函数名**: 自定义函数 `Write-Error` 会覆盖内置 cmdlet，使用 `Write-Err` 代替
