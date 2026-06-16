#!/usr/bin/env bash
# =============================================================================
# install.sh — 安装 openclaw-bg 到系统 PATH
#
# 本地安装:  ./install.sh
# 远程安装:  curl -sSL https://raw.githubusercontent.com/gochangc/openclaw-bg/master/install.sh | bash
#
# 支持 Linux / macOS / Windows (Git Bash, MSYS2)
# =============================================================================
set -euo pipefail

# ---- 远程/本地模式检测 ----
# 如果当前目录下没有 bin/openclaw-bg，说明是通过 curl|bash 远程执行的，
# 需要先 clone 仓库，再调用本地安装流程
if [[ ! -f "${0:-}" ]] || [[ ! -f "$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)/bin/openclaw-bg" ]]; then
    REPO_URL="https://github.com/gochangc/openclaw-bg.git"
    REPO_DIR="${OPENCLAW_BG_HOME:-$HOME/.openclaw-bg}"

    echo "========================================"
    echo "  OpenClaw BG 远程安装"
    echo "========================================"
    echo ""

    # 检查依赖
    if ! command -v git &>/dev/null; then
        echo "错误: 未检测到 git，请先安装 git"
        echo "  Windows: https://git-scm.com"
        echo "  Linux:   sudo apt install git  或  sudo yum install git"
        echo "  macOS:   xcode-select --install"
        exit 1
    fi

    # 下载仓库
    if [[ -d "$REPO_DIR/.git" ]]; then
        echo "仓库已存在，正在更新..."
        cd "$REPO_DIR"
        git pull --ff-only origin master 2>/dev/null || echo "  (跳过更新, 使用已有版本)"
    else
        echo "正在下载 openclaw-bg..."
        if [[ -d "$REPO_DIR" ]]; then
            rm -rf "$REPO_DIR"
        fi
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    fi

    echo ""
    echo "下载完成，开始本地安装..."
    echo ""

    # 用本地副本重新执行
    exec bash "$REPO_DIR/install.sh"
fi

# ==============================
# 以下为本地安装流程
# ==============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
INSTALL_LOG="$LOG_DIR/install.log"

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 日志函数 ----
log_msg() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] $1" >> "$INSTALL_LOG"
}

# ---- 检测 openclaw 是否已安装 ----
check_openclaw() {
    if command -v openclaw &>/dev/null; then
        local version
        version="$(openclaw --version 2>&1 | head -1)"
        echo -e "  openclaw: ${GREEN}已安装${NC} ($version)"
        log_msg "openclaw 检测: 已安装 ($version)"
        return 0
    else
        echo -e "  openclaw: ${RED}未安装${NC}"
        log_msg "openclaw 检测: 未安装"
        return 1
    fi
}

