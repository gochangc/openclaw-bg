#!/usr/bin/env bash
# =============================================================================
# uninstall.sh — 卸载 openclaw-bg
# 支持 Linux / macOS / Windows (Git Bash, MSYS2)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

# ---- 检测安装目录（与 install.sh 逻辑一致）----
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

# ---- 主流程 ----
main() {
    local target_dir wrapper_path
    target_dir="$(detect_install_dir "${1:-}")"
    wrapper_path="$target_dir/openclaw-bg"

    log_msg "========== 开始卸载 =========="
    log_msg "安装目录: $target_dir"

    echo -e "${CYAN}OpenClaw BG 卸载脚本${NC}"
    echo ""

    if [[ -f "$wrapper_path" ]]; then
        echo -e "移除: ${RED}$wrapper_path${NC}"
        rm -f "$wrapper_path"
        log_msg "已移除: $wrapper_path"

        # 停止正在运行的服务
        if [[ -f "$HOME/.openclaw/gateway.pid" ]]; then
            local pid
            pid="$(cat "$HOME/.openclaw/gateway.pid" 2>/dev/null)"
            if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
                echo -e "  同时停止运行中的 Gateway (PID: $pid)"
                kill "$pid" 2>/dev/null || true
                log_msg "已停止运行中的 Gateway (PID: $pid)"
            fi
            rm -f "$HOME/.openclaw/gateway.pid"
        fi

        echo ""
        echo -e "✓ ${GREEN}卸载完成${NC}"
    else
        echo "未找到已安装的 openclaw-bg，无需卸载"
        log_msg "未找到 wrapper: $wrapper_path"
    fi

    # 提示日志保留
    if [[ -d "$LOG_DIR" ]]; then
        echo -e "  日志保留在: ${YELLOW}$LOG_DIR${NC}（如需清理请手动删除）"
    fi

    # 目标目录为空时提示
    if [[ -d "$target_dir" ]] && [[ -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
        echo ""
        echo -e "  目录 ${YELLOW}$target_dir${NC} 已空，如需删除:"
        echo -e "  ${CYAN}rmdir \"$target_dir\"${NC}"
    fi

    log_msg "卸载完成"
}

main "${@}"
