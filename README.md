# OpenClaw BG

openclaw 后台启动脚本

## 快速开始

### 远程安装（推荐）

一条命令，自动下载并安装，支持 Windows / macOS / Linux：

**Git Bash / Linux / macOS：**

```bash
curl -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | bash
```

**Windows（推荐使用 Git Bash）：**

```bash
curl -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | bash
```

**Windows PowerShell：**

```powershell
curl.exe -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | & "C:\Program Files\Git\usr\bin\bash.exe"
```

> 注意：如果 Git 安装在其他路径，请替换 `bash.exe` 的实际位置。也可直接在 Git Bash 中执行安装命令，更简单。

安装过程会自动：
- 检测 git 是否可用（需要 git 来下载仓库）
- 将仓库 clone 到 `~/.openclaw-bg`
- 检测 openclaw 是否已安装
- 将 `openclaw-bg` 命令安装到系统 PATH
- 重复执行安装脚本会自动更新到最新版本

### 本地安装

如果你已经 clone 了仓库：

```bash
cd openclaw-bg
./install.sh
```

### 使用

```bash
# 后台启动
openclaw-bg start

# 传递参数给 Gateway
openclaw-bg start --port 18789 --verbose

# 停止
openclaw-bg stop

# 查看状态
openclaw-bg status

# 查看帮助
openclaw-bg help
```

### 卸载

```bash
cd ~/.openclaw-bg && ./uninstall.sh
```

卸载时会自动检查并停止正在运行的 Gateway 进程。

## 目录结构

```
~/.openclaw-bg/            # 项目目录（远程安装时默认位置）
├── bin/
│   └── openclaw-bg        # 核心脚本
├── logs/                   # 日志目录（运行后自动生成）
│   ├── gateway.log         # Gateway 运行输出
│   ├── openclaw-bg.log     # 启停事件记录
│   └── install.log         # 安装/卸载记录
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
└── README.md
```

## 命令参考

| 命令 | 说明 |
|------|------|
| `openclaw-bg start [参数...]` | 后台启动 Gateway，参数透传给 `openclaw gateway run` |
| `openclaw-bg stop` | 停止 Gateway（先 SIGTERM，10 秒后 SIGKILL） |
| `openclaw-bg status` | 查看 Gateway 运行状态 |
| `openclaw-bg help` | 显示帮助信息 |

## 日志

所有日志统一存放在项目 `logs/` 目录下：

| 日志文件 | 内容 |
|----------|------|
| `gateway.log` | Gateway 进程的标准输出和标准错误 |
| `openclaw-bg.log` | 启停操作事件，带时间戳 |
| `install.log` | 安装和卸载操作记录 |

## 自定义安装路径

```bash
# 方式一：指定命令安装目录
./install.sh /usr/local/bin

# 方式二：指定项目 clone 目录
OPENCLAW_BG_HOME=/opt/openclaw-bg curl -sSL https://.../install.sh | bash

# 方式三：环境变量
OPENCLAW_BG_PREFIX=/opt/bin ./install.sh
```

## 依赖

- [OpenClaw](https://docs.openclaw.ai) CLI（需提前安装：`npm install -g openclaw`）
- Git（远程安装时需要，用于下载仓库）
- Bash（Linux / macOS 自带，Windows 下使用 Git Bash 或 MSYS2）

## 许可证

MIT
