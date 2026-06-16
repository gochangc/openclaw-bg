# OpenClaw BG

openclaw 后台启动脚本

## 安装

一条命令即可安装，支持 Windows / macOS / Linux。

**Git Bash / Linux / macOS：**

```bash
curl -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | bash
```

**Windows PowerShell：**

```powershell
irm https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.ps1 | iex
```

> 安装过程自动完成：下载仓库、配置 PATH、安装命令。无需任何手动操作。

## 使用

```bash
openclaw-bg start              # 后台启动
openclaw-bg start --verbose    # 传递参数给 Gateway
openclaw-bg stop               # 停止
openclaw-bg status             # 查看状态
openclaw-bg help               # 查看帮助
```

## 卸载

```bash
openclaw-bg uninstall
```

## 日志

| 文件 | 内容 |
|------|------|
| `~/.openclaw-bg/logs/gateway.log` | Gateway 运行输出 |
| `~/.openclaw-bg/logs/openclaw-bg.log` | 启停事件记录 |
| `~/.openclaw-bg/logs/install.log` | 安装/卸载记录 |

## 依赖

- [OpenClaw](https://docs.openclaw.ai) CLI（`npm install -g openclaw`）
- Git（下载仓库需要，Windows / macOS / Linux 均自带或可安装）
- Bash（macOS / Linux 自带；Windows 下 Git Bash 自带）

## 许可证

MIT
