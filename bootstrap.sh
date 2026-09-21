#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
readonly ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

log() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$1"
}

warn() {
  printf '\n\033[1;33m警告:\033[0m %s\n' "$1" >&2
}

die() {
  printf '\n\033[1;31m错误:\033[0m %s\n' "$1" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  printf '\n\033[1;31m安装失败:\033[0m 第 %s 行（退出码 %s）\n' "$1" "$exit_code" >&2
  printf '修复问题后可直接重新运行；脚本会跳过已完成的部分。\n' >&2
  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

append_line_once() {
  local line=$1
  local file=$2
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" || printf '\n%s\n' "$line" >> "$file"
}

check_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "此项目仅支持 macOS。"
  case "$(uname -m)" in
    arm64|x86_64) ;;
    *) die "不支持的 Mac 架构：$(uname -m)" ;;
  esac
}

install_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools 已安装"
    return
  fi

  log "请求安装 Xcode Command Line Tools"
  xcode-select --install 2>/dev/null || true
  printf '请在弹出的系统窗口中完成安装；脚本会等待安装结束。\n'

  local waited=0
  local timeout=3600
  until xcode-select -p >/dev/null 2>&1; do
    if (( waited >= timeout )); then
      die "等待 Command Line Tools 超时。安装完成后请重新运行脚本。"
    fi
    sleep 10
    waited=$((waited + 10))
  done
}

load_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  load_homebrew
  if ! command -v brew >/dev/null 2>&1; then
    log "安装 Homebrew"
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_homebrew
  else
    log "Homebrew 已安装"
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew 安装后仍无法找到。"
  append_line_once "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" "$ZPROFILE"
}

install_brew_bundle() {
  [[ -f "$SCRIPT_DIR/Brewfile" ]] || die "缺少 Brewfile。"
  log "按 Brewfile 安装或更新软件"
  brew update
  brew bundle check --file="$SCRIPT_DIR/Brewfile" ||
    brew bundle install --file="$SCRIPT_DIR/Brewfile"
}

configure_mise() {
  command -v mise >/dev/null 2>&1 || die "Brewfile 未能安装 mise。"
  [[ -f "$SCRIPT_DIR/mise.toml" ]] || die "缺少 mise.toml。"

  log "配置 zsh 激活 mise"
  append_line_once 'eval "$(mise activate zsh)"' "$ZSHRC"

  log "安装 mise.toml 中的开发工具"
  mise trust "$SCRIPT_DIR/mise.toml"
  mise install --cd "$SCRIPT_DIR" --yes

  log "同步为用户级默认工具"
  while IFS='=' read -r raw_tool raw_version; do
    local tool version
    tool="$(printf '%s' "$raw_tool" | tr -d '[:space:]')"
    version="$(printf '%s' "$raw_version" | sed -E 's/^[[:space:]]*"([^"]+)".*$/\1/')"
    [[ -n "$tool" && -n "$version" ]] &&
      (cd "$HOME" && mise use --global --yes "${tool}@${version}")
  done < <(
    awk '
      /^\[tools\][[:space:]]*$/ { in_tools=1; next }
      /^\[/ { in_tools=0 }
      in_tools && /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/ { print }
    ' "$SCRIPT_DIR/mise.toml"
  )
}

main() {
  check_macos
  install_command_line_tools
  install_homebrew
  install_brew_bundle
  configure_mise

  log "执行安装后验证"
  "$SCRIPT_DIR/scripts/verify.sh"

  log "新机初始化完成"
  printf '请重新打开终端，或执行：exec zsh -l\n'
}

main "$@"
