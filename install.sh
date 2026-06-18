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
if [[ ! -f "${0:-}" ]] || [[ ! -f "$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)/bin/openclaw-bg" ]]; then
    ARCHIVE_URL="https://github.com/gochangc/openclaw-bg/archive/refs/heads/master.tar.gz"
    REPO_DIR="${OPENCLAW_BG_HOME:-$HOME/.openclaw-bg}"

    echo "========================================"
    echo "  OpenClaw BG 远程安装"
    echo "========================================"
    echo ""

    # 检测下载工具
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
    else
        echo "错误: 未检测到 curl 或 wget，请先安装其中之一"
        echo "  curl: https://curl.se"
        echo "  wget: https://www.gnu.org/software/wget/"
        exit 1
    fi

    echo "正在下载 openclaw-bg..."
    [[ -d "$REPO_DIR" ]] && rm -rf "$REPO_DIR"

    TMP_DIR="$(mktemp -d)"
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL "$ARCHIVE_URL" -o "$TMP_DIR/openclaw-bg.tar.gz"
    else
        wget -q "$ARCHIVE_URL" -O "$TMP_DIR/openclaw-bg.tar.gz"
    fi
    tar xzf "$TMP_DIR/openclaw-bg.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/openclaw-bg-master" "$REPO_DIR"
    rm -rf "$TMP_DIR"
    echo "下载完成，开始本地安装..."
    echo ""
    exec bash "$REPO_DIR/install.sh"
fi

# ==============================
# 以下为本地安装流程
# ==============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
INSTALL_LOG="$LOG_DIR/install.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_msg() {
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$LOG_DIR"
    echo "[$ts] $1" >> "$INSTALL_LOG"
}

check_openclaw() {
    if command -v openclaw &>/dev/null; then
        local v; v="$(openclaw --version 2>&1 | head -1)"
        echo -e "  openclaw: ${GREEN}已安装${NC} ($v)"
        log_msg "openclaw 检测: 已安装 ($v)"
        return 0
    else
        echo -e "  openclaw: ${RED}未安装${NC}"
        log_msg "openclaw 检测: 未安装"
        return 1
    fi
}

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

# 自动将目录加入 PATH
setup_path() {
    local target_dir="$1"
    local rc_file=""

    case "$(basename "${SHELL:-bash}")" in
        zsh)  rc_file="$HOME/.zshrc" ;;
        bash) rc_file="$HOME/.bashrc" ;;
        *)    rc_file="$HOME/.profile" ;;
    esac

    if [[ ":$PATH:" == *":$target_dir:"* ]]; then
        echo -e "  ${GREEN}✓ 已在 PATH 中，无需配置${NC}"
        return 0
    fi

    # 检查是否已在 RC 文件中
    local export_line="export PATH=\"$target_dir:\$PATH\""
    if [[ -f "$rc_file" ]] && grep -qF "$target_dir" "$rc_file" 2>/dev/null; then
        echo -e "  ${GREEN}✓ PATH 配置已存在于 $rc_file${NC}"
    else
        echo "" >> "$rc_file"
        echo "# OpenClaw BG" >> "$rc_file"
        echo "$export_line" >> "$rc_file"
        echo -e "  ${GREEN}✓ 已自动配置 PATH ($rc_file)${NC}"
    fi
    echo -e "  ${YELLOW}  生效方式: source $rc_file  或重新打开终端${NC}"
    # 当前会话即时生效
    export PATH="$target_dir:$PATH"
}

print_usage() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OpenClaw BG 安装完成！${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  后台启动:  ${GREEN}openclaw-bg start${NC}"
    echo -e "  停止服务:  ${GREEN}openclaw-bg stop${NC}"
    echo -e "  查看状态:  ${GREEN}openclaw-bg status${NC}"
    echo -e "  卸载:      ${GREEN}openclaw-bg uninstall${NC}"
    echo ""
}

main() {
    local target_dir wrapper_path
    target_dir="$(detect_install_dir "${1:-}")"
    wrapper_path="$target_dir/openclaw-bg"

    mkdir -p "$LOG_DIR"
    log_msg "========== 开始安装 =========="

    echo -e "${CYAN}OpenClaw BG 安装脚本${NC}"
    echo ""

    # [1/4] 环境检测
    echo -e "${CYAN}[1/4]${NC} 环境检测"
    echo -e "  系统: $(uname -s)"
    echo -e "  项目: $SCRIPT_DIR"
    log_msg "系统: $(uname -s), 项目: $SCRIPT_DIR"
    if ! check_openclaw; then
        echo ""
        echo -e "${RED}错误: 未检测到 openclaw，请先安装${NC}"
        echo "  npm install -g openclaw"
        log_msg "安装失败: openclaw 未安装"
        exit 1
    fi
    echo ""

    # [2/4] 安装目录
    echo -e "${CYAN}[2/4]${NC} 准备安装目录"
    [[ ! -d "$target_dir" ]] && mkdir -p "$target_dir"
    echo -e "  目标: ${YELLOW}$target_dir${NC}"
    echo ""

    # [3/4] 安装命令 + PATH
    echo -e "${CYAN}[3/4]${NC} 安装命令 + PATH 配置"
    cat > "$wrapper_path" << WRAPPER_EOF
#!/usr/bin/env bash
# openclaw-bg wrapper — 由 install.sh 自动生成
export OPENCLAW_BG_HOME="$SCRIPT_DIR"
exec "\$OPENCLAW_BG_HOME/bin/openclaw-bg" "\$@"
WRAPPER_EOF
    chmod +x "$wrapper_path"
    echo -e "  ${GREEN}✓ openclaw-bg${NC} -> $wrapper_path"

    # 记录 wrapper 路径，供卸载时使用
    echo "$wrapper_path" > "$SCRIPT_DIR/.wrapper-path"

    setup_path "$target_dir"
    log_msg "已安装: $wrapper_path"
    echo ""

    # [4/4] 完成
    echo -e "${CYAN}[4/4]${NC} 完成"
    mkdir -p "$LOG_DIR"
    log_msg "安装完成"
    print_usage
}

main "${@}"
