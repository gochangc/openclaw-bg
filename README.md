# OpenClaw BG

OpenClaw Gateway 后台管理工具，提供一条命令启动、一条命令停止的便捷方式。

## 快速开始

### 安装

```bash
cd openclaw-bg
./install.sh
```

安装脚本会自动：
- 检测当前系统平台（Windows / macOS / Linux）
- 检测 openclaw 是否已安装
- 将 `openclaw-bg` 命令安装到系统 PATH

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
cd openclaw-bg
./uninstall.sh
```

卸载时会自动检查并停止正在运行的 Gateway 进程。

## 目录结构

```
openclaw-bg/
├── bin/
│   └── openclaw-bg      # 核心脚本
├── logs/                 # 日志目录（运行后自动生成）
│   ├── gateway.log       # Gateway 运行输出
│   ├── openclaw-bg.log   # 启停事件记录
│   └── install.log       # 安装/卸载记录
├── install.sh            # 安装脚本
├── uninstall.sh          # 卸载脚本
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
# 方式一：指定安装目录
./install.sh /usr/local/bin

# 方式二：环境变量
OPENCLAW_BG_PREFIX=/opt/bin ./install.sh
```

## 依赖

- [OpenClaw](https://docs.openclaw.ai) CLI（需提前安装：`npm install -g openclaw`）
- Bash（Linux / macOS 自带，Windows 下使用 Git Bash 或 MSYS2）

## 许可证

MIT