# ---- 检测安装目标目录 ----
detect_install_dir() {
    local dir

    if [[ -n "${1:-}" ]]; then
        dir="$1"
    elif [[ -n "${OPENCLAW_BG_PREFIX:-}" ]]; then
        dir="$OPENCLAW_BG_PREFIX"
    elif [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
        dir="${HOME}/bin"
    elif [[ "$(uname -s)" == Darwin ]]; then
        dir="${HOME}/.local/bin"
    else
        dir="${HOME}/.local/bin"
    fi

    echo "$dir"
}

# ---- 检查是否在 PATH 中 ----
check_in_path() {
    local d="$1"
    [[ ":$PATH:" == *":$d:"* ]]
}

# ---- 打印使用说明 ----
print_usage() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OpenClaw BG — 使用说明${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  后台启动:  ${GREEN}openclaw-bg start${NC}"
    echo -e "  传递参数:  ${GREEN}openclaw-bg start --port 18789 --verbose${NC}"
    echo -e "  停止服务:  ${GREEN}openclaw-bg stop${NC}"
    echo -e "  查看状态:  ${GREEN}openclaw-bg status${NC}"
    echo -e "  查看帮助:  ${GREEN}openclaw-bg help${NC}"
    echo ""
    echo -e "  项目目录:  ${YELLOW}$SCRIPT_DIR${NC}"
    echo -e "  运行日志:  ${YELLOW}$LOG_DIR/gateway.log${NC}"
    echo -e "  事件日志:  ${YELLOW}$LOG_DIR/openclaw-bg.log${NC}"
    echo ""
    echo -e "  卸载方式:  cd ${YELLOW}$SCRIPT_DIR${NC} && ./uninstall.sh"
    echo ""
}

# ---- 主流程 ----
main() {
    local target_dir wrapper_path
    target_dir="$(detect_install_dir "${1:-}")"
    wrapper_path="$target_dir/openclaw-bg"

    mkdir -p "$LOG_DIR"
    log_msg "========== 开始安装 =========="

    echo -e "${CYAN}OpenClaw BG 安装脚本${NC}"
    echo ""

    # [1/5] 环境检测
    echo -e "${CYAN}[1/5]${NC} 环境检测"
    echo -e "  当前系统: $(uname -s)"
    echo -e "  项目目录: $SCRIPT_DIR"
    echo -e "  安装目标: $target_dir"
    log_msg "系统: $(uname -s), 项目目录: $SCRIPT_DIR, 安装目标: $target_dir"

    if ! check_openclaw; then
        echo ""
        echo -e "${RED}错误: 未检测到 openclaw，请先安装${NC}"
        echo ""
        echo "  安装方式: npm install -g openclaw"
        echo "  或访问: https://docs.openclaw.ai"
        log_msg "安装失败: openclaw 未安装"
        exit 1
    fi
    echo ""

    # [2/5] 检查 git（后续更新需要）
    echo -e "${CYAN}[2/5]${NC} 依赖检查"
    if command -v git &>/dev/null; then
        echo -e "  git: ${GREEN}已安装${NC}"
    else
        echo -e "  git: ${YELLOW}未安装（不影响使用，但无法在线更新）${NC}"
    fi
    echo ""

    # [3/5] 创建安装目录
    echo -e "${CYAN}[3/5]${NC} 准备安装目录"
    if [[ ! -d "$target_dir" ]]; then
        echo -e "  创建: ${YELLOW}$target_dir${NC}"
        mkdir -p "$target_dir"
        log_msg "创建目录: $target_dir"
    else
        echo -e "  已存在: ${YELLOW}$target_dir${NC}"
    fi
    echo ""

    # [4/5] 安装命令（生成 wrapper 脚本）
    echo -e "${CYAN}[4/5]${NC} 安装命令"
    cat > "$wrapper_path" << WRAPPER_EOF
#!/usr/bin/env bash
# openclaw-bg wrapper — 由 install.sh 自动生成
export OPENCLAW_BG_HOME="$SCRIPT_DIR"
exec "\$OPENCLAW_BG_HOME/bin/openclaw-bg" "\$@"
WRAPPER_EOF
    chmod +x "$wrapper_path"
    echo -e "  ✓ ${GREEN}openclaw-bg${NC} -> $wrapper_path"
    log_msg "已安装 wrapper: $wrapper_path"

    echo ""

    # [5/5] PATH 检查
    echo -e "${CYAN}[5/5]${NC} PATH 检查"
    if check_in_path "$target_dir"; then
        echo -e "  ✓ 目录已在 PATH 中"
        log_msg "PATH 检查: 通过 ($target_dir)"
    else
        echo -e "  ${YELLOW}⚠ 目录不在 PATH 中${NC}"
        log_msg "PATH 检查: 未通过 ($target_dir 不在 PATH)"
        echo ""

        local rc_file
        case "$(basename "${SHELL:-bash}")" in
            zsh)  rc_file="$HOME/.zshrc" ;;
            bash) rc_file="$HOME/.bashrc" ;;
            *)    rc_file="$HOME/.profile" ;;
        esac
        echo -e "  请执行以下命令，或手动添加到 ${YELLOW}$rc_file${NC}:"
        echo -e "  ${CYAN}echo 'export PATH=\"$target_dir:\$PATH\"' >> \"$rc_file\"${NC}"
        echo -e "  ${CYAN}source \"$rc_file\"${NC}"
        echo ""
    fi

    # 初始化 logs 目录
    mkdir -p "$LOG_DIR"
    log_msg "安装完成"

    print_usage
}

main "${@}"
