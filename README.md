# OpenClaw BG

OpenClaw Gateway 后台管理工具，提供 `openclaw-bg` 命令一键启动/停止/查看 OpenClaw Gateway 服务，支持 Windows / macOS / Linux。

## 安装

一条命令即可安装，自动完成仓库下载、PATH 配置、命令注册。

**Windows PowerShell：**

```powershell
irm https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.ps1 | iex
```

**Git Bash / macOS / Linux：**

```bash
curl -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | bash
```

> Windows 安装完成后需要新开一个终端窗口，或重启终端使 PATH 生效。

## 使用

```bash
openclaw-bg start                # 后台启动 Gateway
openclaw-bg start --port 18888   # 指定端口启动
openclaw-bg start --verbose      # 传递参数给 Gateway
openclaw-bg stop                 # 停止 Gateway
openclaw-bg status               # 查看运行状态
openclaw-bg help                 # 查看帮助
openclaw-bg uninstall            # 卸载
```

启动成功后会自动显示 Dashboard 访问地址：

```
$ openclaw-bg start
正在后台启动 OpenClaw Gateway...
OpenClaw Gateway 已启动 (PID: 1618)
运行日志: C:\Users\WalNut\.openclaw-bg\logs\gateway.log

Dashboard: http://127.0.0.1:18789/
```

## 命令

| 命令 | 说明 |
|------|------|
| `start [参数...]` | 后台启动 Gateway，参数透传给 `openclaw gateway run` |
| `stop` | 停止 Gateway（SIGTERM → 10s 等待 → SIGKILL） |
| `status` | 查看 Gateway 运行状态和 PID |
| `help` | 显示帮助信息 |
| `uninstall` | 停止服务并清理安装文件 |

## 目录结构

| 路径 | 说明 |
|------|------|
| `~/.openclaw-bg/` | 项目仓库 |
| `~/.openclaw-bg/bin/openclaw-bg` | 核心脚本 |
| `~/.openclaw-bg/logs/gateway.log` | Gateway 运行日志 |
| `~/.openclaw-bg/logs/openclaw-bg.log` | 启停事件日志 |
| `~/.openclaw/gateway.pid` | Gateway 进程 PID |

## 依赖

- [OpenClaw](https://docs.openclaw.ai) CLI — `npm install -g openclaw`
- [Git Bash](https://git-scm.com)（Windows 必需；macOS / Linux 自带 bash）

## 许可证

MIT
